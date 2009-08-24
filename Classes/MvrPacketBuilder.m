//
//  MvrPacketBuilder.m
//  Mover
//
//  Created by ∞ on 23/08/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "MvrPacketBuilder.h"

@interface MvrPacketBuilder ()

- (void) stopWithoutNotifying;
- (void) startProducingPayload;

@end

NSString* const kMvrPacketBuilderErrorDomain = @"kMvrPacketBuilderErrorDomain";

@implementation MvrPacketBuilder

@synthesize running = sealed, runLoop;

- (id) initWithDelegate:(id <MvrPacketBuilderDelegate>) d;
{
	if (self = [super init]) {
		delegate = d;
		metadata = [NSMutableDictionary new];
		payloadOrder = [NSMutableArray new];
		payloadObjects = [NSMutableDictionary new];
		payloadLengths = [NSMutableDictionary new];
		self.runLoop = [NSRunLoop currentRunLoop];
	}
	
	return self;
}

- (void) dealloc;
{
	[self stop];
	[payloadOrder release];
	[payloadObjects release];
	[payloadLengths release];
	[metadata release];

	self.runLoop = nil;
	[super dealloc];
}

- (void) setMetadataValue:(NSString*) v forKey:(NSString*) k;
{
	NSAssert(!sealed, @"You can't modify the metadata while a packet is being built.");
	
	NSCharacterSet* nullCharset = [NSCharacterSet characterSetWithRange:NSMakeRange(0, 1)];
	NSAssert([v rangeOfCharacterFromSet:nullCharset].location == NSNotFound, @"No NULL characters in the value!");
	NSAssert([k rangeOfCharacterFromSet:nullCharset].location == NSNotFound, @"No NULL characters in the key!");
	
	[metadata setObject:v forKey:k];
}

- (void) addPayload:(id) b length:(unsigned long long) length forKey:(NSString*) key;
{
	NSAssert(!sealed, @"You can't modify the payloads while a packet is being built.");
	
	[payloadOrder removeObject:key];
	[payloadOrder addObject:key];
	
	if ([b isKindOfClass:[NSData class]]) {
		[payloadObjects setObject:[[b copy] autorelease] forKey:key];
		[payloadLengths setObject:[NSNumber numberWithUnsignedInteger:[b length]] forKey:key];
	} else if ([b isKindOfClass:[NSInputStream class]]) {
		[payloadObjects setObject:b forKey:key];
		[payloadLengths setObject:[NSNumber numberWithUnsignedLongLong:length] forKey:key];
	} else
		NSAssert(NO, @"Unknown kind of payload object.");
}

- (void) addPayloadWithData:(NSData*) d forKey:(NSString*) key;
{
	[self addPayload:d length:kMvrPacketBuilderDefaultLength forKey:key];
}

- (BOOL) addPayloadByReferencingFile:(NSString*) s forKey:(NSString*) key error:(NSError**) e;
{
	NSAssert(!sealed, @"You can't modify the payloads while a packet is being built.");

	NSDictionary* d = [[NSFileManager defaultManager] attributesOfItemAtPath:s error:e];
	if (!d) return NO;
	
	NSInputStream* is = [NSInputStream inputStreamWithFileAtPath:s];
	[self addPayload:is length:[[d objectForKey:NSFileSize] unsignedLongLongValue] forKey:key];
	return YES;
}

- (void) removePayloadForKey:(NSString*) key;
{
	NSAssert(!sealed, @"You can't modify the payloads while a packet is being built.");
	
	[payloadOrder removeObject:key];
	[payloadObjects removeObjectForKey:key];
	[payloadLengths removeObjectForKey:key];
}

- (void) removeAllPayloads;
{
	NSAssert(!sealed, @"You can't modify the payloads while a packet is being built.");
	
	[payloadOrder removeAllObjects];
	[payloadObjects removeAllObjects];
	[payloadLengths removeAllObjects];
}

- (void) start;
{
	if (sealed) return;
	NSAssert(self.runLoop == [NSRunLoop currentRunLoop], @"Do not call -start on a thread other than the one where you scheduled the builder. Either call -start on the thread where you created the object, or use the .runLoop property to change what run loop to use to schedule stuff.");
	
	cancelled = NO;
	isWorkingOnStreamPayload = NO;
	
	NSMutableArray* stringVersionsOfPayloadStops = [NSMutableArray array];
	unsigned long long current = 0;
	for (NSString* key in payloadOrder) {
		NSNumber* n = [payloadLengths objectForKey:key];
		current += [n unsignedLongLongValue];
		[stringVersionsOfPayloadStops addObject:[NSString stringWithFormat:@"%llu", current]];
	}
	
	[self setMetadataValue:[stringVersionsOfPayloadStops componentsJoinedByString:@" "] forKey:kMvrProtocolPayloadStopsKey];
	[self setMetadataValue:[payloadOrder componentsJoinedByString:@" "] forKey:kMvrProtocolPayloadKeysKey];
	
	sealed = YES;
	
	[delegate packetBuilderWillStart:self];
	if (cancelled) return;
	
	// The header.
	NSData* d = [NSData dataWithBytesNoCopy:(void*) kMvrPacketParserStartingBytes length:kMvrPacketParserStartingBytesLength freeWhenDone:NO];
	[delegate packetBuilder:self didProduceData:d];
	if (cancelled) return;
	
	// The metadata.
	const char nullCharacter = 0;
	// This 'canonicalizes' the packets so that two packets with same metadata and same payloads are byte-for-byte equal, by sorting the metadata by key via compare:.
	NSMutableArray* orderedMetadata = [NSMutableArray arrayWithArray:[metadata allKeys]];
	[orderedMetadata sortUsingSelector:@selector(compare:)];
	for (NSString* k in orderedMetadata) {
		NSMutableData* d = [NSMutableData new];
		[d appendData:[k dataUsingEncoding:NSUTF8StringEncoding]];
		[d appendBytes:&nullCharacter length:1];
		[d appendData:[[metadata objectForKey:k] dataUsingEncoding:NSUTF8StringEncoding]];
		[d appendBytes:&nullCharacter length:1];
		[delegate packetBuilder:self didProduceData:d];
		[d release];
		if (cancelled) return;
	}
	
	[delegate packetBuilder:self didProduceData:[NSData dataWithBytesNoCopy:(void*) &nullCharacter length:1 freeWhenDone:NO]];
	if (cancelled) return;
	currentPayloadIndex = 0;
	
//	if ([body isKindOfClass:[NSData class]]) {
//		[delegate packetBuilder:self didProduceData:body];
//		sealed = NO;
//		if (cancelled) return;
//		[delegate packetBuilder:self didEndWithError:nil];
//	} else if ([body isKindOfClass:[NSStream class]]) {
//		toBeRead = bodyLength;
//		[body scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
//		[body setDelegate:self];
//		[body open];
//	}
	[self startProducingPayload];
}

- (void) startProducingPayload;
{
	while (!cancelled && currentPayloadIndex < [payloadOrder count]) {
		
		NSString* key = [payloadOrder objectAtIndex:currentPayloadIndex];
		id payload = [payloadObjects objectForKey:key];
		
		if ([payload isKindOfClass:[NSData class]]) {
			
			isWorkingOnStreamPayload = NO;
			[delegate packetBuilder:self didProduceData:payload];
			
		} else if ([payload isKindOfClass:[NSInputStream class]]) {
			
			isWorkingOnStreamPayload = YES;
			toBeRead = [[payloadLengths objectForKey:key] unsignedLongLongValue];
			[payload scheduleInRunLoop:self.runLoop forMode:NSRunLoopCommonModes];
			[payload setDelegate:self];
			[payload open];
			return;
			
		}
		
		currentPayloadIndex++;
	}
	
	if (!cancelled) {
		[delegate packetBuilder:self didEndWithError:nil];
		currentPayloadIndex--;
		[self stopWithoutNotifying];
	}
}

#define kMvrPacketBuilderStackBufferSize 10240

- (void) stream:(NSInputStream*) aStream handleEvent:(NSStreamEvent) eventCode;
{	
	switch (eventCode) {
		case NSStreamEventHasBytesAvailable: {
			uint8_t* buffer; NSUInteger bufferSize;
			uint8_t stackBuffer[kMvrPacketBuilderStackBufferSize];
			
			if (![aStream getBuffer:&buffer length:&bufferSize]) {
				buffer = stackBuffer;
				bufferSize = [aStream read:buffer maxLength:kMvrPacketBuilderStackBufferSize];
			}
			
			bufferSize = MIN(bufferSize, toBeRead);
			toBeRead -= bufferSize;
			
			[delegate packetBuilder:self didProduceData:[NSData dataWithBytesNoCopy:buffer length:bufferSize freeWhenDone:NO]];
			if (cancelled) return;
			
			if (toBeRead == 0) {
				[aStream setDelegate:nil];
				[aStream close];
				currentPayloadIndex++;
				[self startProducingPayload];
			}
		}
			break;
			
		case NSStreamEventErrorOccurred: {
			[delegate packetBuilder:self didEndWithError:[aStream streamError]];
			[self stopWithoutNotifying];
		}
			break;
			
		case NSStreamEventEndEncountered: {
			if (sealed) {
				NSError* e = nil;
				if (toBeRead > 0)
					e = [NSError errorWithDomain:kMvrPacketBuilderErrorDomain code:kMvrPacketBuilderNotEnoughDataInStreamError userInfo:nil];
				[delegate packetBuilder:self didEndWithError:e];
				[self stopWithoutNotifying];
			}
		}
			break;
			
		default:
			break;
	}
}

- (void) stop;
{
	if (!sealed) return;
	[self stopWithoutNotifying];
	[delegate packetBuilder:self didEndWithError:[NSError errorWithDomain:NSCocoaErrorDomain code:NSUserCancelledError userInfo:nil]];
}

- (void) stopWithoutNotifying;
{
	if (!sealed) return;
	cancelled = YES;
	
	if (isWorkingOnStreamPayload) {
		id body = [payloadObjects objectForKey:[payloadOrder objectAtIndex:currentPayloadIndex]];
		if ([body isKindOfClass:[NSInputStream class]]) {
			[body setDelegate:nil];
			[body close];
		}
	}
	
	sealed = NO;
}

@end
