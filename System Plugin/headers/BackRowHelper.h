//
//  BackRowHelper.h
//  System
//
//  Created by ash on 04.03.09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>
#import <Foundation/Foundation.h>

@interface BackRowHelper : NSObject {
@private
	BOOL screenSaverWasEnabled;
	NSWorkspace *workspace;
	id oldFirstResponder;
	NSString *pidOfRunningApp;
}

+ (BackRowHelper *)sharedInstance;

- (BOOL)runApplicationWithIdentifier:(NSString *)appIdentifier withName:(NSString *)appName withPath:(NSString *)appPath;
- (NSString *)runScriptWithPathToScript:(NSString *)scriptPath WaitForScript:(BOOL) waitForScript;
- (BOOL)quitApplicationWithPID: (NSString *)pid;
- (BOOL)quitApplication;
- (void)hideFrontRowSetResponderTo:(id)responder;
- (void)showFrontRow;
- (BRImage *)getIconOfApplication:(NSString *)pathToApplication;
- (BRImage *)getIconOfFile:(NSString *)pathToFile;


@end
