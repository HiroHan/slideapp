//
//  L0SlideAboutPane.h
//  Slide
//
//  Created by ∞ on 11/04/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>

@class L0SlideAboutCopyrightWebPane;

@interface L0MoverAboutPane : UIViewController {
	IBOutlet UILabel* versionLabel;
	IBOutlet L0SlideAboutCopyrightWebPane* copyrightPane;
	
	id target;
	SEL selector;
	
	IBOutlet UIToolbar* toolbar;
}

@property(assign) IBOutlet UILabel* versionLabel;
@property(assign) IBOutlet UIToolbar* toolbar;
@property(retain) L0SlideAboutCopyrightWebPane* copyrightPane;

- (IBAction) showAboutCopyrightWebPane;
- (IBAction) openInfiniteLabsDotNet;
- (IBAction) emailAFriend;

- (IBAction) showBookmarksAccountPane;

- (IBAction) dismiss;
- (void) setDismissButtonTarget:(id) target selector:(SEL) selector;

@end

@interface L0SlideAboutCopyrightWebPane : UIViewController <UIWebViewDelegate> {
	UIWebView* webView;
}

@property(retain) UIWebView* webView;

@end
