//
//  L0BeamableItemView.m
//  Shard
//
//  Created by ∞ on 21/03/09.
//  Copyright 2009 __MyCompanyName__. All rights reserved.
//

#import "L0MoverItemView.h"
#import "L0ImageItem.h"
#import "MvrProtocol.h"

@interface L0MoverItemView ()

- (void) removeHighlightViewIfPossible;

- (void) stopProgress;
- (void) updateProgress;

@end


@implementation L0MoverItemView

@synthesize contentView, label, imageView, highlightView, backdropView;
@synthesize spinner, progressBar;

- (id) initWithFrame:(CGRect) frame;
{
    if (self = [super initWithFrame:frame]) {
        [[NSBundle mainBundle] loadNibNamed:NSStringFromClass([self class]) owner:self options:[NSDictionary dictionary]];

		self.contentView.frame = self.bounds;
		self.contentView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
		[self addSubview:self.contentView];
		
		self.backgroundColor = [UIColor clearColor];
		self.opaque = NO;
		self.editing = NO;
		self.highlighted = NO;
		
		self.maximumSlideDistances = CGSizeMake(350, 150);
		self.slideSpeedDampeningFactor = 0.6;
		
		self.isAccessibilityElement = YES;
		
		progress = kMvrPacketIndeterminateProgress;
	}
	
    return self;
}

- (void) sizeToFit;
{
	CGRect frame = self.frame;
	frame.size = CGSizeMake(179, 179);
	self.frame = frame;
	
	self.contentView.frame = self.bounds;
}

- (void) dealloc;
{
	self.contentView = nil;
	self.highlightView = nil;
	[super dealloc];
}

@synthesize item;
- (void) setItem:(L0MoverItem*) i;
{
	self.label.text = i.title;
	
	NSString* accessibilityLabel = i.title;
	if ([accessibilityLabel length] == 0) {
		if ([i isKindOfClass:[L0ImageItem class]])
			accessibilityLabel = @"Image";
		else
			accessibilityLabel = nil;
	}
	
	if (accessibilityLabel)
		self.accessibilityLabel = accessibilityLabel;
	
	self.imageView.image = i.representingImage;
	item = i;
}

@synthesize actionButton;

- (void) setActionButtonTarget:(id) target selector:(SEL) action;
{
	actionButtonTarget = target;
	actionButtonSelector = action;
}

- (IBAction) performDelete;
{
	if (actionButtonTarget && actionButtonSelector)
		[actionButtonTarget performSelector:actionButtonSelector withObject:self];
}

- (void) setEditing:(BOOL) newEditing animated:(BOOL) animated;
{
	if (newEditing == editing)
		return;
		
	editing = newEditing;
	self.pressAndHoldDelay = editing? 0.1 : 0.7;
	L0Log(@"press and hold delay of %@ now %f", self, self.pressAndHoldDelay);
	if (editing) {
		
		actionButton.userInteractionEnabled = YES;
		contentView.userInteractionEnabled = YES;

		if (animated) {
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:0.4];
		}

		imageView.alpha = 0.4;
		actionButton.alpha = 1.0;
		
		if (animated)
			[UIView commitAnimations];
		
	} else {

		actionButton.userInteractionEnabled = NO;
		contentView.userInteractionEnabled = NO;

		if (animated) {
			[UIView beginAnimations:nil context:NULL];
			[UIView setAnimationDuration:0.4];
		}
		
		imageView.alpha = 1.0;
		actionButton.alpha = 0.0;
		
		if (animated)
			[UIView commitAnimations];
		
	}
}

- (void) setHighlighted:(BOOL) h animated:(BOOL) animated animationDuration:(NSTimeInterval) duration;
{
	L0Log(@"%d, %d, %f", h, animated, duration);
	highlighted = h;
	if (h && !self.highlightView.superview) {
		L0Log(@"Readding highlight view to hierarchy");
		self.highlightView.alpha = 0;
		[self.contentView insertSubview:self.highlightView aboveSubview:self.backdropView];
	}
	
	[UIView beginAnimations:nil context:NULL];
	if (animated) {
		[UIView setAnimationDuration:duration];
		[UIView setAnimationCurve:UIViewAnimationCurveEaseOut];
		[UIView setAnimationBeginsFromCurrentState:YES];
		[UIView setAnimationDelegate:self];
		[UIView setAnimationDidStopSelector:@selector(highlightAnimation:didEndByFinishing:context:)];
	} else
		[UIView setAnimationDuration:0.0];
	
	highlightView.alpha = h? 1.0 : 0.0;
	label.highlighted = h;
	
	[UIView commitAnimations];
	
	if (!animated)
		[self removeHighlightViewIfPossible];
}

- (void) highlightAnimation:(NSString*) ani didEndByFinishing:(BOOL) finished context:(void*) context;
{
	[self removeHighlightViewIfPossible];
}

- (void) removeHighlightViewIfPossible;
{
	if (!self.highlighted && self.highlightView.superview) {
		L0Log(@"Removing highlight view from hierarchy");
		[self.highlightView removeFromSuperview];
	}
}

@synthesize editing;
- (void) setEditing:(BOOL) e;
{
	[self setEditing:e animated:NO];
}

@synthesize highlighted;
- (void) setHighlighted:(BOOL) h;
{
	[self setHighlighted:h animated:NO animationDuration:0.0];
}

@synthesize transferring;
- (void) setTransferring:(BOOL) t;
{
	BOOL wasTransferring = transferring;
	transferring = t;
	
	[self updateProgress];

	if (t && !wasTransferring) {
		[UIView beginAnimations:nil context:NULL];
		
		self.label.alpha = 0.0;
		self.imageView.alpha = 0.0;
		self.progressBar.alpha = 1.0;
		self.spinner.alpha = 1.0;
		
		[UIView commitAnimations];
		
	} else {
		[self stopProgress];
		
		[UIView beginAnimations:nil context:NULL];
		
		self.label.alpha = 1.0;
		self.imageView.alpha = 1.0;
		self.progressBar.alpha = 0.0;
		self.spinner.alpha = 0.0;
		
		[UIView commitAnimations];
	}
}

@synthesize progress;
- (void) setProgress:(CGFloat) p;
{
	progress = p;
	[self updateProgress];
}

- (void) updateProgress;
{
	if (self.transferring && progress == kMvrPacketIndeterminateProgress) {
		[self.spinner startAnimating];
	} else {
		[self.spinner stopAnimating];
		self.progressBar.progress = progress;
	}
}

- (void) stopProgress;
{
	[self.spinner stopAnimating];
}

@end
