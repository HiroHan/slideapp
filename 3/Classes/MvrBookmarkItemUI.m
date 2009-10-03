//
//  MvrBookmarkItemUI.m
//  Mover3
//
//  Created by ∞ on 03/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrBookmarkItemUI.h"
#import "MvrBookmarkItem.h"

#import "Network+Storage/MvrUTISupport.h"

@implementation MvrBookmarkItemUI

+ supportedItemClasses;
{
	return [NSSet setWithObject:[MvrBookmarkItem class]];
}

// + supportedItemSources;
// { the paste-from-clipboard source }

- (UIImage*) representingImageWithSize:(CGSize)size forItem:(id)i;
{
	return [UIImage imageNamed:@"BookmarkIcon.png"];
}

- (MvrItemAction*) mainActionForItem:(id)i;
{
	return [self openAction];
}

- (NSArray*) additionalActionsForItem:(id)i;
{
	return [NSArray arrayWithObject:[self clipboardAction]];
}

- (void) performShowOrOpenAction:(MvrItemAction*) a withItem:(MvrBookmarkItem*) item;
{
	[[UIApplication sharedApplication] openURL:item.address];
}

- (void) performCopyAction:(MvrItemAction *)copy withItem:(MvrBookmarkItem*)i;
{
	UIPasteboard* p = [UIPasteboard generalPasteboard];
	[p setValue:i.address forPasteboardType:(id) kUTTypeURL];
	[p setData:[[i.address absoluteString] dataUsingEncoding:NSUTF8StringEncoding] forPasteboardType:(id) kUTTypeUTF8PlainText];
}

- (NSString*) accessibilityLabelForItem:(MvrBookmarkItem*)i;
{
	return [NSString stringWithFormat:NSLocalizedString(@"Bookmark to %@", @"Template for bookmark accessibility label"), [i.address host]];
}

@end
