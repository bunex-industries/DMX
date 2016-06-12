//
//  BUNFader.h
//  DMX
//
//  Created by JFR on 12/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface BUNFader : NSViewController
{
    BOOL enabled;
    int currentValue;
}

@property (strong) IBOutlet NSTextField * label;
@property (strong) IBOutlet NSTextField * value;
@property (strong) IBOutlet NSSlider * slider;
@property (strong) IBOutlet NSButton * checker;

-(IBAction)sliderAction:(NSSlider*)sldr;
-(IBAction)valueEntered:(NSTextField*)txtf;
-(void)adjustValue:(int)v;

-(void)setEnabled:(BOOL)e;
-(BOOL)isEnabled;

@end
