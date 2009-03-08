//
//  ScriptMenuController.m
//  System
//
//  Created by ash on 01.03.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "ScriptMenuController.h"

#ifndef DEBUG
#define DEBUG_MODE true
#else
#define DEBUG_MODE false
#endif

@implementation ScriptMenuController

- (id)init
{
	if (DEBUG_MODE) NSLog(@"SystemAppliance: ScriptMenuController - init");
	
	//create an instance variable of NSWorkspace - needed for some file operations, like opeing
	workspace = [NSWorkspace sharedWorkspace];
	//create an instance varialbe of our BackRowHelper - offers useful features
	helper = [BackRowHelper sharedInstance];

	//load the default icon for the preview panel on the left side of the menu
	NSBundle *selfBundle = [NSBundle bundleForClass:[self class]];
	NSString *pathToExeceutableIcon = [selfBundle  pathForResource:@"ExecutableBinaryIcon" ofType:@"png"];
	scriptFileImage = [[BRImage imageWithPath:pathToExeceutableIcon] retain];
	
	return [super init];
}


- (void)dealloc
{
	if (DEBUG_MODE) NSLog(@"SystemAppliance: ScriptMenuController - dealloc");
	
	//if frontrow is hidden, show it again
	[helper showFrontRow];	

	//deleting all the instance variables from memory
	//helper is a singleton, so deallocing is not needed
	[identifier release];
	[allScripts release];
	[pathToScriptFolder release];
	[selectedScript release];
	[scriptFileImage release];
	[menuItems release];
	[scriptFileImage release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];  
}

//load all scripts and add it to the listing
- (id)initWithIdentifier:(NSString *) initId withPath: (NSString *)path withScripts:(NSMutableArray *)scripts
{
	//set the title of the menu
	[self addLabel:@"at.ash.SystemAppliance.ScriptMenuController"];
	[self setListTitle: [BRLocalizedStringManager appliance: self
									  localizedStringForKey: initId
													 inFile: @"InfoPlist"]];
	
	//set the passed arguements to the corresponding instance variables
	identifier = initId;
	allScripts = scripts;
	pathToScriptFolder = path;
	[allScripts retain];
	
	//if (DEBUG_MODE) NSLog(@"SystemAppliance: ScriptMenuController - initWithIdentifier:%@ WithScripts:%@", initId, allScripts);
	
	//iterate over all scripts in the scripts section of the preference list
	NSEnumerator *enumerator = [scripts objectEnumerator];
	menuItems = [[NSMutableArray alloc] initWithObjects:nil];
	
	id obj;
	while((obj = [enumerator nextObject]) != nil) {
		//create a new menu item and set the title
		id item = [[BRTextMenuItemLayer alloc] init];
		[item setTitle: [obj valueForKey:@"name"]];
		
		if (DEBUG_MODE) NSLog(@"SystemAppliance: add menu item = %@", [obj valueForKey:@"name"]);
		
		//add the menu item to the array of menuitems
		[menuItems addObject:item];
	}
	
	//return the array of menu itesm
	id list = [self list];
	[list setDatasource: self];
	
	return self;
}

//called when clicking play/pause on the selected menu item
- (void)itemSelected:(long)fp8
{
	//if (DEBUG_MODE) NSLog([NSString stringWithFormat:@"SystemAppliance: ScriptMenuController - itemSelected, row=%i",fp8]);
	//if (DEBUG_MODE) NSLog(@"SystemAppliance: all scripts = %@.", allScripts);
	
	//read the script name and the launchtype (faw, faf, ex)
	NSString *launchTypeOfSelectedScript = [[allScripts objectAtIndex:fp8] valueForKey:@"launchtype"];
	NSString *scriptName = [[allScripts objectAtIndex:fp8] valueForKey:@"name"];
	//selectedScript = [[allScripts objectAtIndex:fp8] valueForKey:@"path"];

	//run the script with the chosen launchtype
	if ([launchTypeOfSelectedScript isEqualToString:@"faf"]) {
		if (DEBUG_MODE) NSLog(@"SystemAppliance: launching script (faf) %@.", selectedScript);
		
		[helper runScriptWithPathToScript:selectedScript WaitForScript:NO];
	} else 	if ([launchTypeOfSelectedScript isEqualToString:@"faw"]) {
		if (DEBUG_MODE) NSLog(@"SystemAppliance: launching script (faw) %@.", selectedScript);
		
		NSString *scriptOutput = [helper runScriptWithPathToScript:selectedScript WaitForScript:YES];
		
		//create a new alert controller, that displays the console output of the script
		BRAlertController *alert = [BRAlertController alertOfType:0
														   titled:[@"Output of " stringByAppendingString: scriptName]
													  primaryText:@""
													secondaryText:scriptOutput];
		//scriptRunning = YES;
		
		//show the newly created alert controler
		[[self stack] pushController:alert];
	} else 	if ([launchTypeOfSelectedScript isEqualToString:@"ex"]) {
		if (DEBUG_MODE) NSLog(@"SystemAppliance: launching script (ex) %@.", selectedScript);
		
		scriptRunning = YES;

		//show an alert controller, same as above
		BRAlertController *alert = [BRAlertController alertOfType:0
														   titled:scriptName
													  primaryText:@"If the script launched an applications, then this application has not yet quitted!"
													secondaryText:@"Start applications in the Applications Menu to be able to quit them with the Apple Remote."];
		
		[[self stack] pushController:alert];
		
		//use the BackRowHelper to launch the script, then hide frontrow
		[helper runScriptWithPathToScript:selectedScript WaitForScript:NO];
		[helper hideFrontRowSetResponderTo:self];
	}
}

//display an image on the left side of the menu
- (id)previewControlForItem:(long)fp8
{
	selectedScript = [[allScripts objectAtIndex:fp8] valueForKey:@"path"];

	if (DEBUG_MODE) NSLog(@"SystemAppliance: previewControlForItem - script = %@.", selectedScript);				
	
	//load the preview pane for the left side and ...
	BRImageAndSyncingPreviewController *imageControl = [[BRImageAndSyncingPreviewController alloc] init];
	//set the icon to the default script file icon loaded in -init()
	[imageControl setImage:scriptFileImage];
	return imageControl;
}

//process the keycodes of the Apple Remote
- (BOOL)brEventAction:(BREvent *)event
{
	if (scriptRunning) {
		unsigned int hashVal = (uint32_t)([event page] << 16 | [event usage]);
		if ([(BRControllerStack *)[self stack] peekController] != self) hashVal = 0;
		if (DEBUG_MODE) NSLog([NSString stringWithFormat:@"hashVal = %i",hashVal]);
		
		switch (hashVal) {
			case 65676:		// tap up
				if (DEBUG_MODE) NSLog(@"SystemAppliance: brEventAction: tap up");				
				break;
			case 65677:		// tap down
				if (DEBUG_MODE) NSLog(@"SystemAppliance: brEventAction: tap down");
				break;
			case 65675:		// tap left
				if (DEBUG_MODE) NSLog(@"SystemAppliance: brEventAction: tap left");
				break;
			case 65674:		// tap right
				if (DEBUG_MODE) NSLog(@"@SystemAppliance:brEventAction: tap right");
				break;
			case 65670:		// tap menu
				if (DEBUG_MODE) NSLog(@"SystemAppliance: brEventAction (menu) - quiting %@", selectedScript);

				scriptRunning = NO;
				
				[helper showFrontRow];
				[[self stack] popController];
				
				return YES;
				break;
				
			case 65673:		// tap play
				if (DEBUG_MODE) NSLog(@"SystemAppliance: brEventAction (play/pause) - restaring %@", selectedScript);			
				break;
		}
		return NO;
	}
	else {
		return [super brEventAction:event];
	}
}

// Don't know what that does, copied it from Emulators Plugin
- (long)defaultIndex				{ return 0; }


// Data source methods:
- (float)	heightForRow:(long)row		{ return 0.0f; }
- (BOOL)	rowSelectable:(long)row		{ return YES;}
- (long)	itemCount					{ return (long)[menuItems count];}
- (id)		itemForRow:(long)row			{ return [menuItems objectAtIndex:row]; }
- (long)	rowForTitle:(id)title		{ return (long)[menuItems indexOfObject:title]; }
- (id)		titleForRow:(long)row			{ return [[menuItems objectAtIndex:row] title]; }


// Partially borrowed from SapphireCompatibilityClasses:
- (long)getSelection
{
	BRListControl *list = [self list];
	NSMethodSignature *signature = [list methodSignatureForSelector:@selector(selection)];
	NSInvocation *selInv = [NSInvocation invocationWithMethodSignature:signature];
	[selInv setSelector:@selector(selection)];
	[selInv invokeWithTarget:list];
	long row = 0;
	[selInv getReturnValue:&row];
	return row;
}

@end
