//
//  ApplicationAlertController.m
//  SystemPlugin 0.1
//
//  Created by ash 2009.
//

#import "ApplicationAlertController.h"

#ifndef DEBUG
#define DEBUG_MODE true
#else
#define DEBUG_MODE false
#endif

@implementation ApplicationAlertController

//initialize the class
-(id)init {
	//load the BackRowHelper
	helper = [BackRowHelper sharedInstance];
	
	return [super init];
}

- (BOOL)runApplicationWithIdentifier:(NSString *)appIdentifier withName:(NSString *)appName withPath:(NSString *)appPath
{
	if (DEBUG_MODE) NSLog(@"SystemAppliance: ApplicationAlertController - runApplicationWithIdentifier");

	appRunning = [helper runApplicationWithIdentifier:appIdentifier withName:appName withPath:appPath];
	
	if (appRunning) {
		if (DEBUG_MODE) NSLog(@"SystemAppliance: runApplicationWithIdentifier");
		
		//[self setTitle:[NSString stringWithFormat:@"Starting %@", appName]];
//		[self setPrimaryText:@""];
//		[self setSecondaryText:appPath];
		
		[helper hideFrontRowSetResponderTo:self];
	} else  {
		if (DEBUG_MODE) NSLog(@"SystemAppliance: failed to start app");
		
		[self setTitle:@"Error"];
		[self setPrimaryText:[NSString stringWithFormat:@"Could not start %@", appName]];
		[self setSecondaryText:appPath];
		
		[[self stack] popController];
		
		return NO;
	}
	
	// NSImage *theIcon = [workspace iconForFile:[workspace fullPathForApplication:identifier]];
	// CGImageRef *imgRef = ???
	// [self->_image setImage:[BRImage imageWithCGImageRef:imgRef]];
	
	return appRunning;
}


- (BOOL)runScriptWithIdentifier:(NSString *)scriptIdentifier withName:(NSString *)scriptName withPath:(NSString *)scriptPath
{
	if (DEBUG_MODE) NSLog(@"SystemAppliance: ApplicationAlertController - runScriptWithIdentifier");
	
	workspace = [NSWorkspace sharedWorkspace];
	identifier = scriptIdentifier;
	name = scriptName;
	path = scriptPath;
	
	NSLog(@"Opening script %@",identifier);
	appRunning = [workspace launchApplication:identifier];
	
	[[NSWorkspace sharedWorkspace] openFile: scriptPath];
	
	if (appRunning) [helper hideFrontRowSetResponderTo:self];
	
	// NSImage *theIcon = [workspace iconForFile:[workspace fullPathForApplication:identifier]];
	// CGImageRef *imgRef = ???
	// [self->_image setImage:[BRImage imageWithCGImageRef:imgRef]];
	
	return appRunning;
}

- (BOOL)brEventAction:(BREvent *)event
{	
	// unsigned int hashVal = [event pageUsageHash];
	unsigned int hashVal = (uint32_t)([event page] << 16 | [event usage]);
	if ([(BRControllerStack *)[self stack] peekController] != self) hashVal = 0;
	if (DEBUG_MODE) NSLog([NSString stringWithFormat:@"hashVal = %i",hashVal]);
	
	switch (hashVal)
	{
		case 65676:		// tap up
			if (DEBUG_MODE) NSLog(@"brEventAction: tap up");				
			break;
		case 65677:		// tap down
			if (DEBUG_MODE) NSLog(@"brEventAction: tap down");
			break;
		case 65675:		// tap left
			if (DEBUG_MODE) NSLog(@"brEventAction: tap left");
			break;
		case 65674:		// tap right
			if (DEBUG_MODE) NSLog(@"brEventAction: tap right");
			break;
		case 65670:		// tap menu
			if (DEBUG_MODE) NSLog(@"SystemAppliance: ApplicationAlertController - tap menu -- quitting app");
			if (DEBUG_MODE) NSLog(@"SystemAppliance: ApplicationAlertController - appRunning = %@", appRunning);

			if (appRunning) {
				[helper quitApplication];
				[helper showFrontRow];
			}
			[[self stack] popController];	
			
			return YES;
			break;
			
		case 65673:		// tap play
			if (DEBUG_MODE) NSLog(@"brEventAction: tap play -- returning to menu");			
			
			//[helper showFrontRow];
			[[self stack] popController];
			
			return YES;
			break;
	}
	return NO;
}

@end
