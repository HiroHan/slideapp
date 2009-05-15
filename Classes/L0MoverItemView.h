//
//  L0BeamableItemView.h
//  Shard
//
//  Created by ∞ on 21/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <MuiKit/MuiKit.h>
#import "L0MoverItem.h"

@interface L0MoverItemView : L0DraggableView {
	UIView* contentView;
		
	UILabel* label;
	UIImageView* imageView;
	UIButton* deleteButton;
	UIImageView* highlightView;
	UIImageView* backdropView;
	
	L0MoverItem* item;

	id deletionTarget;
	SEL deletionAction;
	
	BOOL editing;
	BOOL highlighted;
}

@property(retain) IBOutlet UIView* contentView;
@property(assign) IBOutlet UILabel* label;
@property(assign) IBOutlet UIImageView* imageView;
@property(assign) IBOutlet UIImageView* backdropView;
@property(assign) IBOutlet UIButton* deleteButton;

@property(retain) IBOutlet UIImageView* highlightView;

- (void) setDeletionTarget:(id) target action:(SEL) action;

- (void) displayWithContentsOfItem:(L0MoverItem*) item;
@property(readonly) L0MoverItem* item;

- (void) setEditing:(BOOL) editing animated:(BOOL) animated;
@property(getter=isEditing) BOOL editing;

- (void) setHighlighted:(BOOL) highlighted animated:(BOOL) animated animationDuration:(NSTimeInterval) duration;
@property(getter=isHighlighted) BOOL highlighted;

- (IBAction) performDelete;

@end
