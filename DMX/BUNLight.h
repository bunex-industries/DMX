//
//  BUNLight.h
//  DMX
//
//  Created by JFR on 08/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import "BUNFader.h"

@interface BUNLight : NSObject
{

}

@property (strong) NSString * info;
@property int internalNumber;
@property int DMXChannel;
@property int DMXUniverse;
@property int value;
@property float xPos;
@property float yPos;
@property float zPos;

@property (strong) NSBezierPath * path;
@property (strong) NSString * filterLabel;
@property (strong) BUNFader * fader;




+(id)newLightWithInternalNumber:(int)inn
                           info:(NSString*)n
                           xPos:(float)x
                           yPos:(float)y
                           zPos:(float)z
                          value:(int)v
                     DMXChannel:(int)dmxc
                    DMXUniverse:(int)dmxu
                    filterLabel:(NSString*)fl;






@end
