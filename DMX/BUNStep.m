//
//  BUNStep.m
//  DMX
//
//  Created by JFR on 08/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import "BUNStep.h"
#import "BUNAppDelegate.h"

@implementation BUNStep

@synthesize lightStates, millisecondToMe, previousStepsStream, autoplay, name;

-(id)init
{
    self = [super init];
    if(self != nil)
    {
        self.autoplay = NO;
        self.name = @"---";
        self.lightStates = [NSMutableArray array];
        self.millisecondToMe = 0;
        self.previousStepsStream = [NSMutableArray array];
        return self;
    }
    return nil;
}

+(id)newStepWithLights:(NSMutableArray*)l
{
    BUNStep * step = [[BUNStep alloc] init];
    if (step != nil)
    {
        for (BUNLight * light in l)
        {
            NSMutableDictionary * di = [NSMutableDictionary dictionary];
            [di setObject:light forKey:@"light"];

            int val = 0;//[light.fader.slider intValue];
            [di setObject:[NSNumber numberWithInt:val] forKey:@"value"];
            [step.lightStates addObject:di];
        }
        return step;
    }
    
    return nil;
}

-(void)removeLightStateForLight:(BUNLight*)light
{
    for (NSMutableDictionary *d in lightStates)
    {
        BUNLight * l = [d objectForKey:@"light"];
        if (l.internalNumber == light.internalNumber)
        {
            [lightStates removeObject:d];
            return;
        }
    }
}



-(void)updateFaders
{
    
    BUNAppDelegate* delegate = (BUNAppDelegate*)[NSApp delegate];
    [delegate.transitionTimeField setIntValue:self.millisecondToMe];
    delegate.autoplayButton.state = self.autoplay;
    delegate.nameField.stringValue = self.name;
    
    for (NSDictionary * dic in self.lightStates)
    {
        BUNLight * light = [dic objectForKey:@"light"];
        BUNFader * fader = light.fader;
        
        [fader adjustValue:[[dic objectForKey:@"value"] intValue]];
//        [fader.value setIntValue:];
//        [fader valueEntered:fader.value];
    }
    [delegate.scene sendLightsValuesToQC];
}



-(void)updateStep
{
    BUNAppDelegate* delegate = (BUNAppDelegate*)[NSApp delegate];
    
    self.millisecondToMe =  delegate.transitionTimeField.intValue;
    self.autoplay = delegate.autoplayButton.state;
    self.name = delegate.nameField.stringValue;
    for (NSMutableDictionary * dic in self.lightStates)
    {
        BUNLight * light = [dic objectForKey:@"light"];
        int faderValue = light.fader.slider.intValue;
        [dic setObject:[NSNumber numberWithInt:faderValue] forKey:@"value"];
    }
    [delegate.scene sendLightsValuesToQC];
}

-(int)stepValueForLight:(BUNLight*)light
{
    for (NSDictionary * dic in self.lightStates)
    {
        if ([dic objectForKey:@"light"] == light)
        {
            return [[dic objectForKey:@"value"] intValue];
        }
    }
    return -1;
}


-(uint8_t*)dmxData
{
    static uint8_t dmxData[512] = {0};

    for (NSMutableDictionary*d in lightStates)
    {
        int lightNum = [(BUNLight*)[d objectForKey:@"light"] DMXChannel];
        uint8_t val = (uint8_t)[[d objectForKey:@"value"] intValue];
        //NSLog(@"%d", val);
        dmxData[lightNum] = val;
    }
    return dmxData;
}

@end
