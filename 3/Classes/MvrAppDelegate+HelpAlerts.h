//
//  MvrAppDelegate+HelpAlerts.h
//  Mover3
//
//  Created by ∞ on 17/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MvrAppDelegate.h"

@interface MvrAppDelegate (MvrHelpAlerts)

- (void) suppressHelpAlerts;
- (void) resumeHelpAlerts;

@property(readonly) BOOL helpAlertsSuppressed;

- (void) showAlertIfNotShownBeforeNamed:(NSString*) name;
- (UIAlertView*) alertIfNotShownBeforeNamed:(NSString*) name;

- (void) showAlertIfNotShownBeforeNamedForiPhone:(NSString*) iPhoneName foriPodTouch:(NSString*) iPodTouchName;
- (UIAlertView*) alertIfNotShownBeforeNamedForiPhone:(NSString*) iPhoneName foriPodTouch:(NSString*) iPodTouchName;

@end
