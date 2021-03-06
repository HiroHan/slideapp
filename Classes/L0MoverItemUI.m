//
//  L0MoverItemUI.m
//  Mover
//
//  Created by ∞ on 15/05/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverItemUI.h"

#import "L0ImageItem.h"
#import "L0AddressBookPersonItem.h"
#import "L0MoverAppDelegate.h"

#import "MvrStorageCentral.h"

#import <MobileCoreServices/MobileCoreServices.h>

@interface L0MoverItemUI () <L0MoverItemUIAsynchronousMailDelegate>

@end


@implementation L0MoverItemUI

static NSMutableDictionary* L0ItemClassesToUIs = nil;

+ (void) registerUI:(L0MoverItemUI*) ui forItemClass:(Class) c;
{
	if (!L0ItemClassesToUIs)
		L0ItemClassesToUIs = [NSMutableDictionary new];
	
	[L0ItemClassesToUIs setObject:ui forKey:NSStringFromClass(c)];
}

+ (void) registerClass;
{
	id myself = [[self new] autorelease];
	
	for (Class c in [self supportedItemClasses])
		[self registerUI:myself forItemClass:c];
}

+ (L0MoverItemUI*) UIForItemClass:(Class) i;
{
	Class current = i; id ui;
	do {
		if (!current || [current isEqual:[L0MoverItem class]])
			return nil;
		
		ui = [L0ItemClassesToUIs objectForKey:NSStringFromClass(current)];
		current = [current superclass];
	} while (ui == nil);
	
	return ui;
}

+ (L0MoverItemUI*) UIForItem:(L0MoverItem*) i;
{
	return [self UIForItemClass:[i class]];
}

// Funnels
+ (NSArray*) supportedItemClasses;
{
	NSAssert(NO, @"You must override +supportedItemClasses and/or +registerClass in your implementation.");
	return nil;
}

- (L0MoverItemAction*) mainActionForItem:(L0MoverItem*) i;
{
	return nil;
}

- (NSArray*) additionalActionsForItem:(L0MoverItem*) i;
{
	return [NSArray array];
}

- (L0MoverItemAction*) showAction;
{
	return [L0MoverItemAction actionWithTarget:self selector:@selector(showOrOpenItem:forAction:) localizedLabel:NSLocalizedString(@"Show", @"Default label for the 'Show' action on items")];
}
- (L0MoverItemAction*) openAction;
{
	return [L0MoverItemAction actionWithTarget:self selector:@selector(showOrOpenItem:forAction:) localizedLabel:NSLocalizedString(@"Open", @"Default label for the 'Open' action on items")];
}

- (void) showOrOpenItem:(L0MoverItem*) i forAction:(L0MoverItemAction*) a;
{
	NSAssert(NO, @"You must override -showOrOpenItem:forAction: for this to work properly.");
}

- (L0MoverItemAction*) resaveAction;
{
	return [L0MoverItemAction actionWithTarget:self selector:@selector(resaveItem:forAction:) localizedLabel:NSLocalizedString(@"Save Again", @"Default label for the 'Save Again' action on items")];
}
// whose target is self and whose selector is:
- (void) resaveItem:(L0MoverItem*) i forAction:(L0MoverItemAction*) a;
{
	[i storeToAppropriateApplication];
}

- (L0MoverItemAction*) shareByEmailAction;
{
	L0MoverItemAction* a = [L0MoverItemAction actionWithTarget:self selector:@selector(shareItemByEmail:forAction:) localizedLabel:NSLocalizedString(@"Share by E-mail", @"Default label for the 'Share by E-mail' action on items")];
	a.hidden = ![MFMailComposeViewController canSendMail];
	return a;
}
// whose target is self and whose selector is:
- (void) shareItemByEmail:(L0MoverItem*) i forAction:(L0MoverItemAction*) a;
{
	if (self.preparesEmailAsynchronously) {
		[L0Mover beginShowingShieldViewWithText:NSLocalizedString(@"Preparing e-mail...", @"Label for shield view during asynchronous e-mail preparation")];
		[self performSelector:@selector(beginSendingItemViaEmail:) withObject:i afterDelay:0.1];
	} else {
		NSData* d = nil; NSString* t = nil, * f = nil;
		BOOL ok = [self fromItem:i getMailAttachmentData:&d mimeType:&t fileName:&f];
		NSAssert(ok, @"We need data, MIME type and filename before we can share an item by e-mail.");	
		[self finishedPreparingEmailWithData:d mimeType:t fileName:f];
	}
}

- (BOOL) preparesEmailAsynchronously;
{
	return NO;
}

- (void) beginSendingItemViaEmail:(L0MoverItem*) i;
{
	[self beginSendingItemViaEmail:i delegate:self];
}

- (void) beginSendingItemViaEmail:(L0MoverItem*) i delegate:(id <L0MoverItemUIAsynchronousMailDelegate>) delegate;
{	
	NSData* d = nil; NSString* t = nil, * f = nil;
	BOOL ok = [self fromItem:i getMailAttachmentData:&d mimeType:&t fileName:&f];
	NSAssert(ok, @"We need data, MIME type and filename before we can share an item by e-mail.");	
	[delegate finishedPreparingEmailWithData:d mimeType:t fileName:f];
}

- (BOOL) fromItem:(L0MoverItem*) i getMailAttachmentData:(NSData**) d mimeType:(NSString**) t fileName:(NSString**) f;
{
	BOOL allDone = YES;
	
	if (d) {
		NSData* externalRep = i.storage.data;
		if (!externalRep) allDone = NO;
		*d = externalRep;
	}
	
	NSString* type = i.type;
	
	if (t) {
		NSString* mime = [(id) UTTypeCopyPreferredTagWithClass((CFStringRef) type, kUTTagClassMIMEType) autorelease];
		if (!mime) allDone = NO;
		*t = mime;
	}
	
	if (f) {
		NSString* name = i.title;
		NSString* extension = [(id) UTTypeCopyPreferredTagWithClass((CFStringRef) type, kUTTagClassFilenameExtension) autorelease];
		if (name && extension) {
			name = [name stringByAppendingFormat:@".%@", extension];
			*f = name;
		} else
			allDone = NO;
	}
		
	return allDone;
}

- (void)mailComposeController:(MFMailComposeViewController *)controller didFinishWithResult:(MFMailComposeResult)result error:(NSError *)error;
{
	[controller dismissModalViewControllerAnimated:YES];
}

- (BOOL) removingFromTableIsSafeForItem:(L0MoverItem*) i;
{
	NSAssert(NO, @"You must override -removingFromTableIsSafeForItem:");
	return NO;
}

- (void) finishedPreparingEmailWithData:(NSData*) d mimeType:(NSString*) t fileName:(NSString*) f;
{
	[L0Mover endShowingShieldView];
	
	MFMailComposeViewController* mailVC = [[MFMailComposeViewController new] autorelease];
	mailVC.mailComposeDelegate = self;	
	[mailVC addAttachmentData:d mimeType:t fileName:f];
	
	// NSString* subject = [NSString stringWithFormat:NSLocalizedString(@"Shared by Mover: %@", @"Subject of 'Share by E-mail' new mails"), f];
	// [mailVC setSubject:subject];
	
	L0MoverAppDelegate* delegate = (L0MoverAppDelegate*) UIApp.delegate;
	[delegate presentModalViewController:mailVC];
}

@end
