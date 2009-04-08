//
//  L0SlideItem.m
//  Shard
//
//  Created by ∞ on 21/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0SlideItem.h"

@interface L0SlideItem ()

@property(copy, setter=_setOffloadingFile:) NSString* offloadingFile;

@end


@implementation L0SlideItem

+ (void) registerClass;
{
	for (NSString* type in [self supportedTypes])
		[self registerClass:self forType:type];
}

+ (NSArray*) supportedTypes;
{
	NSAssert(NO, @"Subclasses of L0SlideItem must implement this method.");
	return nil;
}

static NSMutableDictionary* classes = nil;

+ (void) registerClass:(Class) c forType:(NSString*) type;
{
	if (!classes)
		classes = [NSMutableDictionary new];
	
	[classes setObject:c forKey:type];
}

+ (Class) classForType:(NSString*) c;
{
	return [classes objectForKey:c];
}

- (id) initWithExternalRepresentation:(NSData*) payload type:(NSString*) type title:(NSString*) title;
{
	NSAssert(NO, @"Subclasses of L0SlideItem must implement this method.");
	return nil;
}

@synthesize title;
@synthesize type;
@synthesize representingImage;

- (NSData*) externalRepresentation;
{
	NSAssert(NO, @"Subclasses of L0SlideItem must implement this method.");
	return nil;
}

- (void) storeToAppropriateApplication;
{
	// Overridden, optionally, by subclasses.
}

- (void) offloadToFile:(NSString*) file;
{	
	if ([[self externalRepresentation] writeToFile:file atomically:YES]) {
		self.offloadingFile = file;
		[self clearCache];
	}
}

@synthesize offloadingFile;

// Used by subclasses to 'see' the external representation that
// was saved in offloadToFile:.
- (NSData*) contentsOfOffloadingFile;
{
	NSString* file = self.offloadingFile;
	if (!file) return nil;
	
	return [NSData dataWithContentsOfFile:self.offloadingFile];
}

- (void) clearCache;
{
	// Overridden, optionally, by subclasses.
}

- (void) dealloc;
{
	[title release];
	[type release];
	[representingImage release];
	[super dealloc];
}

@end

@implementation L0SlideItem (L0BLIPBeaming)

- (BLIPRequest*) networkBLIPRequest;
{
	NSDictionary* properties = [NSDictionary dictionaryWithObjectsAndKeys:
								self.title, @"L0SlideItemTitle",
								self.type, @"L0SlideItemType",
								@"1", @"L0SlideItemWireProtocolVersion",
								nil];
								
	
	return [BLIPRequest requestWithBody:[self externalRepresentation]
							 properties:properties];
}

+ (id) beamableItemWithNetworkBLIPRequest:(BLIPRequest*) req;
{
	NSString* version = [req valueOfProperty:@"L0SlideItemWireProtocolVersion"];
	if (![version isEqualToString:@"1"])
		return nil;
	
	NSString* type = [req valueOfProperty:@"L0SlideItemType"];
	if (!type)
		return nil;
	
	
	NSString* title = [req valueOfProperty:@"L0SlideItemTitle"];
	if (!title)
		return nil;
	
	Class c = [self classForType:type];
	if (!c)
		return nil;
					   
	return [[[c alloc] initWithExternalRepresentation:req.body type:type title:title] autorelease];
}

@end
