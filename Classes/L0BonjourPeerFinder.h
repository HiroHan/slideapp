//
//  L0BonjourPeerDiscovery.h
//  Shard
//
//  Created by ∞ on 24/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "L0PeerDiscovery.h"
#import "BLIP.h"

#define kL0BonjourPeeringServiceName @"_x-infinitelabs-slides._tcp."

@interface L0BonjourPeerFinder : NSObject <TCPListenerDelegate> {
	id <L0PeerDiscoveryDelegate> delegate;
	NSNetServiceBrowser* _browser;

	NSMutableSet* _peers;
	
	BLIPListener* _listener;
	NSNetService* _publishedService;
}

+ sharedFinder;

- (void) beginPeering;
- (void) stopPeering;

@property(assign) id <L0PeerDiscoveryDelegate> delegate;

@end

