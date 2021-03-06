//
//  MvrDevice.m
//  MoverWaypoint
//
//  Created by ∞ on 26/02/10.
//  Copyright 2010 Apple Inc. All rights reserved.
//

#import "MvrDevice.h"

#import "Network+Storage/MvrItem.h"
#import "Network+Storage/MvrGenericItem.h"
#import "Network+Storage/MvrItemStorage.h"
#import "Network+Storage/MvrIncoming.h"
#import "Network+Storage/MvrOutgoing.h"

#import <QuartzCore/QuartzCore.h>

static NSArray* MvrTypeForExtension(NSString* ext) {
	if ([ext isEqual:@"m4v"])
		return [NSArray arrayWithObject:(id) kUTTypeMPEG4];
	
	return NSMakeCollectable(UTTypeCreateAllIdentifiersForTag(kUTTagClassFilenameExtension, (CFStringRef) ext, NULL));
}

@implementation MvrDevicesCollectionView

- (NSCollectionViewItem*) newItemForRepresentedObject:(id) object;
{
	return [[MvrDeviceItem alloc] initWithChannel:(id <MvrChannel>) object];
}

@end



@interface MvrDeviceItem ()

- (void) animateMiniSlide;

@end


@implementation MvrDeviceItem

- (id) initWithChannel:(id <MvrChannel>) chan;
{
	if ([NSCollectionViewItem instancesRespondToSelector:@selector(initWithNibName:bundle:)])
		self = [super initWithNibName:@"MvrDeviceItem" bundle:nil];
	else {
		self = [super init];
		[NSBundle loadNibNamed:@"MvrDeviceItem" owner:self];
	}
	
	if (self) {
		[(id)chan addObserver:self forKeyPath:@"incomingTransfers" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
		[(id)chan addObserver:self forKeyPath:@"outgoingTransfers" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:NULL];
		self.channel = chan;
	}
		
	return self;
}

- (void) observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context;
{
	NSLog(@"%@.%@ changed: %@", object, keyPath, change);
	
	NSInteger incoming = [self.channel.incomingTransfers count];
	NSInteger outgoing = [self.channel.incomingTransfers count];
	
	for (id i in [change objectForKey:NSKeyValueChangeNewKey]) {
		if ([i conformsToProtocol:@protocol(MvrIncoming)])
			incoming++;
		else if ([i conformsToProtocol:@protocol(MvrOutgoing)])
			outgoing++;
	}
	
	if (incoming != 0 || outgoing != 0) {
		[spinnerView setHidden:NO];
		[spinner startAnimation:self];
	} else {
		[spinnerView setHidden:YES];
		[spinner stopAnimation:self];
	}	
}

- (void) awakeFromNib;
{
	[self.view setFrame:NSMakeRect(0, 0, 155, 140)];
	[spinner stopAnimation:self];
	[spinnerView setHidden:YES];
}

- (void) sendItemFile:(NSString*) file;
{
	NSString* title = [[NSFileManager defaultManager] displayNameAtPath:file];
	
	NSString* ext = [file pathExtension];
	NSArray* types = MvrTypeForExtension(ext);
	
	NSString* filename = [file lastPathComponent];
	NSDictionary* md = [NSDictionary dictionaryWithObjectsAndKeys:
						title, kMvrItemTitleMetadataKey,
						filename, kMvrItemOriginalFilenameMetadataKey,
						nil];
	
	MvrItemStorage* is = [MvrItemStorage itemStorageFromFileAtPath:file options:kMvrItemStorageDoNotTakeOwnershipOfFile error:NULL];
	if (is && [types count] > 0) {
		MvrGenericItem* item = [[MvrGenericItem alloc] initWithStorage:is type:[types objectAtIndex:0] metadata:md];
		[self.channel beginSendingItem:item];
	}
	
	[self animateMiniSlide];
}

@synthesize channel;
@dynamic view;


#pragma mark Animation

- (void) animateMiniSlide;
{
	NSImageView* iv = [[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 32, 32)];
	[iv setImageScaling:NSImageScaleProportionallyUpOrDown];
	[iv setImage:[NSImage imageNamed:@"MiniSlide"]];
	[iv setWantsLayer:YES];	
	[iv setHidden:YES];
	[self.view addSubview:iv positioned:NSWindowBelow relativeTo:dropView];

	
	NSPoint origin = NSMakePoint(NSMidX([self.view bounds]) - [iv frame].size.width / 2, [self.view bounds].size.height + [iv frame].size.height);
	[iv setFrameOrigin:origin];
	
	[iv setAlphaValue:0.0];
	[iv setHidden:NO];
	
	[self performSelector:@selector(fadeMiniSlideIn:) withObject:iv afterDelay:0.001];
}

- (void) fadeMiniSlideIn:(NSImageView*) iv;
{
	[CATransaction begin];
	[CATransaction setValue:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] forKey:kCATransactionAnimationTimingFunction];
	[CATransaction setValue:[NSNumber numberWithFloat:1.5] forKey:kCATransactionAnimationDuration];
	
	NSRect r = [iv frame];
	srandomdev();
	r.origin.y = 57; // + (random() % 20 - 10);
	
	[[iv animator] setFrameOrigin:r.origin];
	[[iv animator] setAlphaValue:1.0];
	
#define kMvrMaximumAngleRange (30)
	srandomdev();
	CGFloat angle = ((random() % kMvrMaximumAngleRange) - kMvrMaximumAngleRange / 2.0) * M_PI/180.0;
	[iv layer].transform = CATransform3DMakeAffineTransform(CGAffineTransformMakeRotation(angle));
	
	
	[CATransaction commit];
	
	[self performSelector:@selector(fadeSlideOut:) withObject:iv afterDelay:7.0];
}

- (void) fadeSlideOut:(NSImageView*) iv;
{
	[CATransaction begin];
	[CATransaction setValue:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut] forKey:kCATransactionAnimationTimingFunction];
	[CATransaction setValue:[NSNumber numberWithFloat:3.0] forKey:kCATransactionAnimationDuration];
	
	[[iv animator] setAlphaValue:0.0];
	
	[CATransaction commit];
	
	
	[iv performSelector:@selector(removeFromSuperview) withObject:nil afterDelay:4.0];
}

@end


@implementation MvrDeviceDropDestinationView

@synthesize owner;

- (void) awakeFromNib;
{
	[self registerForDraggedTypes:[NSArray arrayWithObjects:NSFilenamesPboardType, nil]]; // TODO more types?
}

- (void) setDragging:(BOOL) d;
{
	dragging = d;
	[self setNeedsDisplay:YES];
}

- (void) drawRect:(NSRect)dirtyRect;
{
	if (dragging) {
		[[[NSColor selectedTextBackgroundColor] colorWithAlphaComponent:0.5] setFill]; 
		NSRectFillUsingOperation(self.bounds, NSCompositeSourceOver);
	} else
		[super drawRect:dirtyRect];
}

- (NSDragOperation) draggingEntered:(id <NSDraggingInfo>) sender;
{
	NSArray* files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	if ([files count] != 1) {
		[self setDragging:NO];
		return NSDragOperationNone;
	} else {
		[self setDragging:YES];
		return NSDragOperationCopy;
	}
}

- (NSDragOperation) draggingUpdated:(id <NSDraggingInfo>) sender;
{
	NSArray* files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	if ([files count] != 1) {
		[self setDragging:NO];
		return NSDragOperationNone;
	} else {
		[self setDragging:YES];
		return NSDragOperationCopy;
	}
}

- (void) draggingExited:(id <NSDraggingInfo>)sender;
{
	[self setDragging:NO];
}

- (void) draggingEnded:(id <NSDraggingInfo>) sender;
{
	[self setDragging:NO];
}

- (BOOL) prepareForDragOperation:(id <NSDraggingInfo>)sender;
{
	NSArray* files = [[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType];
	return [files count] == 1;
}

- (BOOL) performDragOperation:(id <NSDraggingInfo>)sender;
{
	[self.owner sendItemFile:[[[sender draggingPasteboard] propertyListForType:NSFilenamesPboardType] objectAtIndex:0]];
	return YES;
}

@end

@implementation MvrDeviceBaseView

- (NSView *) hitTest:(NSPoint)aPoint;
{
	return nil;
}

@end