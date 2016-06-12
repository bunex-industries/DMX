//
//  BUNScene.h
//  DMX
//
//  Created by JFR on 09/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import "BUNLight.h"
#import "BUNSequence.h"
#import "BUNSceneView.h"

@interface BUNScene : NSObject <NSTableViewDataSource, NSTableViewDelegate>
{
    
}

@property (strong) NSMutableArray * lights;
@property (strong) NSTableView * lightTable;
@property (strong) BUNSequence * sequence;
@property (strong) BUNSceneView * sceneView;


-(id)init;

-(void)addLight;
-(void)removeLight;
-(void)sendLightsToQC;
-(void)sendLightsValuesToQC;
-(void)loadLightsWithPath:(NSString*)path;
-(void)saveLightsWithPath:(NSString*)path;
-(void)refreshLightPaths;
-(BUNLight*)lightWithInternalIndex:(int)index;
-(NSDictionary*)rgbValueForFilterLabel:(NSString*)filterLabel;


@end
