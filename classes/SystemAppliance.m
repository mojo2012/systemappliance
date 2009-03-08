//
//  SystemAppliance.m
//  SystemPlugin 0.1
//
//  Created by ash 2009.
//

#import "SystemAppliance.h"

#ifndef DEBUG
#define DEBUG_MODE true
#else
#define DEBUG_MODE false
#endif

@implementation SystemAppliance

// Override to allow FrontRow to load custom appliance plugins
+ (NSString *)className
{
    // this function creates an NSString from the contents of the
    // struct objc_class, which means using this will not call this
    // function recursively, and it'll also return the *real* class
    // name.
    NSString * className = NSStringFromClass( self );
	
	// new method based on the BackRow NSException subclass, which conveniently provides us a backtrace
	// method!
	NSRange result = [[BRBacktracingException backtrace] rangeOfString:@"(in BackRow)"];
	
	if(result.location != NSNotFound) {
		if (DEBUG_MODE) NSLog(@"+[%@ className] called for whitelist check.", className);
		className = @"RUIDVDAppliance";
	} 
	
	// Set defaults for at.ash.SystemAppliance.plist
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	if (! [defaults persistentDomainForName:@"at.ash.SystemAppliance"])
	{
		if (DEBUG_MODE) NSLog(@"SystemAppliance: is creating at.ash.SystemAppliance.plist from defaults");
		
		// This will create a binary plist file
		// NSString *defaultPlist = [[NSBundle bundleForClass:[self class]] pathForResource:@"defaults" ofType:@"plist"];
		// NSDictionary *defaultDictionary = [NSDictionary dictionaryWithContentsOfFile:defaultPlist];
		// [defaults setPersistentDomain:defaultDictionary forName:@"at.ash.SystemAppliance"];
		
		// This will create a xml plist file (more user friendly)
		NSFileManager *fileManager = [NSFileManager defaultManager];
		NSString *source = [[NSBundle bundleForClass:[self class]] pathForResource:@"defaults" ofType:@"plist"];
		NSString *destination = [@"~/Library/Preferences/at.ash.SystemAppliance.plist" stringByExpandingTildeInPath];
		[fileManager copyPath:source toPath:destination handler:nil];
	}
	else
	{
		if (DEBUG_MODE) NSLog(@"SystemAppliance: has found at.ash.SystemAppliance.plist");
	}
	
	return className;
}

+ (NSString *)rootMenuLabel
{
	return ( @"System" );
}

- (id)controllerForIdentifier:(id)identifier {
	id categoryInfos = [self getPrefsForCategoryIdentifier:identifier];

	NSBundle *appBundle = [NSBundle bundleForClass:[self class]];
	
	if ([identifier isEqualToString:@"Applications"]) {
		if (DEBUG_MODE) NSLog(@"SystemAppliance: Applications category selected");
		if (DEBUG_MODE) NSLog(@"SystemAppliance: path=%@", [categoryInfos valueForKey:@"path"]);
		
		ApplicationMenuController *appMenu = [[ApplicationMenuController alloc] init];
		
		//NSString *pathToExeceutableIcon = [[NSBundle bundleForClass:[self class]]  pathForResource:@"ExecutableBinaryIcon" ofType:@"png"];
		//BRImage *applianceIcon = [[BRImage imageWithPath:pathToExeceutableIcon] retain];
		
		//[appMenu setApplianceIcon:[CIImage imaimageNamed:@"ExecutableBinaryIcon.png"]];
		//default NO
		[appMenu initWithIdentifier:identifier withPath:[categoryInfos valueForKey:@"path"] withShowExtensions:NO];
		
		return appMenu;
	} else if ([identifier isEqualToString:@"Scripts"]) {
		if (DEBUG_MODE) NSLog(@"SystemAppliance: Scripts category selected");
		
		// Get path from at.ash.SystemAppliance.plist
		NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
		NSDictionary *defaultDictionary = [defaults persistentDomainForName:@"at.ash.SystemAppliance"];
		NSMutableArray *scriptArray = [defaultDictionary objectForKey:@"Scripts"];
		
		//if (DEBUG_MODE) NSLog(@"SystemAppliance: scripts array = %@", scriptArray);
		
		ScriptMenuController *scriptMenu = [[ScriptMenuController alloc] init];
		[scriptMenu initWithIdentifier:identifier withPath:[categoryInfos valueForKey:@"path"] withScripts: scriptArray];	
		return scriptMenu;
	} else if ([identifier isEqualToString:@"Shutdown"]) {
		BRAlertController *alert = [BRAlertController alertOfType:0
														   titled:@"Shutting down AppleTV ..."
													  primaryText:[NSString stringWithFormat:@"Unplug your AppleTV when the screen goes black!"]
													secondaryText:@"You don't have to do this.\n But it is safer if you copied over something before."];
		
		if (DEBUG_MODE) NSLog(@"SystemAppliance: shutting down now ...");
		
		NSString *pathToShellScript = [appBundle pathForResource:identifier ofType:@"sh"];
		
		[NSTask launchedTaskWithLaunchPath:@"/bin/bash/" arguments:[NSArray arrayWithObject:pathToShellScript]];
		
		return alert;
	} else if ([identifier isEqualToString:@"Reboot"]) {
		BRAlertController *alert = [BRAlertController alertOfType:0
														   titled:@"Rebooting AppleTV ..."
													  primaryText:[NSString stringWithFormat:@""]
													secondaryText:@""];
	
		if (DEBUG_MODE) NSLog(@"SystemAppliance: reboot now ...");
		
		NSString *pathToShellScript = [appBundle pathForResource:identifier ofType:@"sh"];
		
		[NSTask launchedTaskWithLaunchPath:@"/bin/bash/" arguments:[NSArray arrayWithObject:pathToShellScript]];
		
		return alert;
	} else if ([identifier isEqualToString:@"RestartFinder"]) {
		if (DEBUG_MODE) NSLog(@"SystemAppliance: restarting Finder ...");
		
		NSString *pathToShellScript = [appBundle pathForResource:identifier ofType:@"sh"];
		[NSTask launchedTaskWithLaunchPath:@"/bin/bash/" arguments:[NSArray arrayWithObject:pathToShellScript]];
		 
		return nil;
	}
		
	return nil;
}

- (id)getPrefsForCategoryIdentifier:(id)identifier {
	// Get path from at.ash.SystemAppliance.plist
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultDictionary = [defaults persistentDomainForName:@"at.ash.SystemAppliance"];
	NSArray *categoryArray = [defaultDictionary objectForKey:@"FRApplianceCategoryDescriptors"];
	NSEnumerator *enumerator = [categoryArray objectEnumerator];
	
	//if (DEBUG_MODE) NSLog(@"SystemAppliance: selected category=%@", categoryArray);
	
	id obj;
	while((obj = [enumerator nextObject]) != nil) {
		if ([identifier isEqualToString:[obj valueForKey:@"identifier"]]) {
			//name = [obj valueForKey:@"name"];
			//path = [obj valueForKey:@"path"];
			//preferredOrder = [obj valueForKey:@"preferred-order"];

			//if (DEBUG_MODE) NSLog(@"SystemAppliance: name=%@", name);
			//if (DEBUG_MODE) NSLog(@"SystemAppliance: path=%@", path);
			//if (DEBUG_MODE) NSLog(@"SystemAppliance: preferedOrder=%@", preferredOrder);
			//if (DEBUG_MODE) NSLog(@"SystemAppliance: settings for selected category=%@", obj);
			
			return obj;
		}
	}
	
	return nil;
}

// Populate appliance categories from at.ash.SystemAppliance.plist
- (id)applianceCategories
{	
	NSMutableArray *categories = [NSMutableArray array];

	//Read plist and get all the categories
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	NSDictionary *defaultDictionary = [defaults persistentDomainForName:@"at.ash.SystemAppliance"];
	NSArray *categoryArray = [defaultDictionary objectForKey:@"FRApplianceCategoryDescriptors"];
	NSEnumerator *catEnumerator = [categoryArray objectEnumerator];
	
	//NSBundle *bundle = [NSBundle bundleForClass: [self class]];
	
	//iterate over all categories and ...
	id tmpCat;
	while((tmpCat = [catEnumerator nextObject]) != nil) 
	{
		BRApplianceCategory *category = [BRApplianceCategory categoryWithName:[BRLocalizedStringManager appliance:self
										localizedStringForKey:[tmpCat valueForKey:@"identifier"] inFile: @"InfoPlist"] 
										identifier:[tmpCat valueForKey:@"identifier"] 
										preferredOrder:[[tmpCat valueForKey:@"preferred-order"] floatValue]];

		//if (DEBUG_MODE) NSLog(@"SystemAppliance: Adding category=%@",[tmpCat valueForKey:@"name"]);
		
		//... add them to the array ...
		[categories addObject:category];
	}
	//... that will be return to frontrow

	return categories;
}

- (id)identifierForContentAlias:(id)fp8
{
	return @"System";
}

- (id)applianceInfo
{
	return [BRApplianceInfo infoForApplianceBundle:[NSBundle bundleForClass:[self class]]];
}

@end
