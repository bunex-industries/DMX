//
//  BUNSerial.m
//  DMX
//
//  Created by JFR on 09/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//


#import "BUNSerial.h"

#define BRK 176 //µs
#define MAB 12 //µs
#define COUNT 512 // number of channel
#define FRAME 50000 // µs >> 20 frames per sec

@implementation BUNSerial
@synthesize serialList, port, alive, blackOut;

-(id)init
{
    self = [super init];
    if (self) {
        serialList = [[NSMutableArray alloc] init];
        incomingString = @"";
        lastMessage = @"";
        for (int i = 0; i<512 ; i++)
        {
            dmxData[i] = 0;
            nullDmxData[i] = 0;
        }
        
        self.blackOut = NO;
        self.alive = NO;
        return self;
    }
    return nil;
}


-(void) refreshSerialList
{
	io_object_t serialPort;
	io_iterator_t serialPortIterator;
	
	[serialList removeAllObjects];
	IOServiceGetMatchingServices(kIOMasterPortDefault, IOServiceMatching(kIOSerialBSDServiceValue), &serialPortIterator);
	while ((serialPort = IOIteratorNext(serialPortIterator))) 
    {
        NSString * portt = (__bridge_transfer NSString*)IORegistryEntryCreateCFProperty(serialPort, CFSTR(kIOCalloutDeviceKey),  kCFAllocatorDefault, 0);
        [serialList addObject:portt];
		IOObjectRelease(serialPort);
	}
	IOObjectRelease(serialPortIterator);
}


// open the serial port
//   - nil is returned on success
//   - an error message is returned otherwise
-(NSString *)openSerialPort:(NSString *)serialPortFile baud:(speed_t)bauds
{
    baudRate = bauds;
	int success;
	
	// close the port if it is already open
	if (serialFileDescriptor != -1)
    {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
		
		// wait for the reading thread to die
		while(readThreadRunning);
		
		// re-opening the same port REALLY fast will fail spectacularly... better to sleep a sec
		sleep(1.0);
	}
	
	// c-string path to serial-port file
	const char *bsdPath = [serialPortFile cStringUsingEncoding:NSASCIIStringEncoding];
	
	// Hold the original termios attributes we are setting
	struct termios options;
	
	// receive latency ( in microseconds )
	unsigned long mics = 3;
	
	// error message string
	NSString *errorMessage = nil;
	
	// open the port
	//     O_NONBLOCK causes the port to open without any delay (we'll block with another call)
	serialFileDescriptor = open(bsdPath, O_RDWR | O_NOCTTY | O_NONBLOCK );
	
	if (serialFileDescriptor == -1) { 
		// check if the port opened correctly
		errorMessage = @"Error: couldn't open serial port";
	} else {
		// TIOCEXCL causes blocking of non-root processes on this serial-port
		success = ioctl(serialFileDescriptor, TIOCEXCL);
		if ( success == -1) { 
			errorMessage = @"Error: couldn't obtain lock on serial port";
		} else {
			success = fcntl(serialFileDescriptor, F_SETFL, 0);
			if ( success == -1) { 
				// clear the O_NONBLOCK flag; all calls from here on out are blocking for non-root processes
				errorMessage = @"Error: couldn't obtain lock on serial port";
			} else {
				// Get the current options and save them so we can restore the default settings later.
				success = tcgetattr(serialFileDescriptor, &gOriginalTTYAttrs);
				if ( success == -1) { 
					errorMessage = @"Error: couldn't get serial attributes";
				} else {
					// copy the old termios settings into the current
					// you want to do this so that you get all the control characters assigned
					options = gOriginalTTYAttrs;
                    BOOL dmxSimple = NO;
                    if (dmxSimple)
                    {
                        cfmakeraw(&options);
                    }
                    else
                    {
                        options.c_cflag = (CS8 | CSTOPB | CLOCAL | CREAD);
                        options.c_lflag &= ~(ICANON | ECHO | ECHOE | ISIG);
                        options.c_oflag &= ~OPOST;
                        options.c_cc[ VMIN ] = 1;
                        options.c_cc[ VTIME ] = 0;
                    }
                    
					success = tcsetattr(serialFileDescriptor, TCSANOW, &options);
                    success = ioctl(serialFileDescriptor, IOSSIOSPEED, &baudRate);
                    success = ioctl(serialFileDescriptor, IOSSDATALAT, &mics);
                    success = tcflush(serialFileDescriptor, TCIOFLUSH);
                    
                    // set RS485 for sending
                    int flag;
                    success = ioctl(serialFileDescriptor, TIOCMGET, &flag);
                    flag &= ~TIOCM_RTS;     // clear RTS flag
                    success = ioctl(serialFileDescriptor, TIOCMSET, &flag);
                }
			}
		}
	}
	
	// make sure the port is closed if a problem happens
	if ((serialFileDescriptor != -1) && (errorMessage != nil)) {
		close(serialFileDescriptor);
		serialFileDescriptor = -1;
	}
    self.port = serialPortFile;
    
    if (errorMessage == nil)
    {
        self.alive = YES;

        long int totalData = (long int)BRK + (long int)MAB + (((long int)COUNT+1) * 11 * 1000000/(long int)baudRate);
        int totalTime = FRAME; // 20 packet per sec
        pause = MAX(totalTime - (int)totalData, 50);
        NSLog(@"DATA = %d µs PAUSE = %d µs TOTAL = %d µs",(int)totalData, pause, totalTime);
        if (pause==50)
        {
            NSLog(@"frame too long");
        }
        
        dmxThread = [[NSThread alloc] initWithTarget:self
                                                     selector:@selector(startDMXLoop)
                                                       object:nil];
        [dmxThread start];
    }
    
	return errorMessage;
}



-(void)closeConnexion
{
    if (serialFileDescriptor != -1)
    {
        close(serialFileDescriptor);
        serialFileDescriptor = -1;
    }
    
    self.alive = NO;
    self.port = @"none";
}


-(void)setValue:(int)val forChannel:(int)cha
{
    dmxData[cha] = val;
}


-(void)setDmxData:(uint8_t*)d
{
    for (int i = 0 ; i<COUNT; i++)
    {
        dmxData[i] = d[i];
    }
}

  /*
   Break (a space)
   (the packet start) 	>= 92 us 	100-120 us (Ujjal) 176 us (DMX512-A-2004) 	>= 88 us
   
   Mark after break
   (in packet start) 	>= 8 us 	12 us (Ujjal) 	4 us – < 1 s backward compatible  8 us – < 1 s DMX512-A-2004
   
   Slot/frame width 	44 us 	44 us 	44 us
   
   Inter-slot/frame time
  
   Mark time between slots 	< 1 s 	minimal 	< 1 s
  
   Mark before break
   (Idle time after packet) 	< 1 s 	minimal 	< 1 s
  
   Break to Break time (DMX2512 packet length) 	1204 us – 1 s 	minimal 	1196 us – 1.25 s
   
   */
  
-(void)startDMXLoop
{
    while (TRUE)
    {

        ioctl(serialFileDescriptor, TIOCSBRK, 0); //set break bit
        usleep(BRK);
        ioctl(serialFileDescriptor, TIOCCBRK, 0); //clear break bit
        
        usleep(MAB);
        
        write(serialFileDescriptor, "\0", 1);
        
        
        write(serialFileDescriptor, blackOut ? nullDmxData : dmxData, COUNT);
        
        usleep(pause);
    }
}


-(void)resetConnexion
{
	// set and clear DTR to reset an arduino	
	struct timespec interval = {0,100000000}, remainder;
	if(serialFileDescriptor!=-1) {
		ioctl(serialFileDescriptor, TIOCSDTR);
		nanosleep(&interval, &remainder); // wait 0.1 seconds
		ioctl(serialFileDescriptor, TIOCCDTR);
	}
}


@end





