//
//  L0BeamableImage.h
//  Shard
//
//  Created by ∞ on 21/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "L0MoverItem.h"

@interface L0ImageItem : L0MoverItem {
	UIImage* image;
}

- (id) initWithTitle:(NSString*) title image:(UIImage*) image;
@property(readonly) UIImage* image;

@end
