//
//  BUNFader.m
//  DMX
//
//  Created by JFR on 12/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import "BUNFader.h"
#import "BUNAppDelegate.h"

@implementation BUNFader

@synthesize label;
@synthesize value;
@synthesize slider;
@synthesize checker;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self)
    {
        enabled = NO;
    }
    return self;
}


-(void)awakeFromNib
{
    [self.slider setIntValue:0];
    [self.value setIntValue:0];
}

-(void)setEnabled:(BOOL)e
{
    [label setEnabled:e];
    [slider setEnabled:e];
    [checker setEnabled:e];
    [value setEnabled:e];
    
    self.view.alphaValue = e ? 1.0 : 0.1;
    if (e == NO)
    {
        slider.intValue = 0;
        value.intValue = 0;
        currentValue = 0;
    }
}

-(BOOL)isEnabled
{
    return enabled;
}

-(IBAction)sliderAction:(NSSlider*)sldr
{
    [self adjustValue:sldr.intValue];
    [(BUNAppDelegate*)[NSApp delegate] updateStep:nil];
}

-(IBAction)valueEntered:(NSTextField*)txtf
{
    [self adjustValue:txtf.intValue];
    [(BUNAppDelegate*)[NSApp delegate] updateStep:nil];
}

-(void)adjustValue:(int)v
{
    
    int prevValue = currentValue;
    [[[self.view.window undoManager] prepareWithInvocationTarget:self] adjustValue:prevValue];
    [[self.view.window undoManager] setActionName:@"fader adustment"];
    v = MAX(0,MIN(255, v));
    slider.intValue = v;
    value.intValue = v;
    currentValue = v;
    
    //
}


@end
