//
//  ScriptMenuController.h
//  System
//
//  Created by ash on 01.03.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>
#import "BackRowHelper.h"

@interface ScriptMenuController : BRMediaMenuController
{
	int padding[16];	// credit is due here to SapphireCompatibilityClasses!!
	
	NSString *identifier;
	NSMutableArray *allScripts;
	NSString *pathToScriptFolder;
	NSString *selectedScript;

	BOOL screenSaverWasEnabled;
	BOOL scriptRunning;
	
	NSWorkspace *workspace;
	BackRowHelper *helper;
	
	BRImage *scriptFileImage;
	
	// Data source variables:
	NSMutableArray *menuItems;
}

- (id)initWithIdentifier:(NSString *) initId withPath: (NSString *)path withScripts:(NSMutableArray *)scripts;
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
