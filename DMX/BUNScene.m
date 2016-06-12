//
//  BUNScene.m
//  DMX
//
//  Created by JFR on 09/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import "BUNScene.h"
#import "BUNAppDelegate.h"

@implementation BUNScene


@synthesize lights, lightTable, sequence, sceneView;

-(id)init
{
    self = [super init];
    if (self != nil)
    {
        self.lights = [[NSMutableArray alloc] init];
        self.sequence = [[BUNSequence alloc] initWithScene:self];
        self.sceneView = [[BUNSceneView alloc] initWithFrame:NSMakeRect(0, 0, 40, 30)];

        return self;
    }
    return nil;
}


-(void)addLight
{
    BUNLight * light = [BUNLight newLightWithInternalNumber:-1 info:@"---" xPos:0 yPos:0 zPos:0 value:0 DMXChannel:0 DMXUniverse:0 filterLabel:@"---"];
    [self.lights addObject:light];
    
    for(int i = 0 ; i < sequence.steps.count ; i++)
    {
        BUNStep * step = [sequence.steps objectAtIndex:i];
        if([step stepValueForLight:light] == -1)
        {
            [step.lightStates addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:light, @"light",[NSNumber numberWithInt:0] ,@"value", nil]];
        }
    }
    
    [lightTable reloadData];
}


-(void)removeLight
{
    BUNLight * light = [self.lights objectAtIndex:[lightTable selectedRow]];
    [light.fader setEnabled:NO];
    light.fader.value.intValue = 0;
    [light.fader valueEntered:light.fader.value];
    [light.fader.value setBackgroundColor:[NSColor colorWithWhite:0.2 alpha:1.0]];
    [light.fader.label setTextColor:[NSColor colorWithWhite:0.2 alpha:1.0]];
    
    for(int i = 0 ; i < sequence.steps.count ; i++)
    {
        BUNStep * step = [sequence.steps objectAtIndex:i];
        [step removeLightStateForLight:light];
    }
    
    [self.lights removeObject:light];
    [self refreshLightPaths];
    [sequence precomputeTransitions];
    [sequence.sequenceView redrawBack];
    [lightTable reloadData];
}

-(void)sendLightsToQC
{
    NSLog(@"send all data to QC");
    NSMutableArray * lightArrayForQC = [NSMutableArray array];
    for (BUNLight * light in self.lights)
    {
        NSDictionary * di = [NSDictionary dictionaryWithObjectsAndKeys:
                             [NSNumber numberWithFloat:light.xPos],@"xPos",
                             [NSNumber numberWithFloat:light.yPos],@"yPos",
                             [NSNumber numberWithFloat:light.zPos],@"zPos",
                             [NSNumber numberWithInt:[light.fader.value intValue]],@"value",
                             [self rgbValueForFilterLabel:light.filterLabel],@"color",
                             [NSNumber numberWithInt:light.internalNumber],@"internalNumber",nil];
        [lightArrayForQC addObject:di];
    }
    NSDictionary * lightsForQC = [NSDictionary dictionaryWithObject:lightArrayForQC forKey:@"lights"];
    [self.sceneView setValue:lightsForQC forInputKey:@"lights"];
}

-(void)sendLightsValuesToQC
{
    
    NSMutableArray * lightArrayForQC = [NSMutableArray array];
    for (BUNLight * light in self.lights)
    {
        [lightArrayForQC addObject:[NSNumber numberWithInt:[light.fader.value intValue]]];
    }
    NSDictionary * lightsForQC = [NSDictionary dictionaryWithObject:lightArrayForQC forKey:@"lightsValues"];
    [self.sceneView setValue:lightsForQC forInputKey:@"lightsValues"];
}



-(NSDictionary*)rgbValueForFilterLabel:(NSString*)filterLabel
{
    NSError * err;
    NSArray * filterLines = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"filters" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&err] componentsSeparatedByString:@"\n"];
    for (NSString * filterLine in filterLines)
    {
        NSArray * filterComponents = [filterLine componentsSeparatedByString:@";"];
        NSString * label = [NSString stringWithFormat:@"%@_%@ %@ %@", [filterComponents objectAtIndex:0], [filterComponents objectAtIndex:2], [filterComponents objectAtIndex:1], [filterComponents objectAtIndex:3]];
        
        if ([label isEqualToString:filterLabel])
        {
            return [NSDictionary dictionaryWithObjectsAndKeys:
                    [filterComponents objectAtIndex:4],@"r",
                    [filterComponents objectAtIndex:5],@"g",
                    [filterComponents objectAtIndex:6],@"b", nil];
        }
    }
    return [NSDictionary dictionaryWithObjectsAndKeys:@0.0,@"r",@0.0,@"g",@0.0,@"b", nil];
}


-(BOOL)availableInternalNumber:(int)internalNumberToTest
{
    for (BUNLight * light in lights)
    {
        if (light.internalNumber == internalNumberToTest)
        {
            NSAlert * alert = [NSAlert alertWithMessageText:@"This index is already in use !" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"Please enter a free index for this light."];
            [alert runModal];
            return NO;
        }
    }
    return YES;
}

-(BUNLight*)lightWithInternalIndex:(int)index
{
    for (BUNLight * light in lights)
    {
        if(light.internalNumber == index)
        {
            return light;
        }
    }
    return nil;
}



-(void)refreshLightPaths
{

    float scale = self.sequence.sequenceView.scale;
    float height = self.sequence.sequenceView.frame.size.height;
    
    for (BUNLight * light in self.lights)
    {
        NSBezierPath * path = [NSBezierPath bezierPath];
        for (BUNStep * step in self.sequence.steps)
        {
            int val = [step stepValueForLight:light];
            int stepIndex = (int)[self.sequence.steps indexOfObject:step];
            if (step == self.sequence.steps.firstObject)
            {
                [path moveToPoint:NSMakePoint(0, (height-40) *(float)val/255 + 20.0)];
                
            }
            else
            {
                NSPoint  pt = NSMakePoint((float)stepIndex*scale, (height-40) * (float)val/255 + 20.0);
                [path lineToPoint:pt];
            }
        }
        light.path = path;
    }
}


/////////////////////////////////////////////////////////
////////////////   FILE FUNCTIONS   /////////////////////
/////////////////////////////////////////////////////////


-(void)loadLightsWithPath:(NSString*)path
{
    self.lights = [NSMutableArray array];

    NSError * err;
    NSString * fileContent = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&err];
    NSArray * lines = [fileContent componentsSeparatedByString:@"\n"];
    for (int i = 0 ; i < lines.count ; i++)
    {
        NSString * line = [lines objectAtIndex:i];
        if (i != 0)//first line is column's title
        {
            NSArray * props = [line componentsSeparatedByString:@";"];
            BUNLight * light = [BUNLight newLightWithInternalNumber:[[props objectAtIndex:0] intValue]
                                                               info:[props objectAtIndex:1]
                                                               xPos:[[(NSString*)[props objectAtIndex:2] stringByReplacingOccurrencesOfString:@"," withString:@"."] floatValue]
                                                               yPos:[[(NSString*)[props objectAtIndex:3] stringByReplacingOccurrencesOfString:@"," withString:@"."] floatValue]
                                                               zPos:[[(NSString*)[props objectAtIndex:4] stringByReplacingOccurrencesOfString:@"," withString:@"."] floatValue]
                                                              value:[[props objectAtIndex:5] intValue]
                                                         DMXChannel:[[props objectAtIndex:6] intValue]
                                                        DMXUniverse:[[props objectAtIndex:7] intValue]
                                                        filterLabel:(NSString*)[props objectAtIndex:8]];
            
            
            [self.lights addObject:light];
            
            BOOL found = NO;
            for(int k = 0 ; k < sequence.steps.count ; k++)
            {
                BUNStep * step = [sequence.steps objectAtIndex:k];
                for(NSMutableDictionary * d in step.lightStates)
                {
                    if([(BUNLight*)[d objectForKey:@"light"] internalNumber] == light.internalNumber)
                    {

                        [d setObject:light forKey:@"light"];
                        found = YES;
                    }
                }
                if(!found)
                {
                    NSMutableDictionary * d = [NSMutableDictionary dictionaryWithObjectsAndKeys:light, @"light" ,[NSNumber numberWithInt:0], @"value", nil];
                    [step.lightStates addObject:d];
                }
                [step updateFaders];
            }
        }
    }
    
    [self.lightTable reloadData];
    [self refreshLightPaths];
    [sequence precomputeTransitions];
    [self.sequence.sequenceView redrawBack];
    
    [self sendLightsToQC];
}


-(void)saveLightsWithPath:(NSString *)path
{
    NSString*fileContent = @"index;info;x;y;z;value;channel;universe;filterLabel\n";
    NSError * err;
    for (int i = 0 ; i < self.lights.count ; i++)
    {
        BUNLight * light = [self.lights objectAtIndex:i];
        NSString * line = [NSString stringWithFormat:@"%d;%@;%.2f;%.2f;%.2f;%d;%d;%d;%@\n",
                           light.internalNumber,
                           light.info,
                           light.xPos,
                           light.yPos,
                           light.zPos,
                           light.value,
                           light.DMXChannel,
                           light.DMXUniverse,
                           light.filterLabel];
        
        fileContent = [fileContent stringByAppendingString:line];
    }
    fileContent = [fileContent substringToIndex:fileContent.length-1];
    [fileContent writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&err];
}




/////////////////////////////////////////////////////////////
//////////   LIGHT TABLEVIEW DELEGATE & DATASOURCE   ////////
/////////////////////////////////////////////////////////////

- (NSInteger)numberOfRowsInTableView:(NSTableView *)tableView
{
    return self.lights.count;
}

- (BOOL)tableView:(NSTableView *)tableView shouldEditTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == lightTable)
    {
        if ([tableView.tableColumns indexOfObject:tableColumn] == 0)
        {
            return YES;
        }
        return YES;
    }
    return YES;
}

- (id)tableView:(NSTableView *)tableView objectValueForTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    NSUInteger col = [tableView.tableColumns indexOfObject:tableColumn];
    BUNLight* light = [self.lights objectAtIndex:row];
    if (col == 0)
    {
        return [NSNumber numberWithInt:[light internalNumber]];
    }
    else if (col == 1)
    {
        return [light info];
    }
    else if (col == 2)
    {
        return [NSNumber numberWithFloat:[light xPos]];
    }
    else if (col == 3)
    {
        return [NSNumber numberWithFloat:[light yPos]];
    }
    else if (col == 4)
    {
        return [NSNumber numberWithFloat:[light zPos]];
    }
    else if (col == 5)
    {
        return [NSNumber numberWithInt:[light value]];
    }
    else if (col == 6)
    {
        return [NSNumber numberWithInt:[light value]];
    }
    else if (col == 7)
    {
        return [NSNumber numberWithInt:[light DMXChannel]];
    }
    else if (col == 8)
    {
        return [NSNumber numberWithInt:[light DMXUniverse]];
    }
    else if (col == 9)
    {
        return [light filterLabel];
    }
    
    return nil;
}

- (void)tableView:(NSTableView *)tableView setObjectValue:(id)object forTableColumn:(NSTableColumn *)tableColumn row:(NSInteger)row
{
    if (tableView == lightTable)
    {
        NSUInteger col = [tableView.tableColumns indexOfObject:tableColumn];
        BUNLight * editedLight = [self.lights objectAtIndex:row];
        if (col == 0)
        {
            if ([self availableInternalNumber:[object intValue]])
            {    
                [editedLight setValue:[NSNumber numberWithInt:[object intValue]] forKey:@"internalNumber"];
            }
        }
        else if (col == 1)
        {
            editedLight.info = (NSString *)object;
        }
        
        else if (col == 2)
        {
            editedLight.xPos = [[(NSString*)object stringByReplacingOccurrencesOfString:@"," withString:@"."] floatValue];
        }
        else if (col == 3)
        {
            editedLight.yPos = [[(NSString*)object stringByReplacingOccurrencesOfString:@"," withString:@"."] floatValue];
        }
        else if (col == 4)
        {
            editedLight.zPos = [[(NSString*)object stringByReplacingOccurrencesOfString:@"," withString:@"."] floatValue];
        }
        else if (col == 5)
        {
            editedLight.value = [object intValue];
        }
        else if (col == 6)
        {
            editedLight.value = [object intValue];
        }
        else if (col == 7)
        {
            editedLight.DMXChannel = [object intValue];
        }
        else if (col == 8)
        {
            editedLight.DMXUniverse = [object intValue];
        }
        else if (col == 9)
        {
            editedLight.filterLabel = object;
            editedLight.fader.view.toolTip = editedLight.info;
            
            NSColor * col = [NSColor colorWithRed:[[[self rgbValueForFilterLabel:editedLight.filterLabel] objectForKey:@"r"] floatValue]/255
                                            green:[[[self rgbValueForFilterLabel:editedLight.filterLabel]objectForKey:@"g"] floatValue]/255
                                             blue:[[[self rgbValueForFilterLabel:editedLight.filterLabel]objectForKey:@"b"] floatValue]/255
                                            alpha:1.0];
            
            editedLight.fader.label.textColor = col;
            editedLight.fader.value.backgroundColor = col;
        }
    }
    [self refreshLightPaths];
    [sequence.sequenceView redrawBack];
}




@end
