//
//  BUNSequence.h
//  DMX
//
//  Created by JFR on 08/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "BUNStep.h"
#import "BUNSequenceView.h"
#import "BUNSerial.h"

@class BUNScene;

@interface BUNSequence : NSObject
{
    float timeInterval;
    int count;
    BOOL autoplay;
    NSDate *lastdate;
}

@property (strong) BUNSerial * DMXUniverse0;
@property (strong) BUNSerial * DMXUniverse1;

@property BOOL applyInstantly;
@property BOOL isAdjusting;
@property int transitionDuration;
@property int transitionPosition;
@property BOOL reverse;
@property (strong) BUNStep * nextStepToPlay;
@property (strong) BUNStep * volatileStep;
@property (strong) BUNScene * scene;
@property (strong) BUNStep * selectedStep;
@property (strong) NSMutableArray * steps;
@property (strong) BUNSequenceView * sequenceView;

-(id)initWithScene:(BUNScene*)s;

-(void)addStep;
-(void)deleteStep;
-(void)insertStep;
-(void)splitStep;

-(void)loadStepsAtPath:(NSString*)path;
-(void)saveStepsAtPath:(NSString*)path;

-(void)nextStep;
-(void)previousStep;

-(void)selectStepAtIndex:(int)si;

-(void)timeTop;
-(void)precomputeTransitions;
@end
