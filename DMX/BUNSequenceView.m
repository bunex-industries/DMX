//
//  BUNTimeLineView.m
//  DMX
//
//  Created by JFR on 08/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import "BUNScene.h"
#import "BUNSequenceView.h"
#import "BUNSequence.h"
#import "BUNStep.h"

@implementation BUNSequenceView
@synthesize sequence, percentOftransition, scale;

-(id)initWithFrame:(NSRect)frameRect andSequence:(BUNSequence*)seq
{
    self = [super initWithFrame:frameRect];
    if (self != nil)
    {
        sequence = seq;
        scale = 30.0;
        NSFont * font = [NSFont fontWithName:@"Helvetica" size:8];
        NSTextAlignment align = NSCenterTextAlignment;
        NSMutableParagraphStyle * pgs = [[NSMutableParagraphStyle alloc] init];
        pgs.alignment = align;
        
         attr = [NSDictionary dictionaryWithObjectsAndKeys:
                               font,NSFontNameAttribute,
                               pgs,NSParagraphStyleAttributeName,
                               [NSColor blackColor], NSForegroundColorAttributeName,
                               nil];
        
        
        
        return self;
    }
    return nil;
}

-(void)drawBack
{
    backImage = [[NSImage alloc] initWithSize:self.bounds.size];
    [backImage lockFocus];
    
    [[NSColor grayColor] set];
    NSRectFill(self.bounds);
    
    [[NSColor whiteColor] setStroke];
    for (int i = 0; i < self.bounds.size.width/scale; i++)
    {
        [[NSString stringWithFormat:@"%d", i] drawInRect:NSMakeRect(i*scale-15, 0, 30, 15) withAttributes:attr];
        NSBezierPath * line = [NSBezierPath bezierPath];
        [line moveToPoint:NSMakePoint(i*scale, 20)];
        [line lineToPoint:NSMakePoint(i*scale, self.bounds.size.height)];
        [line setLineWidth:0.1];
        [line stroke];
        
        // autoplay segments
        if([sequence.steps objectAtIndex:MIN(i, sequence.steps.count-1)] !=nil)
        {
            BUNStep * step = [sequence.steps objectAtIndex:MIN(i, sequence.steps.count-1)];
            [NSBezierPath setDefaultLineWidth:4];
            if (step.autoplay == YES)
            {
                [[NSColor greenColor] setStroke];
                [NSBezierPath strokeLineFromPoint:NSMakePoint(i*scale , self.frame.size.height-5)
                                          toPoint:NSMakePoint((i+1)*scale, self.frame.size.height-5)];
                
            }
            [NSBezierPath setDefaultLineWidth:1];
        }
        
    }
    
    
    
    BUNScene * scene = sequence.scene;
    NSMutableArray * lights = scene.lights;
    
    for (BUNLight * light in lights)
    {
        NSDictionary * rgbValue = [scene rgbValueForFilterLabel:light.filterLabel];
        NSBezierPath * path = light.path;
        
        [[NSColor colorWithRed:[[rgbValue objectForKey:@"r"] floatValue]/255
                         green:[[rgbValue objectForKey:@"g"] floatValue]/255
                          blue:[[rgbValue objectForKey:@"b"] floatValue]/255
                         alpha:1.0] set];
        [path stroke];
        for (int i = 0 ; i < path.elementCount ; i++)
        {
            path = [path bezierPathByFlatteningPath];
            NSPoint pt;
            [path elementAtIndex:i associatedPoints:&pt];
            [[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(pt.x-4, pt.y-4, 8, 8)] fill];

            
        }
    }
    
    [backImage unlockFocus];
    
    //NSLog(@"%@", backImage);
    //[self setNeedsDisplay:YES];
}

-(void)redrawBack
{
    
    backImage = nil;
    [self setNeedsDisplay:YES];
    
}

- (void)drawRect:(NSRect)dirtyRect
{
    [super drawRect:dirtyRect];
    
    if (backImage == nil)
    {
        [self drawBack];
    }
    [backImage drawInRect:dirtyRect fromRect:dirtyRect operation:NSCompositeSourceOver fraction:1.0];
    
    if (sequence.selectedStep != nil)
    {
        [[NSColor colorWithRed:0 green:0 blue:0 alpha:0.5] setFill];
        [[NSBezierPath bezierPathWithRect:NSMakeRect(scale*[sequence.steps indexOfObject:sequence.selectedStep] - 15 + scale*percentOftransition, 20, 30, self.frame.size.height)] fill];
    }


}




-(void)mouseDown:(NSEvent *)theEvent
{
    NSPoint pt = [self convertPoint:[theEvent locationInWindow] fromView:nil];
    int stepIndex = round(pt.x/scale);

    if (stepIndex >= sequence.steps.count)
    {
        sequence.selectedStep = nil;
    }
    else
    {
        [sequence selectStepAtIndex:stepIndex];
        if ([theEvent clickCount] == 2)
        {
            [sequence.DMXUniverse0 setDmxData:[sequence.selectedStep dmxData]];
        }
        
    }
    
    [self setNeedsDisplay:YES];
}

-(void)mouseDragged:(NSEvent *)theEvent
{
    [self mouseDown:theEvent];
}



-(void)setScale:(float)s
{
    scale = s;
    backImage = nil;
    [self setNeedsDisplay:YES];
}



-(float)scale
{
    return scale;
}


@end
