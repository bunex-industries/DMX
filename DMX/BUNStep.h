//
//  BUNStep.h
//  DMX
//
//  Created by JFR on 08/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "BUNLight.h"


@interface BUNStep : NSObject
{
    
}

@property (strong) NSMutableArray * lightStates;
@property (strong) NSMutableArray * previousStepsStream;
@property int millisecondToMe;
@property BOOL autoplay;
@property (strong) NSString* name;

+(id)newStepWithLights:(NSMutableArray*)l;
-(int)stepValueForLight:(BUNLight*)light;
-(void)updateFaders;
-(void)updateStep;
-(void)removeLightStateForLight:(BUNLight*)light;
-(uint8_t*)dmxData;
@end
