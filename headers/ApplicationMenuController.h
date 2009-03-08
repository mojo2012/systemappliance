//
//  ApplicationMenuController.m
//  SystemPlugin 0.1
//
//  Created by ash 2009.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>
#import <BackRowHelper.h>

@interface ApplicationMenuController : BRMediaMenuController
{
	int padding[16];	// credit is due here to SapphireCompatibilityClasses!!

	NSString *identifier;
	NSString *name;
	NSString *pathToAppFolder;
	NSString *showExtensions;
	NSString *pathToApp;
	NSString *selectedFilename;
	NSString *pidOfRunningApp;
	
	BOOL appRunning;
	BOOL screenSaverWasEnabled;

	NSWorkspace *workspace;
	BackRowHelper *helper;

	// Data source variables:
	NSMutableArray *_items;
	NSMutableArray *_fileListArray;
}

- (id)initWithIdentifier:(NSString *)initId withPath:(NSString *)initPath withShowExtensions:(BOOL *)initShowExtensions;
- (id)previewControlForItem:(long)fp8;

// Data source methods:
- (float)heightForRow:(long)row;
- (BOOL)rowSelectable:(long)row;
- (long)itemCount;
- (id)itemForRow:(long)row;
- (long)rowForTitle:(id)title;
- (id)titleForRow:(long)row;
- (long)getSelection;

@end
