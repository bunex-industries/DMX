//
//  AppDelegate.h
//  DMX
//
//  Created by JFR on 08/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "BUNSerial.h"
#import "BUNScene.h"
#import "BUNLight.h"
#import "BUNFader.h"


@interface BUNAppDelegate : NSObject <NSApplicationDelegate, NSCollectionViewDelegate, NSTextFieldDelegate, NSControlTextEditingDelegate>
{
    
    //LIGHTS
    IBOutlet NSPopover * lightSetupPopover;
    IBOutlet NSTableView * lightTable;
    IBOutlet NSSlider * groupLevelSlider;
    IBOutlet NSTextField * groupLevelTextField;
    
    //SCENE
    IBOutlet NSView * sceneViewContainer;
    
    //SEQUENCE
    IBOutlet NSSlider * scaleSlider;
    IBOutlet NSButton * instantApplication;
    
    
    //FADERS
    IBOutlet NSView * faderContainer;
    
    //HARDWARE
    IBOutlet NSPopover * hardwareSetupPopover;
    IBOutlet NSPopUpButton * hardwareList0;
    IBOutlet NSPopUpButton * hardwareList1;
    BUNSerial * DMXUniverse0;
    BUNSerial * DMXUniverse1;
    
    BOOL directFaders;
}
@property BOOL isEditing ;
@property (strong) NSMutableArray * faderArray;
@property (strong) BUNScene * scene;
@property (strong) IBOutlet NSScrollView * sequenceViewContainer;
@property (strong) IBOutlet NSTextField * transitionTimeField;
@property (strong) IBOutlet NSTextField * nameField;
@property (strong) IBOutlet NSButton * autoplayButton;
@property float scale;
@property (weak) IBOutlet NSWindow *window;
-(void)generateFaders;

//LIGHTS ACTIONS
-(IBAction)popLightSetup:(NSButton*)btn;
-(IBAction)confirmLightSetup:(NSButton*)btn;
-(IBAction)addLight:(NSButton*)btn;
-(IBAction)removeLight:(NSButton*)btn;
-(IBAction)loadLights:(NSButton*)btn;
-(IBAction)saveLights:(NSButton*)btn;
-(IBAction)blackOut:(NSButton*)btn;
-(IBAction)offlineMode:(NSButton*)btn;
-(IBAction)groupLevelAdjust:(NSSlider*)sldr;
-(IBAction)groupLevelValueEntered:(NSTextField*)txtf;

//SEQUENCE ACTIONS
-(IBAction)scaleAdjust:(NSSlider*)sldr;
-(IBAction)addAStep:(NSButton*)btn;
-(IBAction)removeSelectedStep:(NSButton*)btn;
-(IBAction)insertAfterSelectedStep:(NSButton*)btn;
-(IBAction)splitStep:(NSButton*)btn;
-(IBAction)updateStep:(NSButton*)btn;
-(IBAction)loadSteps:(NSButton*)btn;
-(IBAction)saveSteps:(NSButton*)btn;
-(IBAction)nextStep:(NSButton*)btn;
-(IBAction)previousStep:(NSButton*)btn;
-(IBAction)instantApplicationModeChange:(NSButton*)btn;
-(IBAction)transitionTimeSet:(NSTextField*)txtf;


//HARDWARE ACTIONS
-(IBAction)configureHardware:(NSButton*)btn;
-(IBAction)confirmHardwareSetup:(NSButton*)btn;
-(IBAction)refreshHardwareList:(NSButton*)btn;
-(IBAction)closeConnexion:(id)sender;

@end

