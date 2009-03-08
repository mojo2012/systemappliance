//
//  BackRowHelper.m
//  System
//
//  Created by ash on 04.03.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "BackRowHelper.h"

#ifndef DEBUG
#define DEBUG_MODE true
#else
#define DEBUG_MODE false
#endif

@implementation BackRowHelper

+ (BackRowHelper *)sharedInstance {
	static BackRowHelper *sharedInstance = nil;
	
	if (sharedInstance == nil) {
		sharedInstance = [[BackRowHelper alloc] init];
	}
	
	return sharedInstance;
}

- (id)init
{
	if (DEBUG_MODE) NSLog(@"SystemAppliance: BackRowHelper - init");
	workspace = [NSWorkspace sharedWorkspace];
	
	return [super init];
}

- (void)dealloc
{
	if (DEBUG_MODE) NSLog(@"SystemAppliance: BackRowHelper - dealloc");

	[workspace release];
	[pidOfRunningApp release];
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];  
}


- (BOOL)runApplicationWithIdentifier:(NSString *)appIdentifier withName:(NSString *)appName withPath:(NSString *)appPath {
	NSString *pathToApp = [appPath stringByAppendingPathComponent:appName];
	
	// Open the application using LaunchServices
	if (DEBUG_MODE) NSLog(@"SystemAppliance: BackRowHelper - Opening %@", pathToApp);
	BOOL appRunning = [workspace launchApplication:pathToApp];
	
	if (!appRunning) {
		return NO;
	}
	
	NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 2.0];
	[NSThread sleepUntilDate:future];
	
	//get PID
	NSArray *apps = [workspace launchedApplications];
	//NSLog(@"SystemAppliance: itemSelected - runnings apps: %@", apps);
	
	int i;
	for (i=0; i<[apps count]; i++)
	{
		//NSLog(@"SystemAppliance: itemSelected - current nsworkspace path= %@", [[apps objectAtIndex:i] valueForKey:@"NSApplicationPath"]);
		//NSLog(@"SystemAppliance: itemSelected - current nsworkspace path= %@", pathToApp);
		
		if ([[[apps objectAtIndex:i] valueForKey:@"NSApplicationPath"] isEqualToString: pathToApp]) {
			pidOfRunningApp = [[apps objectAtIndex:i] valueForKey:@"NSApplicationProcessIdentifier"];
			if (DEBUG_MODE) NSLog(@"SystemAppliance: BackRowHelper - PID of launched app %@", pidOfRunningApp);
		}
	}
	
	return appRunning;
}

- (BOOL)quitApplicationWithIdentifier:withName:(NSString *)appName withPath:(NSString *)appPath {
	NSString *pathToApp = [appPath stringByAppendingString:appName];
	
	//get PID
	NSArray *apps = [workspace launchedApplications];
	//NSLog(@"SystemAppliance: itemSelected - runnings apps: %@", apps);
	
	int i;
	for (i=0; i<[apps count]; i++)
	{
		//NSLog(@"SystemAppliance: itemSelected - current nsworkspace path= %@", [[apps objectAtIndex:i] valueForKey:@"NSApplicationPath"]);
		//NSLog(@"SystemAppliance: itemSelected - current nsworkspace path= %@", pathToApp);
		
		if ([[[apps objectAtIndex:i] valueForKey:@"NSApplicationPath"] isEqualToString: pathToApp]) {
			pidOfRunningApp = [[apps objectAtIndex:i] valueForKey:@"NSApplicationProcessIdentifier"];
			if (DEBUG_MODE) NSLog(@"SystemAppliance: PID of app to quit %@", pidOfRunningApp);
			[self quitApplicationWithPID: pidOfRunningApp];
			return YES;
		}
	}
	
	return NO;
}

- (BRImage *)getIconOfApplication:(NSString *)pathToApplication {
	//Extract the filename to the app icon of a specific application
	NSBundle *appBundle = [NSBundle bundleWithPath:pathToApplication];
	NSDictionary *appInfo = [appBundle infoDictionary];
	NSString *appIconName = [appInfo valueForKey:@"CFBundleIconFile"];
	
	//if (DEBUG_MODE) NSLog(@"SystemAppliance: previewControlForItem - info.pslist =%@", appInfo);
	
	if (!NSEqualRanges(NSMakeRange(NSNotFound, 0), [appIconName rangeOfString:@".icns"])) {
		appIconName = [appIconName substringToIndex:[appIconName length] - [@".icns" length]];
	}
	
	if (DEBUG_MODE) NSLog(@"BackRowHelper: getIconOfApplication - icon=%@", appIconName);
	NSString *appIconPath = [appBundle pathForResource:appIconName ofType:@"icns"];
	
	//sometimes the icon can't be found, then we use NSWorkspace to get the app icon
	//disadvantage: lower icon quality because of the converting process
	if (appIconPath == nil) {
		//get the app icon with NSWorkspace and conert to CIImage
		if (DEBUG_MODE) NSLog(@"BackRowHelper: getIconOfApplication - no icon in resource folder found.");
		return [self getIconOfFile: pathToApplication];
	} else {
		//if (DEBUG_MODE) NSLog(@"BackRowHelper: getIconOfApplication - returned app icon=%@", appIconPath);
		
		return [BRImage imageWithPath: appIconPath];
	}
	
	return nil;
}

- (BRImage *)getIconOfFile:(NSString *)pathToFile {
	//get the app icon with NSWorkspace and conert to CIImage
	NSImage *icon  = [workspace iconForFile:pathToFile];
	NSData  *tiffData = [icon TIFFRepresentation];
	NSBitmapImageRep * bitmap = [NSBitmapImageRep imageRepWithData:tiffData];
	CIImage *ciImage = [[CIImage alloc] initWithBitmapImageRep:bitmap];
		
	return [BRImage imageWithCIImage:ciImage];
}

- (NSString *)runScriptWithPathToScript:(NSString *)scriptPath WaitForScript:(BOOL) waitForScript {
	if (DEBUG_MODE) NSLog(@"BackRowHelper: path to script %@ (%i).", scriptPath, waitForScript);
	
	if (!waitForScript) {
		[NSTask launchedTaskWithLaunchPath:@"/bin/bash/" arguments:[NSArray arrayWithObject:scriptPath]];
		return @"";
	} else {
		NSTask *task = [[NSTask alloc] init];
		NSArray *args = [NSArray arrayWithObjects:scriptPath,nil];
		
		[task setArguments:args];
		[task setLaunchPath:@"/bin/bash"];
		NSPipe *outPipe = [[NSPipe alloc] init];
		
		[task setStandardOutput:outPipe];
		[task setStandardError:outPipe];
		NSFileHandle *file;
		file = [outPipe fileHandleForReading];
		
		[task launch];
		NSData *data;
		data = [ file readDataToEndOfFile];
		NSString *string = [[NSString alloc] initWithData: data encoding: NSUTF8StringEncoding];
		return string;
	}
		
	return @"";
}

- (BOOL)quitApplicationWithPID: (NSString *)pid {
	if (DEBUG_MODE) NSLog(@"SystemAppliance: quitApplicationWithPID - PID of app to kill %@", [NSString stringWithFormat:@"%@", pid]);
	
	if (pid != 0)
	{
		[NSTask launchedTaskWithLaunchPath:@"/bin/kill" arguments: [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@", pid], nil]];
	}
	
	return NO;
}

- (BOOL)quitApplication {
	if (DEBUG_MODE) NSLog(@"SystemAppliance: quitApplication - PID of app to kill %@", [NSString stringWithFormat:@"%@", pidOfRunningApp]);
	
	if (pidOfRunningApp != 0)
	{
		[NSTask launchedTaskWithLaunchPath:@"/bin/kill" arguments: [NSArray arrayWithObjects:[NSString stringWithFormat:@"%@", pidOfRunningApp], nil]];
	}
	
	return NO;
}


- (void)hideFrontRowSetResponderTo:(id)responder {
	if (DEBUG_MODE) NSLog(@"SystemAppliance: BackRowHelper - hideFrontRow");
	
	@try
	{
		screenSaverWasEnabled = [[BRSettingsFacade sharedInstance] screenSaverEnabled];
		[[BRSettingsFacade sharedInstance] setScreenSaverEnabled:false];
		
		if (DEBUG_MODE) NSLog(@"hideFrontRow : BRDisplayManagerDisplayOffline");
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerDisplayOffline"
															object:[BRDisplayManager sharedInstance]];
		
		if (DEBUG_MODE) NSLog(@"hideFrontRow : BRDisplayManagerStopRenderingNotification");
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerStopRenderingNotification"
															object:[BRDisplayManager sharedInstance]];
		
		CGDisplayErr theErr = kCGErrorNoneAvailable;
		int attempts=1;
		while (theErr != kCGErrorSuccess && attempts<=5)
		{
			if (DEBUG_MODE) NSLog(@"hideFrontRow : CGReleaseAllDisplays");
			theErr = CGReleaseAllDisplays();
			
			attempts++;
			if (theErr != kCGErrorSuccess)
			{
				NSLog(@"hideFrontRow : CGDisplayErr = %i",theErr);
				NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.1];
				[NSThread sleepUntilDate:future];
			}
		}
		
		// The pre-AppleTV 2.3 Way...
		//if (DEBUG_MODE) NSLog(@"hideFrontRow : _displayGoneOffline");
		//[display _displayGoneOffline:displayid];
		//if (DEBUG_MODE) NSLog(@"hideFrontRow : releaseAllDisplays");
		//[display releaseAllDisplays];
	}
	@catch (NSException *theErr)
	{
		NSLog(@"hideFrontRow : exception thrown...\n  name: %@ \n  reason: %@", [theErr name], [theErr reason]);
	}
	
	// Hack to send remote events to brEventAction of this BRAlertController, even when display is offline
	BREventManager *eventManager = [BREventManager sharedManager];
	oldFirstResponder = [eventManager firstResponder];
	[eventManager setFirstResponder:responder];
}

- (void)showFrontRow {
	if (DEBUG_MODE) NSLog(@"SystemAppliance: BackRowHelper - showFrontRow");
	
	// Hack to return sending remote events to BRBaseAppliance when we're done
	BREventManager *eventManager = [BREventManager sharedManager];
	[eventManager setFirstResponder:oldFirstResponder];
	
	@try
	{
		[[BRSettingsFacade sharedInstance] setScreenSaverEnabled:screenSaverWasEnabled];
		
		if (DEBUG_MODE) NSLog(@"showFrontRow : BRDisplayManagerResumeRenderingNotification");
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerResumeRenderingNotification"
															object:[BRDisplayManager sharedInstance]];
		
		if (DEBUG_MODE) NSLog(@"hideFrontRow : BRDisplayManagerDisplayOnline");
		[[NSNotificationCenter defaultCenter] postNotificationName:@"BRDisplayManagerDisplayOnline"
															object:[BRDisplayManager sharedInstance]];
		
		/*
		 CGDisplayErr theErr = kCGErrorNoneAvailable;
		 int attempts=1;
		 while (theErr != kCGErrorSuccess && attempts<=5)
		 {
		 if (DEBUG_MODE) NSLog(@"showFrontRow : CGCaptureAllDisplays");
		 theErr = CGCaptureAllDisplays();
		 
		 attempts++;
		 if (theErr != kCGErrorSuccess)
		 {
		 NSLog(@"showFrontRow : CGDisplayErr = %i",theErr);
		 NSDate *future = [NSDate dateWithTimeIntervalSinceNow: 0.1];
		 [NSThread sleepUntilDate:future];
		 }
		 }
		 */
		
		// The pre-AppleTV 2.3 Way...
		//if (DEBUG_MODE) NSLog(@"showFrontRow : _displayGoneOnline");
		//[display _displayGoneOnline:displayid];
		//if (DEBUG_MODE) NSLog(@"showFrontRow : captureAllDisplays");
		//[display captureAllDisplays];
	}
	@catch (NSException *theErr)
	{
		NSLog (@"showFrontRow : exception thrown...\n  name: %@ \n  reason: %@", [theErr name], [theErr reason]);
	}
}

@end
