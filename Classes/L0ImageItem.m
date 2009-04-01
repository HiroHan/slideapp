//
//  L0BeamableImage.m
//  Shard
//
//  Created by ∞ on 21/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0ImageItem.h"

//#if __IPHONE_OS_VERSION_MIN_REQUIRED >= 30000
//#import <MobileCoreServices/MobileCoreServices.h>
//#else
#import "L0SlideUTISupport.h"
//#endif

#import <MuiKit/MuiKit.h>

@implementation L0ImageItem

+ (NSArray*) supportedTypes;
{
	return [NSArray arrayWithObjects:
			(id) kUTTypeTIFF,
			(id) kUTTypeJPEG,
			(id) kUTTypeGIF,
			(id) kUTTypePNG,
			(id) kUTTypeBMP,
			(id) kUTTypeICO,
			nil];
}

- (NSData*) networkPacketPayload;
{	
	return UIImagePNGRepresentation([self.image imageByRenderingRotation]);
}

- (id) initWithTitle:(NSString*) ti image:(UIImage*) img;
{
	if (self = [super init]) {
		self.title = ti;
		self.image = img;
		self.type = (id) kUTTypePNG;
	}
	
	return self;
}

- (UIImage*) representingImage;
{
	return self.image;
}

- (id) initWithNetworkPacketPayload:(NSData*) payload type:(NSString*) ty title:(NSString*) ti;
{
	if (self = [super init]) {
		self.title = ti;
		self.type = (id) kUTTypePNG;
		UIImage* img = [UIImage imageWithData:payload];
		
		if (!img) {
			[self release];
			return nil;
		}
		
		self.image = img;
	}
	
	return self;
}

- (void) store;
{
	UIImageWriteToSavedPhotosAlbum(self.image, nil, nil, NULL);
}

@synthesize image;

- (void) dealloc;
{
	[image release];
	[super dealloc];
}

@end
