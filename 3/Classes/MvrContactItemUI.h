//
//  MvrContactItemUI.h
//  Mover3
//
//  Created by ∞ on 02/10/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AddressBookUI/AddressBookUI.h>

#import "MvrItemUI.h"

@interface MvrContactItemUI : MvrItemUI <ABPeoplePickerNavigationControllerDelegate, ABUnknownPersonViewControllerDelegate> {
	
	UINavigationController* shownPerson;
	NSMutableSet* duplicateContactHandlers;
}

@end
