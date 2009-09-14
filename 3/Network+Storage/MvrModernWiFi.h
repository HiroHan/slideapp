//
//  MvrModernWiFi.h
//  Network
//
//  Created by ∞ on 12/09/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MvrWiFiScanner.h"

#define kMvrModernWiFiBonjourServiceType @"_x-mover2._tcp."
#define kMvrModernWiFiPort (25252)

@class L0KVODispatcher;

@class AsyncSocket, MvrModernWiFiChannel;

@interface MvrModernWiFi : MvrWiFiScanner {
	AsyncSocket* serverSocket;
	
	NSMutableSet* incomingTransfers;
	L0KVODispatcher* dispatcher;
}

- (MvrModernWiFiChannel*) channelForAddress:(NSData*) address;

@end
