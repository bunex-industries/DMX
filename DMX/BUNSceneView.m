//
//  BUNSceneView.m
//  DMX
//
//  Created by JFR on 09/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import "BUNSceneView.h"

@implementation BUNSceneView

-(id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    BOOL loaded = [self loadCompositionFromFile:[[NSBundle mainBundle] pathForResource:@"scene" ofType:@"qtz"]];
    if (loaded)
    {
        [self setEventForwardingMask:NSAnyEventMask];
        [self startRendering];
        return self;
    }
    return nil; 
}



@end
