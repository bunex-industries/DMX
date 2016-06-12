//
//  BUNTimeLineView.h
//  DMX
//
//  Created by JFR on 08/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class BUNSequence;

@interface BUNSequenceView : NSView
{
    
    NSDictionary * attr;

    NSImage * backImage;
}

@property (strong) BUNSequence * sequence;
@property float percentOftransition;
@property float scale;
-(id)initWithFrame:(NSRect)frameRect andSequence:(BUNSequence*)seq;

-(void)setScale:(float)s;
-(float)scale;
-(void)redrawBack;
@end
