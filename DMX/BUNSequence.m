//
//  BUNSequence.m
//  DMX
//
//  Created by JFR on 08/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import "BUNSequence.h"
#import "BUNScene.h"



@implementation BUNSequence

@synthesize reverse,scene, steps, sequenceView, selectedStep, applyInstantly, volatileStep, isAdjusting, nextStepToPlay, transitionDuration, transitionPosition, DMXUniverse0, DMXUniverse1;


-(id)initWithScene:(BUNScene*)s
{
    self = [super init];
    if (self != nil)
    {
        timeInterval = 0.02;
        self.scene = s;
        self.steps = [[NSMutableArray alloc] init];
        self.sequenceView = [[BUNSequenceView alloc] initWithFrame:NSMakeRect(0, 0, 10, 10) andSequence:self];
        autoplay = NO;
        return self;
    }
    return nil;
}




-(void)timeTop
{
    while (isAdjusting == YES)
    {
        if (reverse)
        {
            volatileStep = [selectedStep.previousStepsStream objectAtIndex:(selectedStep.previousStepsStream.count-1-count)];
            self.sequenceView.percentOftransition = -((float)count/(float)selectedStep.previousStepsStream.count);
            autoplay = selectedStep.autoplay;
        }
        else //forward
        {
            volatileStep = [nextStepToPlay.previousStepsStream objectAtIndex:count];
            self.sequenceView.percentOftransition = ((float)count/(float)nextStepToPlay.previousStepsStream.count);
            autoplay = nextStepToPlay.autoplay;
        }
        
        count = count+1;
        [volatileStep performSelectorOnMainThread:@selector(updateFaders) withObject:nil waitUntilDone:NO];
        
        uint8_t *dmxData = [volatileStep dmxData];

        [DMXUniverse0 setDmxData:dmxData];
        
        if ((reverse && count >= selectedStep.previousStepsStream.count) || (!reverse && count >=nextStepToPlay.previousStepsStream.count))
        {
            dispatch_sync(dispatch_get_main_queue(), ^{
                isAdjusting = NO;
                count = 0;
                [self selectStepAtIndex:(int)[steps indexOfObject:nextStepToPlay]];
                self.sequenceView.percentOftransition = 0;
                [selectedStep updateFaders];
                
                if(autoplay)
                {
                    if(!reverse)
                    {
                        [self nextStep];
                    }
                }
            });            
        }
        
        [sequenceView performSelectorOnMainThread:@selector(setNeedsDisplay:) withObject:@YES waitUntilDone:YES];
        
        [NSThread sleepForTimeInterval:timeInterval];
    }
}



-(void)nextStep
{
    int stepIndex = (int)[self.steps indexOfObject:self.selectedStep];
    int nextStepIndex = (int)MIN(self.steps.count-1 , stepIndex+1);
    
    if (applyInstantly == YES)
    {
        reverse = NO;
        isAdjusting = NO;
        count = 0;
        self.sequenceView.percentOftransition = 0;
        if (self.selectedStep != nil)
        {
            self.selectedStep = [self.steps objectAtIndex:nextStepIndex];
            [self.selectedStep updateFaders];
            [self.sequenceView setNeedsDisplay:YES];
            uint8_t *dmxData = [self.selectedStep dmxData];            
            [DMXUniverse0 setDmxData:dmxData];
        }
    }
    else
    {
        if (self.selectedStep != nil && isAdjusting == NO)
        {
            reverse = NO;
            transitionPosition = 0;
            nextStepToPlay = [self.steps objectAtIndex:nextStepIndex];
            transitionDuration = nextStepToPlay.millisecondToMe;
            if (transitionDuration >= timeInterval*1000)
            {
                isAdjusting = YES;
                lastdate = [NSDate date];
                [NSThread detachNewThreadSelector:@selector(timeTop) toTarget:self withObject:nil];
            }
            else
            {
                self.selectedStep = [self.steps objectAtIndex:nextStepIndex];
                [self.selectedStep updateFaders];
                [self.sequenceView setNeedsDisplay:YES];
                uint8_t *dmxData = [self.selectedStep dmxData];
                [DMXUniverse0 setDmxData:dmxData];
                if (selectedStep.autoplay)
                {
                    [self nextStep];
                }
            }
        }
    }
}

-(void)previousStep
{
    int stepIndex = (int)[scene.sequence.steps indexOfObject:self.selectedStep];
    int previousStepIndex = (int)MAX(0 , stepIndex-1);
    
    if (applyInstantly == YES)
    {
        reverse = YES;
        isAdjusting = NO;
        count = 0;
        self.sequenceView.percentOftransition = 0;
        if (self.selectedStep != nil)
        {
            self.selectedStep = [scene.sequence.steps objectAtIndex:previousStepIndex];
            [self.selectedStep updateFaders];
            [self.sequenceView setNeedsDisplay:YES];
            uint8_t *dmxData = [self.selectedStep dmxData];
            [DMXUniverse0 setDmxData:dmxData];
        }
    }
    else
    {
        if (self.selectedStep != nil  && isAdjusting == NO)
        {
            reverse = YES;
            transitionPosition = 0;
            nextStepToPlay = [scene.sequence.steps objectAtIndex:previousStepIndex];
            transitionDuration = selectedStep.millisecondToMe;
            if (transitionDuration >= timeInterval*1000)
            {
                isAdjusting = YES;
                lastdate = [NSDate date];
                [NSThread detachNewThreadSelector:@selector(timeTop) toTarget:self withObject:nil];
            }
            else
            {
                self.selectedStep = [scene.sequence.steps objectAtIndex:previousStepIndex];
                [self.selectedStep updateFaders];
                [self.sequenceView setNeedsDisplay:YES];
                uint8_t *dmxData = [self.selectedStep dmxData];
                [DMXUniverse0 setDmxData:dmxData];
            }
        }
    }
}

-(void)addStep
{
    [self.steps addObject:[BUNStep newStepWithLights:scene.lights]];
    [self.sequenceView redrawBack];
    [self precomputeTransitions];
    selectedStep = self.steps.lastObject;
    [scene refreshLightPaths];
    [selectedStep updateFaders];
}


-(void)deleteStep
{
    if (self.selectedStep != nil)
    {
        int index = (int)[steps indexOfObject:self.selectedStep];
        [self.steps removeObject:self.selectedStep];
        if (steps.count)
        {
            self.selectedStep = [steps objectAtIndex:MIN(index, self.steps.count-1)];
        }
        [scene refreshLightPaths];
        [self precomputeTransitions];
        [self.sequenceView redrawBack];
    }
}


-(void)insertStep
{
    if (self.selectedStep != nil)
    {
        int stepIndex = (int)[self.steps indexOfObject:self.selectedStep];
        
        BUNStep * newStep = [[BUNStep alloc] init];
        for (NSMutableDictionary *dic in self.selectedStep.lightStates)
        {
            [newStep.lightStates addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [dic objectForKey:@"light"],@"light",
                                            [NSNumber numberWithInt:[[dic objectForKey:@"value"] intValue]],@"value", nil]];
        }
        
        newStep.millisecondToMe = self.selectedStep.millisecondToMe;
        newStep.autoplay = self.selectedStep.autoplay;
        newStep.name = [self.selectedStep.name stringByAppendingString:@" (copy)"];
        
        [self.steps insertObject:newStep atIndex:stepIndex];
        [scene refreshLightPaths];
        [self precomputeTransitions];
        [self.sequenceView redrawBack];
    }
}


-(void)splitStep
{
    if (self.selectedStep != nil && [self.steps indexOfObject:self.selectedStep] != 0)
    {
        int stepIndex = (int)[self.steps indexOfObject:self.selectedStep];
        int previousStepIndex = stepIndex-1;
        BUNStep * previousStep = [steps objectAtIndex:previousStepIndex];
        
        BUNStep * newStep = [[BUNStep alloc] init];
        for (int i = 0 ; i < selectedStep.lightStates.count ; i++)
        {
            NSMutableDictionary * dStep = [selectedStep.lightStates objectAtIndex:i];
            NSMutableDictionary * dPreviousStep = [previousStep.lightStates objectAtIndex:i];
            
            int newValue = ([[dStep objectForKey:@"value"] intValue]+[[dPreviousStep objectForKey:@"value"] intValue])/2;
            
            [newStep.lightStates addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:
                                            [dStep objectForKey:@"light"],@"light",
                                            [NSNumber numberWithInt:newValue],@"value", nil]];
        }
        
        newStep.millisecondToMe = self.selectedStep.millisecondToMe / 2;
        newStep.autoplay = self.selectedStep.autoplay;
        newStep.name = [self.selectedStep.name stringByAppendingString:@" (splitted)"];
        
        self.selectedStep.millisecondToMe = self.selectedStep.millisecondToMe/2;
        
        [self.steps insertObject:newStep atIndex:previousStepIndex+1];
        [self.selectedStep updateFaders];
        [scene refreshLightPaths];
        [self precomputeTransitions];
        [self.sequenceView redrawBack];
    }
}


-(void)selectStepAtIndex:(int)si
{
    isAdjusting = NO;
    count = 0;
    sequenceView.percentOftransition = 0;
    self.selectedStep = [self.steps objectAtIndex:si];
    [self.selectedStep updateFaders];
}


-(void)precomputeTransitions
{
    NSDate * date = [NSDate date];
    for (int i = 1 ; i<steps.count ; i++)
    {
        BUNStep * previousStep = [steps objectAtIndex:i-1];
        BUNStep * step = [steps objectAtIndex:i];

        [step.previousStepsStream removeAllObjects];
        int timePos =0;
        NSString * tmpNameSeparator = [NSString stringWithFormat:@"%@ <__________> %@", previousStep.name, step.name];
        if (step.millisecondToMe != 0)
        {
            while (timePos <= step.millisecondToMe)
            {
                float percent = (float)timePos / (float)step.millisecondToMe;
                BUNStep * tmpStep = [[BUNStep alloc] init];
                tmpStep.millisecondToMe = timePos;
                tmpStep.autoplay = previousStep.autoplay;
                NSRange range = [tmpNameSeparator rangeOfCharacterFromSet:[NSCharacterSet characterSetWithCharactersInString:@"<"]];
                range.location = range.location+1+ 10*percent;
                range.length = 1;
                tmpStep.name = [tmpNameSeparator stringByReplacingCharactersInRange:range withString:@"*"];
                
                for (int i = 0 ; i < previousStep.lightStates.count ; i++)
                {
                    NSMutableDictionary * initialDict = [previousStep.lightStates objectAtIndex:i];
                    int initialValue = [[initialDict objectForKey:@"value"] intValue];
                    
                    NSMutableDictionary * finalDict = [step.lightStates objectAtIndex:i];
                    int finalValue = [[finalDict objectForKey:@"value"] intValue];
                    
                    BUNLight * light = [initialDict objectForKey:@"light"];
                    
                    int value = initialValue + percent*(finalValue-initialValue);
                    NSMutableDictionary * dic = [NSMutableDictionary dictionaryWithObjectsAndKeys:light,@"light",[NSNumber numberWithInt:value], @"value", nil];
                    
                    [tmpStep.lightStates addObject:dic];
                }
                timePos = timePos + 1000*timeInterval;
                [step.previousStepsStream addObject:tmpStep];
            }
        }
    }
    NSLog(@"precompute in %.2f millisec", -1000*[date timeIntervalSinceNow]);
}


/////////////////////////////////////////////////////////
////////////////   FILE FUNCTIONS   /////////////////////
/////////////////////////////////////////////////////////


-(void)loadStepsAtPath:(NSString*)path
{
    [[NSUserDefaults standardUserDefaults] setObject:path forKey:@"stepsFilePath"];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.steps = [NSMutableArray array];
    NSError * err;
    NSString * fileContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    NSArray * lines = [fileContent componentsSeparatedByString:@"\n"];
    for (int i = 0 ; i < lines.count ; i++)
    {
        BUNStep * step = [[BUNStep alloc] init];
        NSString * line = [lines objectAtIndex:i];
        NSArray * lightStates = [line componentsSeparatedByString:@";"];
        if (lightStates.count != 0)
        {
            for (int k = 0 ; k<lightStates.count ; k++)
            {
                if (k==0)
                {
                    step.millisecondToMe = [[lightStates objectAtIndex:k] intValue];
                }
                else if(k == 1)
                {
                    step.autoplay = [[lightStates objectAtIndex:k] boolValue];
                }
                else if(k == 2)
                {
                    step.name = [lightStates objectAtIndex:k];
                }
                else
                {
                    NSString * lightState = [lightStates objectAtIndex:k];
                    NSArray * comps = [lightState componentsSeparatedByString:@"@"];
                    int lightNum = [[comps objectAtIndex:0] intValue];
                    int lightVal = [[comps objectAtIndex:1] intValue];
                    
                    NSMutableDictionary * di = [NSMutableDictionary dictionary];
                    BUNLight * light = [scene lightWithInternalIndex:lightNum];
                    if (light == nil)
                    {
                        NSLog(@"A step in this file describes a light (#%d) that does not exist in the light configuration, it has been created but needs some configuration", lightNum);
                        light = [BUNLight newLightWithInternalNumber:lightNum info:@"give a name" xPos:0 yPos:0 zPos:0 value:0 DMXChannel:512 DMXUniverse:0 filterLabel:@"choose a filter"];
                        [scene.lights addObject:light];
                        [scene.lightTable reloadData];
                    }
                    
                    [di setObject:light forKey:@"light"];
                    [di setObject:[NSNumber numberWithInt:lightVal] forKey:@"value"];
                    [step.lightStates addObject:di];
                }
            }
        }
        [steps addObject:step];
    }
    [scene refreshLightPaths];
    [scene.sequence precomputeTransitions];
    [self.sequenceView redrawBack];
}


-(void)saveStepsAtPath:(NSString*)path
{
    NSString * fileContent = @"";
    NSError * err;
    for (int i = 0 ; i < steps.count ; i++)
    {
        BUNStep * step = [self.steps objectAtIndex:i];
        NSString * line = @"";
        line = [line stringByAppendingString:[NSString stringWithFormat:@"%d;%d;%@;", step.millisecondToMe, step.autoplay, step.name]];

        for (int k = 0; k < step.lightStates.count; k++)
        {
            NSDictionary * di = [step.lightStates objectAtIndex:k];
            NSString * lightNum = [NSString stringWithFormat:@"%d", [(BUNLight*)[di objectForKey:@"light"] internalNumber]];
            NSString * lightVal = [NSString stringWithFormat:@"%d", [[di objectForKey:@"value"] intValue]];
            line = [line stringByAppendingString:[NSString stringWithFormat:@"%@@%@;", lightNum, lightVal]];
        }
        line = [line substringToIndex:line.length-1];
        fileContent = [fileContent stringByAppendingFormat:@"%@\n", line];
    }
    fileContent = [fileContent substringToIndex:fileContent.length-1];
    [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err];
}



@end
