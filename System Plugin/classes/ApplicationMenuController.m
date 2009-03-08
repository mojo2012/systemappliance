//
//  ApplicationMenuController.m
//  SystemPlugin 0.1
//
//  Created by ash 2009.
//

#import "ApplicationMenuController.h"

#ifndef DEBUG
#define DEBUG_MODE true
#else
#define DEBUG_MODE false
#endif

@implementation ApplicationMenuController

- (id)init
{
	if (DEBUG_MODE) NSLog(@"SystemAppliance: ApplicationMenuController - init");
	
	//initialize all the needed variables
	workspace = [NSWorkspace sharedWorkspace];
	pathToAppFolder = [[NSString alloc] init];
	pathToApp = [[NSString alloc] init];
	selectedFilename = [[NSString alloc] init];
	helper = [BackRowHelper sharedInstance];
	
	return [super init];
}

- (void)dealloc
{
	if (DEBUG_MODE) NSLog(@"SystemAppliance: ApplicationMenuController - dealloc");
	[helper showFrontRow];
	[workspace release];
	[identifier release];
	[name release];
	[pathToAppFolder release];
	[pathToApp release];
	[showExtensions release];
	[selectedFilename release];
	[pidOfRunningApp release];
	[_items release];
	[_fileListArray release];
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

//load all .app files and add it to the listing
- (id)initWithIdentifier:(NSString *)initId withPath:(NSString *)initPath withShowExtensions:(BOOL *)initShowExtensions
{
	if (DEBUG_MODE) NSLog(@"SystemAppliance: ApplicationMenuController - initWithIdentifier:%@ withPath:%@ initShowExtensions%@",
						  initId, initPath, initShowExtensions);

	[self addLabel:@"at.ash.SystemAppliance.ApplicationMenuController"];
	[self setListTitle:[BRLocalizedStringManager appliance: self
									 localizedStringForKey: initId
													inFile: @"InfoPlist"]];
	
	identifier = initId;
	pathToAppFolder = initPath;
	appRunning = NO;
	

	_items = [[NSMutableArray alloc] initWithObjects:nil];
	_fileListArray = [[NSMutableArray alloc] initWithObjects:nil];
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	long i, count = [[fileManager directoryContentsAtPath:pathToAppFolder] count];	
	for ( i = 0; i < count; i++ )
	{
		//TODO: check if fileName = folder
		//allow to recursivly open folders
		
		NSString *fileName = [[fileManager directoryContentsAtPath: pathToAppFolder] objectAtIndex:i];
		
		if (! [fileName hasPrefix:@"."] & [fileName hasSuffix:@"app"]) {
			[_fileListArray addObject:fileName];
			
			int length = [fileName length] - [@".app" length];
			fileName = [fileName substringToIndex:length];

			id item = [[BRTextMenuItemLayer alloc] init];
			[item setTitle: fileName];
			[_items addObject:item];
		} else {
			continue;
		}
	}
	
	id list = [self list];
	[list setDatasource: self];
	
	return self;
}

- (long)defaultIndex
{
	return 0;
}

- (void)itemSelected:(long)fp8
{
	if (DEBUG_MODE) NSLog([NSString stringWithFormat:@"SystemAppliance: ApplicationMenuController - itemSelected, row=%i",fp8]);

	if (! appRunning) {
		selectedFilename = [_fileListArray objectAtIndex:fp8];
		pathToApp = [pathToAppFolder stringByAppendingPathComponent: selectedFilename];

		appRunning = [helper runApplicationWithIdentifier:identifier withName:selectedFilename withPath:pathToAppFolder];
		
		if (DEBUG_MODE) NSLog([NSString stringWithFormat:@"SystemAppliance: ApplicationMenuController - path = %@", pathToApp]);

		if (!appRunning) {
			BRAlertController * alert = [[BRAlertController alloc] init];
			[alert initWithType:1 titled:@"Error" primaryText:selectedFilename secondaryText:@"Could not launche app!"];
			[[self stack] pushController:alert];
		} else {
			[helper hideFrontRowSetResponderTo:self];
		}
	}
	else
	{
		appRunning = NO;
	}
}

- (id)previewControlForItem:(long)fp8
{
	selectedFilename = [_fileListArray objectAtIndex:fp8];
	pathToApp = [pathToAppFolder stringByAppendingPathComponent: selectedFilename];
	BRImageAndSyncingPreviewController *imageControl = [[BRImageAndSyncingPreviewController alloc] init];	
	BRImage *icon = [helper getIconOfApplication:pathToApp];
	
	//BRMetadataPreviewControl *previewControl = [[BRMetadataPreviewControl alloc] init];	
//	BRMetadataControl *metadata = [[BRMetadataControl alloc] init];
//	[metadata setTitle:@"aaa"];
//	[previewControl setMetadataProvider:metadata];
//
//	return previewControl;
	
	[imageControl setImage:icon];
	
	return imageControl;
}

- (BOOL)brEventAction:(BREvent *)event
{
	if (appRunning)
	{
		unsigned int hashVal = (uint32_t)([event page] << 16 | [event usage]);
		if ([(BRControllerStack *)[self stack] peekController] != self) hashVal = 0;
		if (DEBUG_MODE) NSLog([NSString stringWithFormat:@"hashVal = %i",hashVal]);
		
		switch (hashVal)
		{
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
				if (DEBUG_MODE) NSLog(@"SystemAppliance: ApplicationMenuController - x3(menu) - quiting %@", selectedFilename);
				
				if (appRunning) {
					appRunning = NO;
					[helper quitApplication];
					[helper showFrontRow];
				} else {
					[[self stack] popController];
				}
				
				return YES;
				break;
				
			case 65673:		// tap play
				if (DEBUG_MODE) NSLog(@"SystemAppliance: brEventAction (play/pause) - restaring %@", selectedFilename);			
				break;
		}
		return NO;
	}
	else
	{
		return [super brEventAction:event];
	}
}

// Data source methods:
- (float)heightForRow:(long)row		{ return 0.0f; }
- (BOOL)rowSelectable:(long)row		{ return YES;}
- (long)itemCount					{ return (long)[_items count];}
- (id)itemForRow:(long)row			{ return [_items objectAtIndex:row]; }
- (long)rowForTitle:(id)title		{ return (long)[_items indexOfObject:title]; }
- (id)titleForRow:(long)row			{ return [[_items objectAtIndex:row] title]; }


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
