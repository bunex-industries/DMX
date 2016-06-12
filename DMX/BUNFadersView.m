//
//  BUNFadersView.m
//  DMX
//
//  Created by JFR on 12/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import "BUNFadersView.h"

@implementation BUNFadersView

- (void)drawRect:(NSRect)dirtyRect {
    [super drawRect:dirtyRect];
    [[NSColor grayColor] set];
    NSRectFill(dirtyRect);
}

-(BOOL)isFlipped
{
    return YES;
}


@end
