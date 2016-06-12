//
//  BUNSerial.h
//  DMX
//
//  Created by JFR on 09/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//


#import <Cocoa/Cocoa.h>
#include <IOKit/IOKitLib.h>
#include <IOKit/serial/IOSerialKeys.h>
#include <IOKit/IOBSD.h>
#include <IOKit/serial/ioss.h>
#include <sys/ioctl.h>


@interface BUNSerial : NSObject
{
    
    NSString * incomingString;
    NSString * lastMessage;

    int serialFileDescriptor; 
	struct termios gOriginalTTYAttrs;
	bool readThreadRunning;
      
	int count;
    uint8_t dmxData[512];
    uint8_t nullDmxData[512];
    NSThread * dmxThread;
    speed_t baudRate;
    int pause;
    
    
}

@property (strong, nonatomic) NSMutableArray * serialList;
@property (strong, nonatomic) NSString *port;
@property BOOL alive;
@property BOOL blackOut;

-(NSString*)openSerialPort:(NSString *)serialPortFile baud:(speed_t)bauds;
-(void)setValue:(int)val forChannel:(int)cha;
-(void)setDmxData:(uint8_t*)d;
-(void)startDMXLoop;
-(void)refreshSerialList;
-(void)closeConnexion;
-(void)resetConnexion;

@end
