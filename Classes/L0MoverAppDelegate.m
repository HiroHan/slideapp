//
//  ShardAppDelegate.m
//  Shard
//
//  Created by ∞ on 21/03/09.
//  Copyright __MyCompanyName__ 2009. All rights reserved.
//

#define L0MoverAppDelegateAllowFriendMethods 1
#import "L0MoverAppDelegate.h"

#import "L0ImageItem.h"
#import "L0AddressBookPersonItem.h"
#import "L0BonjourPeeringService.h"
#import "L0MoverAppDelegate+L0ItemPersistance.h"
#import "L0MoverAppDelegate+L0HelpAlerts.h"

#import "MvrAppleAdItem.h"
#import "L0MoverAppDelegate+MvrAppleAd.h"

#import <netinet/in.h>

// Alert tags
enum {
	kL0MoverNewVersionAlertTag = 1000,
};

#define kL0MoverLastSeenVersionKey @"L0MoverLastSeenVersion"

@interface L0MoverAppDelegate ()

- (void) returnFromImagePicker;
@property(copy, setter=privateSetDocumentsDirectory:) NSString* documentsDirectory;

- (BOOL) isCameraAvailable;

@end


@implementation L0MoverAppDelegate

- (void) applicationDidFinishLaunching:(UIApplication *) application;
{
	// Registering item subclasses.
	[L0ImageItem registerClass];
	[L0AddressBookPersonItem registerClass];
	
	// Starting up peering services.
	L0BonjourPeeringService* bonjourFinder = [L0BonjourPeeringService sharedService];
	bonjourFinder.delegate = self;
	[bonjourFinder start];
	
	// Setting up the UI.
	self.tableController = [[[L0MoverItemsTableController alloc] initWithDefaultNibName] autorelease];
	
	NSMutableArray* itemsArray = [self.toolbar.items mutableCopy];
	[itemsArray addObject:self.tableController.editButtonItem];
	UIButton* infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
	[infoButton addTarget:self.tableHostController action:@selector(showBack) forControlEvents:UIControlEventTouchUpInside];
	UIBarButtonItem* infoButtonItem = [[[UIBarButtonItem alloc] initWithCustomView:infoButton] autorelease];
	[itemsArray addObject:infoButtonItem];
	self.toolbar.items = itemsArray;
	[itemsArray release];
    
	[tableHostView addSubview:self.tableController.view];
	[window addSubview:self.tableHostController.view];
	
	// Loading persisted items from disk. (Later, so we avoid the AB constant bug.)
	[self performSelector:@selector(addPersistedItemsToTable) withObject:nil afterDelay:0.05];
	
	// Go!
	[window makeKeyAndVisible];
	
	// Be helpful if this is the first time (ahem).
	[self showAlertIfNotShownBeforeNamed:@"L0MoverWelcome"];
	
	networkUnavailableViewStartingPosition = self.networkUnavailableView.center;
	self.networkUnavailableView.hidden = YES;
	networkAvailable = YES;
	[self beginWatchingNetwork];	
}

#pragma mark -
#pragma mark Reachability

static SCNetworkReachabilityRef reach = NULL;

static void L0MoverAppDelegateNetworkStateChanged(SCNetworkReachabilityRef reach, SCNetworkReachabilityFlags flags, void* nothing) {
	L0MoverAppDelegate* myself = (L0MoverAppDelegate*) UIApp.delegate;
	[NSObject cancelPreviousPerformRequestsWithTarget:myself selector:@selector(checkNetwork) object:nil];
	[myself updateNetworkWithFlags:flags];
}

@synthesize networkUnavailableView, networkAvailable;

- (void) beginWatchingNetwork;
{
	if (reach) return;
	
	// What follows comes from Reachability.m.
	// Basically, we look for reachability for the link-local address --
	// and filter for WWAN or connection-required responses in -updateNetworkWithFlags:.
	
	// Build a sockaddr_in that we can pass to the address reachability query.
	struct sockaddr_in sin;
	bzero(&sin, sizeof(sin));
	sin.sin_len = sizeof(sin);
	sin.sin_family = AF_INET;
	
	// IN_LINKLOCALNETNUM is defined in <netinet/in.h> as 169.254.0.0
	sin.sin_addr.s_addr = htonl(IN_LINKLOCALNETNUM);
	
	reach = SCNetworkReachabilityCreateWithAddress(kCFAllocatorDefault, (const struct sockaddr*) &sin);
	
	SCNetworkReachabilityContext emptyContext = {0, self, NULL, NULL, NULL};
	SCNetworkReachabilitySetCallback(reach, &L0MoverAppDelegateNetworkStateChanged, &emptyContext);
	SCNetworkReachabilityScheduleWithRunLoop(reach, [[NSRunLoop currentRunLoop] getCFRunLoop], kCFRunLoopDefaultMode);
	
	SCNetworkReachabilityFlags flags;
	if (!SCNetworkReachabilityGetFlags(reach, &flags))
		[self performSelector:@selector(checkNetwork) withObject:nil afterDelay:0.5];
	else
		[self updateNetworkWithFlags:flags];
}

#if DEBUG
- (void) stopWatchingNetwork;
{
	if (!reach) return;
	
	SCNetworkReachabilityUnscheduleFromRunLoop(reach, [[NSRunLoop currentRunLoop] getCFRunLoop], kCFRunLoopDefaultMode);
	CFRelease(reach); reach = NULL;
}
#endif

- (void) checkNetwork;
{
	SCNetworkReachabilityFlags flags;
	if (SCNetworkReachabilityGetFlags(reach, &flags))
		[self updateNetworkWithFlags:flags];
}

- (void) updateNetworkWithFlags:(SCNetworkReachabilityFlags) flags;
{
	BOOL habemusNetwork = 
		(flags & kSCNetworkReachabilityFlagsReachable) &&
		!(flags & kSCNetworkReachabilityFlagsConnectionRequired);
	// note that unlike Reachability.m we don't care about WWANs.
	
	self.networkAvailable = habemusNetwork;
}

- (void) setNetworkAvailable:(BOOL) habemusNetwork;
{
	BOOL wasUp = networkAvailable;
	networkAvailable = habemusNetwork;
	L0Log(@"Available = %d", habemusNetwork);
	
	if (habemusNetwork && !wasUp) {
		// update UI for network. Huzzah!
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationDuration:1.0];
		
		self.networkUnavailableView.alpha = 0.0;
		CGPoint position = self.networkUnavailableView.center;
		position.y =
		self.networkUnavailableView.superview.frame.size.height +
		self.networkUnavailableView.superview.frame.size.height;
		self.networkUnavailableView.center = position;
		
		[UIView commitAnimations];

		self.networkUnavailableView.hidden = NO;
	} else if (!habemusNetwork && wasUp) {
		// disable UI for no network. Boo, user, boo!
		CGPoint position = self.networkUnavailableView.center;
		position.y =
		self.networkUnavailableView.superview.frame.size.height +
		self.networkUnavailableView.superview.frame.size.height;
		self.networkUnavailableView.center = position;
		
		[UIView beginAnimations:nil context:NULL];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationDuration:1.0];
		
		self.networkUnavailableView.alpha = 1.0;
		self.networkUnavailableView.center = networkUnavailableViewStartingPosition;
		
		[UIView commitAnimations];
		
		// clear all peers off the table. TODO: only Bonjour peers!
		self.tableController.northPeer = nil;
		self.tableController.eastPeer = nil;
		self.tableController.westPeer = nil;
		
		self.networkUnavailableView.hidden = NO;
	}

	[self.networkUnavailableView.superview bringSubviewToFront:self.networkUnavailableView];
}

#pragma mark -
#pragma mark Other methods

- (void) addPersistedItemsToTable;
{
	for (L0MoverItem* i in [self loadItemsFromMassStorage])
		[self.tableController addItem:i animation:kL0SlideItemsTableNoAddAnimation];
}

- (void) applicationWillTerminate:(UIApplication*) app;
{
	[self persistItemsToMassStorage:[self.tableController items]];
}

- (void) slidePeer:(L0MoverPeer*) peer willBeSentItem:(L0MoverItem*) item;
{
	L0Log(@"About to send item %@", item);
	[self beginSendingForAppleAdWithItem:item];
}

- (void) slidePeer:(L0MoverPeer*) peer wasSentItem:(L0MoverItem*) item;
{
	// gutted for Apple ad.
}

- (void) slidePeerWillSendUsItem:(L0MoverPeer*) peer;
{
	L0Log(@"Receiving from %@", peer);
	[self.tableController beginWaitingForItemComingFromPeer:peer];
	
	// rigged for Apple ad.
	[self beginReceivingForAppleAd];
}
- (void) slidePeer:(L0MoverPeer*) peer didSendUsItem:(L0MoverItem*) item;
{
	// gutted for Apple ad.
}
- (void) slidePeerDidCancelSendingUsItem:(L0MoverPeer*) peer;
{
	// gutted for Apple ad.
}

- (void) peerFound:(L0MoverPeer*) peer;
{
	peer.delegate = self;
	[self.tableController addPeerIfSpaceAllows:peer];
	
	if (lastSeenVersion == 0.0) {
		double seen = [[NSUserDefaults standardUserDefaults] doubleForKey:kL0MoverLastSeenVersionKey];
		double mine = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] doubleValue];
		
		lastSeenVersion = MAX(seen, mine);
	}
	
	if (peer.applicationVersion > lastSeenVersion) {
		lastSeenVersion = peer.applicationVersion;
		[[NSUserDefaults standardUserDefaults] setDouble:peer.applicationVersion forKey:kL0MoverLastSeenVersionKey];

		NSString* version = peer.userVisibleApplicationVersion?: @"(no version number)";
		[self displayNewVersionAlertWithVersion:version];
	}
}

- (void) displayNewVersionAlertWithVersion:(NSString*) version;
{
	UIAlertView* alert = [UIAlertView alertNamed:@"L0MoverNewVersion"];
	alert.tag = kL0MoverNewVersionAlertTag;
	[alert setTitleFormat:nil, version];
	alert.delegate = self;
	[alert show];
}

- (void) alertView:(UIAlertView*) alertView clickedButtonAtIndex:(NSInteger) buttonIndex;
{
	switch (alertView.tag) {
		case kL0MoverNewVersionAlertTag: {
			if (buttonIndex != 1) return;
			
			NSString* appStoreURLString = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"L0MoverAppStoreURL"];
			if (!appStoreURLString)
				appStoreURLString = @"http://infinite-labs.net/mover/download";
			[UIApp openURL:[NSURL URLWithString:appStoreURLString]];
			return;
		}
	}
}

- (IBAction) testBySendingItemToAnyPeer;
{
}

- (void) peerLeft:(L0MoverPeer*) peer;
{
	[self.tableController removePeer:peer];
}

@synthesize window, toolbar;
@synthesize tableController, tableHostView, tableHostController;

- (void) dealloc;
{
	[toolbar release];
	[tableHostView release];
	[tableHostController release];
	[tableController release];
    [window release];
    [super dealloc];
}

#define kL0MoverAddImageButton @"kL0MoverAddImageButton"
#define kL0MoverAddContactButton @"kL0MoverAddContactButton"
#define kL0MoverTakeAPhotoButton @"kL0MoverTakeAPhotoButton"
#define kL0MoverCancelButton @"kL0MoverCancelButton"

- (BOOL) isCameraAvailable;
{
#if defined(TARGET_IPHONE_SIMULATOR) && kL0iPhoneSimulatorPretendIsiPodTouch
	return NO;
#else
	return [UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera];
#endif
}

- (IBAction) addItem;
{
	[self.tableController setEditing:NO animated:YES];
	
	// gutted for Apple ad.

	for (int i = 0; i <= 5; i++) {
		MvrAppleAdItem* adItem = [[MvrAppleAdItem alloc] initWithNumber:i];
		[self.tableController addItem:adItem animation:kL0SlideItemsTableAddFromSouth];
		[adItem release];
	}
 }

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex;
{
	id identifier = [(L0ActionSheet*)actionSheet identifierForButtonAtIndex:buttonIndex];
	
	if ([identifier isEqual:kL0MoverAddImageButton])
		[self addImageItem];
	else if ([identifier isEqual:kL0MoverTakeAPhotoButton])
		[self takeAPhotoAndAddImageItem];
	else if ([identifier isEqual:kL0MoverAddContactButton])
		[self addAddressBookItem];
}

- (void) addAddressBookItem;
{
	ABPeoplePickerNavigationController* picker = [[[ABPeoplePickerNavigationController alloc] init] autorelease];
	picker.peoplePickerDelegate = self;
	[self.tableHostController presentModalViewController:picker animated:YES];
}

- (void)peoplePickerNavigationControllerDidCancel:(ABPeoplePickerNavigationController *)peoplePicker;
{
	[peoplePicker dismissModalViewControllerAnimated:YES];
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person;
{
	L0AddressBookPersonItem* item = [[L0AddressBookPersonItem alloc] initWithAddressBookRecord:person];
	[self.tableController addItem:item animation:kL0SlideItemsTableAddFromSouth];
	[item release];
	
	[peoplePicker dismissModalViewControllerAnimated:YES];
	return NO;
}

- (BOOL)peoplePickerNavigationController:(ABPeoplePickerNavigationController *)peoplePicker shouldContinueAfterSelectingPerson:(ABRecordRef)person property:(ABPropertyID)property identifier:(ABMultiValueIdentifier)identifier;
{
	return [self peoplePickerNavigationController:peoplePicker shouldContinueAfterSelectingPerson:person];
}

- (void) takeAPhotoAndAddImageItem;
{
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera])
		return;
	
	UIImagePickerController* imagePicker = [[[UIImagePickerController alloc] init] autorelease];
	imagePicker.sourceType = UIImagePickerControllerSourceTypeCamera;
	imagePicker.delegate = self;
	[self.tableHostController presentModalViewController:imagePicker animated:YES];
}	

- (void) addImageItem;
{
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary])
		return;
	
	UIImagePickerController* imagePicker = [[[UIImagePickerController alloc] init] autorelease];
	imagePicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	imagePicker.delegate = self;
	[self.tableHostController presentModalViewController:imagePicker animated:YES];
}

- (void)imagePickerController:(UIImagePickerController *)picker didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo;
{
	L0ImageItem* item = [[L0ImageItem alloc] initWithTitle:@"" image:image];
	if (picker.sourceType == UIImagePickerControllerSourceTypeCamera)
		[item storeToAppropriateApplication];
	
	[self.tableController addItem:item animation:kL0SlideItemsTableAddFromSouth];
	[item release];
	
	[picker dismissModalViewControllerAnimated:YES];
	[self returnFromImagePicker];
}

@synthesize documentsDirectory;
- (NSString*) documentsDirectory;
{
	if (!documentsDirectory) {
		NSArray* docsDirs = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSAssert([docsDirs count] > 0, @"At least one documents directory is known");
		self.documentsDirectory = [docsDirs objectAtIndex:0];
	}
	
	return documentsDirectory;
}

- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker;
{
	[picker dismissModalViewControllerAnimated:YES];
	[self returnFromImagePicker];
}

- (void) returnFromImagePicker;
{
	[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault animated:YES];	
}

@end
