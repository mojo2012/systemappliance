//
//  SystemAppliance.h
//  SystemPlugin 0.1
//
//  Created by ash 2009.
//

#import <Cocoa/Cocoa.h>
#import <BackRow/BackRow.h>
#import "ApplicationMenuController.h"
#import "ApplicationAlertController.h"
#import "ScriptMenuController.h"
#include <CoreServices/CoreServices.h>
#include <Carbon/Carbon.h>


@interface SystemAppliance : BRBaseAppliance
{
}

- (id)getPrefsForCategoryIdentifier:(id)identifier;

@end
