//
//  L0BonjourPeerDiscovery.h
//  Shard
//
//  Created by ∞ on 24/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "L0PeerDiscovery.h"
#import "AsyncSocket.h"

#define kL0BonjourPeeringServiceName @"_x-il-mover-ad._tcp."

@interface L0BonjourPeeringService : NSObject {
	id <L0PeerDiscoveryDelegate> delegate;
	NSNetServiceBrowser* browser;

	NSMutableSet* peers;
	
	NSMutableSet* pendingConnections;
	
	AsyncSocket* serverSocket;
	NSNetService* selfService;
}

+ sharedService;

- (void) start;
- (void) stop;

@property(assign) id <L0PeerDiscoveryDelegate> delegate;

@end

