//
//  AppDelegate.m
//  DMX
//
//  Created by JFR on 08/11/2014.
//  Copyright (c) 2014 JFR. All rights reserved.
//

#import "BUNAppDelegate.h"

@interface BUNAppDelegate ()

@end


@implementation BUNAppDelegate
@synthesize scene, scale, sequenceViewContainer, faderArray, transitionTimeField, autoplayButton, isEditing, nameField, window;


-(BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender
{
    return YES;
}


-(void)controlTextDidBeginEditing:(NSNotification *)obj
{
    isEditing = YES;
    NSLog(@"text editing");
}

-(void)controlTextDidEndEditing:(NSNotification *)obj
{    
    [[self window] endEditingFor:obj.object];
    [self.window makeFirstResponder:[obj.object nextResponder]];
    isEditing = NO;
}



-(void)applicationWillTerminate:(NSNotification *)notification
{
    NSLog(@"Closing connexions...");
    if (DMXUniverse0.alive)
    {
        //[DMXUniverse0 closeConnexion];
        NSLog(@"DMX0 connexion closed");
    }
    
    if (DMXUniverse1.alive)
    {
        //[DMXUniverse1 closeConnexion];
        NSLog(@"DMX1 connexion closed");
    }
    NSLog(@"Application terminates");
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    [[self window] endEditingFor:groupLevelTextField];
    [[self window] endEditingFor:transitionTimeField];
    [[self window] endEditingFor:nameField];
    [self.window makeFirstResponder:[transitionTimeField nextResponder]];
    isEditing = NO;
    directFaders = NO;
      [[NSUserDefaults standardUserDefaults] removePersistentDomainForName:[[NSBundle mainBundle] bundleIdentifier]];
    
    [self.window setBackgroundColor:[NSColor darkGrayColor]];
    
    DMXUniverse0 = [[BUNSerial alloc] init];
    DMXUniverse1 = [[BUNSerial alloc] init];
    
    [scaleSlider setFloatValue:30];
    [self scaleAdjust:scaleSlider];
    
    scene = [[BUNScene alloc] init];
    scene.lightTable = lightTable;
    [scene.lightTable setDelegate:scene];
    [scene.lightTable setDataSource:scene];
    
    NSComboBoxCell * combo = [[scene.lightTable.tableColumns objectAtIndex:9] dataCell];
    [combo removeAllItems];
    NSError * err;
    NSMutableArray * filterLabels = [NSMutableArray array];
    NSArray * filterLines = [[NSString stringWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"filters" ofType:@"txt"] encoding:NSUTF8StringEncoding error:&err] componentsSeparatedByString:@"\n"];
    for (NSString * filterLine in filterLines)
    {
        NSArray * filterComponents = [filterLine componentsSeparatedByString:@";"];
        [filterLabels addObject:[NSString stringWithFormat:@"%@_%@ %@ %@", [filterComponents objectAtIndex:0], [filterComponents objectAtIndex:2], [filterComponents objectAtIndex:1], [filterComponents objectAtIndex:3]]];
    }
    [combo addItemsWithObjectValues:filterLabels];
    
    
    [sceneViewContainer addSubview:scene.sceneView];
    [scene.sceneView setTranslatesAutoresizingMaskIntoConstraints:NO];
    
    QCView * qcView = scene.sceneView;
    NSDictionary *views = NSDictionaryOfVariableBindings(qcView);
    [self.window.contentView addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[qcView]|"
                                             options:0
                                             metrics:nil
                                               views:views]];
    
    [self.window.contentView addConstraints:
     [NSLayoutConstraint constraintsWithVisualFormat:@"V:|[qcView]|"
                                             options:0
                                             metrics:nil
                                               views:views]];
    
    
    sequenceViewContainer.contentView.documentView = scene.sequence.sequenceView;
    [scene.sequence.sequenceView setFrameSize:NSMakeSize(3000, sequenceViewContainer.frame.size.height)];

    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"lightsFilePath"] != nil)
    {
        BOOL isDir;
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[[NSUserDefaults standardUserDefaults] objectForKey:@"lightsFilePath"] isDirectory:&isDir];
        if (exists && !isDir)
        {
            [scene loadLightsWithPath:[[NSUserDefaults standardUserDefaults] objectForKey:@"lightsFilePath"]];
        }
        
    }
    
    [self generateFaders];
    
    [faderContainer scrollPoint:NSMakePoint(0, 0)];
    
    
    [self instantApplicationModeChange:instantApplication];
    
    if ([[NSUserDefaults standardUserDefaults] objectForKey:@"stepsFilePath"] != nil && scene.lights.count > 0)
    {
        BOOL isDir;
        BOOL exists = [[NSFileManager defaultManager] fileExistsAtPath:[[NSUserDefaults standardUserDefaults] objectForKey:@"stepsFilePath"] isDirectory:&isDir];
        if (exists && !isDir)
        {
            [scene.sequence loadStepsAtPath:[[NSUserDefaults standardUserDefaults] objectForKey:@"stepsFilePath"]];
        }
    }
    else
    {
        [self addAStep:nil];
        scene.sequence.selectedStep = [scene.sequence.steps objectAtIndex:0];
    }
    
    [groupLevelTextField setDelegate:self];
    [transitionTimeField setDelegate:self];
    [nameField setDelegate:self];
    
    scene.sequence.DMXUniverse0 = DMXUniverse0;
    scene.sequence.DMXUniverse1 = DMXUniverse1;
    
    //[self.window setFrame:[[NSScreen mainScreen] visibleFrame] display:YES];
}

-(void)generateFaders
{
    faderArray = [NSMutableArray array];

    for (int y = 0; y < 16; y++)
    {
        for (int x = 0; x < 32; x++)
        {
            int faderIndex = (x + 32*y);
            
            BUNFader * fader = [[BUNFader alloc] initWithNibName:@"BUNFader" bundle:[NSBundle mainBundle]];
            
            [fader.view setFrameOrigin:NSMakePoint(x*fader.view.bounds.size.width, y*fader.view.bounds.size.height)];
            [fader.label setStringValue:[NSString stringWithFormat:@"#%d", faderIndex]];
            
            BUNLight * li = [scene lightWithInternalIndex:faderIndex];
            if (li != nil)
            {
                li.fader = fader;
                fader.view.toolTip = li.info;
                NSColor * col = [NSColor colorWithRed:[[[scene rgbValueForFilterLabel:li.filterLabel] objectForKey:@"r"] floatValue]/255
                                                green:[[[scene rgbValueForFilterLabel:li.filterLabel] objectForKey:@"g"] floatValue]/255
                                                 blue:[[[scene rgbValueForFilterLabel:li.filterLabel] objectForKey:@"b"] floatValue]/255
                                                alpha:1.0];
                //NSLog(@"%@", [scene rgbValueForFilterLabel:li.filterLabel] );
                fader.label.textColor = col;
                fader.value.backgroundColor = col;
                [fader setEnabled:YES];
            }
            else
            {
                [fader setEnabled:NO];
            }
            
            [faderArray addObject:fader];

            [faderContainer addSubview:fader.view];
        }
    }
}


-(IBAction)scaleAdjust:(NSSlider*)sldr
{
    scale = sldr.floatValue;
    [scene.sequence.sequenceView setScale:scale];
    [scene refreshLightPaths];
}

-(IBAction)popLightSetup:(NSButton*)btn
{
    [lightSetupPopover showRelativeToRect:btn.frame ofView:self.window.contentView preferredEdge:0];
}

-(IBAction)confirmLightSetup:(NSButton*)btn
{
    [scene sendLightsToQC];
    [lightSetupPopover close];
}

-(IBAction)addLight:(NSButton*)btn
{
    [scene addLight];
}

-(IBAction)removeLight:(NSButton*)btn
{
    [scene removeLight];
}

-(IBAction)loadLights:(NSButton*)btn
{
    NSOpenPanel * panel = [NSOpenPanel openPanel];
    [panel setTitle:@"Please select a CSV file describing the light setup..."];
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:NO];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:@"csv"]];
    if ([panel runModal] == NSOKButton)
    {
        [[NSUserDefaults standardUserDefaults] setObject:[[[panel URLs] objectAtIndex:0] path] forKey:@"lightsFilePath"];
        [[NSUserDefaults standardUserDefaults] synchronize];
        
        [scene loadLightsWithPath:[[[panel URLs] objectAtIndex:0] path]];
        [scene.lightTable reloadData];
    }
}


-(IBAction)saveLights:(NSButton*)btn
{
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setAllowsOtherFileTypes:NO];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"csv"]];
    if ([savePanel runModal] == NSOKButton)
    {
        [scene saveLightsWithPath:savePanel.URL.path];
    }
}

-(IBAction)blackOut:(NSButton *)btn
{
    NSLog(@"BLACK OUT %@", btn.state ? @"ON": @"OFF");
    DMXUniverse0.blackOut = btn.state;
}

-(IBAction)offlineMode:(NSButton*)btn
{
    directFaders = btn.state;
    NSLog(@"%@", directFaders ? @"directFaders" : @"cues");
}


-(IBAction)groupLevelAdjust:(NSSlider *)sldr
{
    [groupLevelTextField setIntValue:[sldr intValue]];
    for (BUNFader * fader in  faderArray)
    {
        if (fader.checker.state == YES)
        {
            fader.slider.intValue = [sldr intValue];
            [fader sliderAction:fader.slider];
        }
    }
}

-(IBAction)groupLevelValueEntered:(NSTextField *)txtf
{
    [groupLevelSlider setIntValue:[txtf intValue]];
    for (BUNFader * fader in  faderArray)
    {
        if (fader.checker.state == YES)
        {
            fader.value.intValue = [txtf intValue];
            [fader valueEntered:fader.value];
        }
    }
}

////////////////////////////////////////////////////
////////////       SEQUENCE         ////////////////
////////////////////////////////////////////////////


-(IBAction)addAStep:(NSButton*)btn
{
    [scene.sequence addStep];
    [scene.sequence precomputeTransitions];
}


-(IBAction)removeSelectedStep:(NSButton*)btn
{
    [scene.sequence deleteStep];
    [scene.sequence precomputeTransitions];
}


-(IBAction)insertAfterSelectedStep:(NSButton*)btn
{
    if (scene.sequence.selectedStep != nil)
    {
        [scene.sequence insertStep];
    }
    [scene.sequence precomputeTransitions];
}


-(IBAction)splitStep:(NSButton*)btn
{
    if (scene.sequence.selectedStep != nil)
    {
        [scene.sequence splitStep];
    }
    [scene.sequence precomputeTransitions];
}


-(IBAction)loadSteps:(NSButton*)btn
{
    NSOpenPanel * panel = [NSOpenPanel openPanel];
    [panel setTitle:@"Please select a CSV file describing the steps"];
    [panel setCanChooseDirectories:NO];
    [panel setCanChooseFiles:YES];
    [panel setAllowsMultipleSelection:NO];
    [panel setAllowedFileTypes:[NSArray arrayWithObject:@"csv"]];
    if ([panel runModal] == NSOKButton)
    {
        [scene.sequence loadStepsAtPath:panel.URL.path];
    }
}


-(IBAction)saveSteps:(NSButton*)btn
{
    NSSavePanel * savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setAllowsOtherFileTypes:NO];
    [savePanel setAllowedFileTypes:[NSArray arrayWithObject:@"csv"]];
    if ([savePanel runModal] == NSOKButton)
    {
        [scene.sequence saveStepsAtPath:savePanel.URL.path];
    }
}



-(IBAction)updateStep:(NSButton *)btn
{
    [[self window] endEditingFor:groupLevelTextField];
    [[self window] endEditingFor:transitionTimeField];
    [self.window makeFirstResponder:[transitionTimeField nextResponder]];
    isEditing = NO;
    
    if (btn == nil && directFaders == YES && scene.sequence.isAdjusting == NO)
    {
        uint8_t dmxData[512] = {0};
        for (BUNLight *l in scene.lights)
        {
            dmxData[l.DMXChannel] = l.fader.value.stringValue.intValue;
        }
        
        [DMXUniverse0 setDmxData:dmxData];
        return;
    }
    
    if (scene.sequence.selectedStep != nil)
    {
        [scene.sequence.selectedStep updateStep];
        [scene refreshLightPaths];
        [scene.sequence.sequenceView redrawBack];
    }
    else
    {
        [[NSAlert alertWithMessageText:@"No step selected !" defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"can't update anything..."] runModal];
    }
    [scene.sequence precomputeTransitions];
    
}




-(IBAction)nextStep:(NSButton *)btn
{
    if (!isEditing)
    {
        [scene.sequence nextStep];
    }
}


-(IBAction)previousStep:(NSButton *)btn
{
    if (!isEditing)
    {
        [scene.sequence previousStep];
    }
}


-(IBAction)instantApplicationModeChange:(NSButton *)btn
{
    scene.sequence.applyInstantly = btn.state;
}


-(IBAction)transitionTimeSet:(NSTextField*)txtf
{
    
}


////////////////////////////////////////////////////
////////////       HARDWARE         ////////////////
////////////////////////////////////////////////////

-(IBAction)configureHardware:(NSButton*)btn
{
    [hardwareSetupPopover showRelativeToRect:btn.frame ofView:self.window.contentView preferredEdge:0];
    [self refreshHardwareList:nil];
}


-(IBAction)closeConnexion:(id)sender
{
    [DMXUniverse0 closeConnexion];
    [hardwareSetupPopover close];
    DMXUniverse0 = nil;
    DMXUniverse0 = [[BUNSerial alloc] init];
    scene.sequence.DMXUniverse0 = DMXUniverse0;
}


-(IBAction)confirmHardwareSetup:(NSButton*)btn
{
    speed_t baudrate = 250000;
    if (![[hardwareList0 titleOfSelectedItem] isEqualToString:@"none"])
    {
        if ([DMXUniverse0 alive] == NO)
        {
            NSString * error0 = [DMXUniverse0 openSerialPort:[hardwareList0 titleOfSelectedItem] baud:baudrate];
            if (error0 != nil)
            {
                NSAlert * alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Error with DMX universe 0\nport : %@\nbaudrate : %lu",[hardwareList0 titleOfSelectedItem], baudrate]  defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", error0];
                [alert runModal];
            }
            else
            {
                NSLog(@"DMXUniverse0 connexion established with %@ at %lu bauds", [hardwareList0 titleOfSelectedItem], baudrate);
                DMXUniverse0.alive = YES;
                //[DMXUniverse0 performSelectorInBackground:@selector(incomingTextUpdateThread:) withObject:[NSThread currentThread]];
            }
        }
    }
    
    if (![[hardwareList1 titleOfSelectedItem] isEqualToString:@"none"])
    {
        if ([DMXUniverse1 alive] == NO)
        {
            NSString * error1 = [DMXUniverse1 openSerialPort:[hardwareList1 titleOfSelectedItem] baud:baudrate];
            if (error1 != nil)
            {
                NSAlert * alert = [NSAlert alertWithMessageText:[NSString stringWithFormat:@"Error with DMX universe 1\nport : %@\nbaudrate : %lu",[hardwareList1 titleOfSelectedItem], baudrate]  defaultButton:@"OK" alternateButton:nil otherButton:nil informativeTextWithFormat:@"%@", error1];
                [alert runModal];
            }
            else
            {
                NSLog(@"DMXUniverse1 connexion established with %@ at %lu bauds", [hardwareList0 titleOfSelectedItem], baudrate);
                DMXUniverse1.alive = YES;
                //[DMXUniverse1 performSelectorInBackground:@selector(incomingTextUpdateThread:) withObject:[NSThread currentThread]];
            }
        }
    }
    [hardwareSetupPopover close];
}



-(IBAction)refreshHardwareList:(NSButton*)btn
{
    [hardwareList0 removeAllItems];
    [DMXUniverse0 refreshSerialList];
    [hardwareList0 addItemWithTitle:@"none"];
    [hardwareList0 addItemsWithTitles:DMXUniverse0.serialList];
    if (DMXUniverse0.port != nil)
    {
        [hardwareList0 selectItemWithTitle:DMXUniverse0.port];
    }
    else
    {
        [hardwareList0 selectItemWithTitle:@"none"];
    }
    
    [hardwareList1 removeAllItems];
    [DMXUniverse1 refreshSerialList];
    [hardwareList1 addItemWithTitle:@"none"];
    [hardwareList1 addItemsWithTitles:DMXUniverse1.serialList];
    if (DMXUniverse1.port != nil)
    {
        [hardwareList1 selectItemWithTitle:DMXUniverse1.port];
    }
    else
    {
        [hardwareList1 selectItemWithTitle:@"none"];
    }
}





@end
