//
//  L0BeamingPeer.h
//  Shard
//
//  Created by ∞ on 24/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "L0MoverItem.h"

#define kL0UnknownApplicationVersion (0.0)

@protocol L0MoverPeerDelegate;

@interface L0MoverPeer : NSObject {
	id <L0MoverPeerDelegate> delegate;
}

@property(readonly) NSString* name;
@property(assign) id <L0MoverPeerDelegate> delegate;
@property(readonly) double applicationVersion;
@property(readonly, copy) NSString* userVisibleApplicationVersion;

- (BOOL) receiveItem:(L0MoverItem*) item;

@end

@protocol MvrIncoming <NSObject>

@property(readonly) CGFloat progress;
@property(readonly) L0MoverItem* item;

@optional
- (void) cancel;

@end

@protocol L0MoverPeerDelegate <NSObject>

- (void) moverPeer:(L0MoverPeer*) peer willBeSentItem:(L0MoverItem*) item;
- (void) moverPeer:(L0MoverPeer*) peer wasSentItem:(L0MoverItem*) item;

- (void) moverPeer:(L0MoverPeer*) peer didStartReceiving:(id <MvrIncoming>) incomingTransfer;
- (void) moverPeer:(L0MoverPeer*) peer didStopReceiving:(id <MvrIncoming>) incomingTransfer;
@end
