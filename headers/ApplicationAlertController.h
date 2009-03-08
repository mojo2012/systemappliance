//
//  ApplicationAlertController.m
//  SystemPlugin 0.1
//
//  Created by ash 2009.
//

#import <Foundation/Foundation.h>
#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>
#import <BackRowHelper.h>


@interface ApplicationAlertController : BRAlertController
{
	int padding[16];
	NSString *identifier;
	NSString *name;
	NSString *path;
	
	BOOL appRunning;
	BackRowHelper *helper;
	NSWorkspace *workspace;
}


- (BOOL)runApplicationWithIdentifier:(NSString *)appIdentifier withName:(NSString *)appName withPath:(NSString *)appPath;
- (BOOL)runScriptWithIdentifier:(NSString *)scriptIdentifier withName:(NSString *)scriptName withPath:(NSString *)scriptPath;

@end
