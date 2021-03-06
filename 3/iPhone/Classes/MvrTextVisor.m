//
//  MvrTextVisor.m
//  Mover3
//
//  Created by ∞ on 03/10/09.
//  Copyright 2009 Infinite Labs (Emanuele Vulcano). All rights reserved.
//

#import "MvrTextVisor.h"


@implementation MvrTextVisor

- (id) initWithItem:(MvrItem*) i;
{
	self = [super initWithItem:i];
	if (self != nil) {
		self.title = i.title;
	}
	return self;
}


- (void) dealloc
{
	[self viewDidUnload];
	[super dealloc];
}


- (void) viewDidLoad;
{
	[super viewDidLoad];
	textView.text = [self.item text];
}

- (void) viewDidUnload;
{
	[textView release]; textView = nil;
}

- (void) viewWillAppear:(BOOL) ani;
{
	[super viewWillAppear:ani];
	
	CGFloat topInset = 0;
	if (self.navigationController && self.navigationController.navigationBar.barStyle == UIBarStyleBlackTranslucent)
		topInset += self.navigationController.navigationBar.bounds.size.height;
	
	textView.contentInset = UIEdgeInsetsMake(topInset, 0, 0, 0);
	textView.scrollIndicatorInsets = textView.contentInset;
	textView.contentOffset = CGPointMake(0, -topInset);
}

@end
