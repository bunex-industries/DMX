//
//  BUNLight.m
//  DMX
//
//  Created by JFR on 08/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import "BUNLight.h"
#import "BUNAppDelegate.h"


@implementation BUNLight
@synthesize info, internalNumber, xPos, yPos, zPos, value, DMXChannel, DMXUniverse, filterLabel, path, fader;


-(id)init
{
    self = [super init];
    [self addObserver:self forKeyPath:@"internalNumber" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self addObserver:self forKeyPath:@"filterLabel" options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
    [self setValue:[NSNumber numberWithInt:-1] forKey:@"internalNumber"];
    return self;
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    NSMutableArray * faderArray = [(BUNAppDelegate*)[NSApp delegate] faderArray];
    if (self.internalNumber != -1 && [keyPath isEqualToString:@"internalNumber"])
    {
        if ([change objectForKey:@"old"] != nil && [[change objectForKey:@"old"] intValue] != -1)
        {
            BUNFader * oldFader = [faderArray objectAtIndex:[[change objectForKey:@"old"] intValue]];
            [oldFader setEnabled:NO];
        }
        
        self.fader = [faderArray objectAtIndex:self.internalNumber];
        self.fader.view.toolTip = self.info;
        
        NSColor * col = [NSColor colorWithRed:[[[[(BUNAppDelegate*)[NSApp delegate] scene] rgbValueForFilterLabel:self.filterLabel] objectForKey:@"r"] floatValue]/255
                                        green:[[[[(BUNAppDelegate*)[NSApp delegate] scene] rgbValueForFilterLabel:self.filterLabel]objectForKey:@"g"] floatValue]/255
                                         blue:[[[[(BUNAppDelegate*)[NSApp delegate] scene] rgbValueForFilterLabel:self.filterLabel]objectForKey:@"b"] floatValue]/255
                                        alpha:1.0];
                         
        fader.label.textColor = col;
        fader.value.backgroundColor = col;
        
        [self.fader setEnabled:YES];
    }
    
}


-(void)dealloc
{
    NSLog(@"Deallocation of light #%d", self.internalNumber);

    [self removeObserver:self forKeyPath:@"internalNumber"];
    [self removeObserver:self forKeyPath:@"filterLabel"];
}


+(id)newLightWithInternalNumber:(int)inn
                           info:(NSString*)n
                           xPos:(float)x
                           yPos:(float)y
                           zPos:(float)z
                          value:(int)v
                     DMXChannel:(int)dmxc
                    DMXUniverse:(int)dmxu
                    filterLabel:(NSString*)fl
{
    BUNLight * light = [[BUNLight alloc] init];
    
    
    light.info = n;
    light.xPos = x;
    light.yPos = y;
    light.zPos = z;
    light.value = v;
    light.DMXChannel = dmxc;
    light.DMXUniverse = dmxu;
    //light.filterLabel = fl;
    [light setValue:fl forKey:@"filterLabel"];
    [light setValue:[NSNumber numberWithInt:inn] forKey:@"internalNumber"];
    
    return light;
}




@end
