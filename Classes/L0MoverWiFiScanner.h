//
//  L0MoverDummyScanner.h
//  Mover
//
//  Created by ∞ on 10/06/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <SystemConfiguration/SystemConfiguration.h>

#import "MvrWiFiScanner.h"

#import "MvrNetworkExchange.h"
#import "BLIP.h"

#define kL0BonjourPeerApplicationVersionKey @"L0AppVersion"
#define kL0BonjourPeerUserVisibleApplicationVersionKey @"L0UserAppVersion"
#define kL0BonjourPeerUniqueIdentifierKey @"L0PeerID"

#define kL0BonjourPeeringServiceName @"_x-infinitelabs-slides._tcp."
#define kMvrStandardServiceName @"_x-mover._tcp."

@interface L0MoverWiFiScanner : MvrWiFiScanner <L0MoverPeerScanner, TCPListenerDelegate, TCPConnectionDelegate> {
	NSNetServiceBrowser* legacyBrowser;
	NSNetServiceBrowser* modernBrowser;
	NSNetService* legacyService;
	NSNetService* modernService;
	int uniquenessNameSuffix;
	
	BLIPListener* listener;
	NSMutableSet* pendingConnections;
	CFMutableDictionaryRef connectionsToTransfers;
	NSMutableSet* availableChannels;
	
	MvrNetworkExchange* service;
	BOOL jammed;
	
#if DEBUG
	BOOL isJammingSimulated;
	BOOL simulatedJammedValue;
#endif
	
	NSTimer* browserResetTimer;
	
	L0KVODispatcher* dispatcher;
	NSMutableSet* servicesBeingDisabled;
}

+ sharedScanner;

#if DEBUG
- (void) testBySimulatingJamming:(BOOL) simulatedJam;
- (void) testByStoppingJamSimulation;
#endif

@end
