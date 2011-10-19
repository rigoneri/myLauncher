//
//  MyLauncherItem.m
//  @rigoneri
//
//  Copyright 2010 Rodrigo Neri
//  Copyright 2011 David Jarrett
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//    http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.
//

#import "MyLauncherItem.h"
#import "CustomBadge.h"

@implementation MyLauncherItem

@synthesize delegate = _delegate;
@synthesize title = _title;
@synthesize image = _image;
@synthesize iPadImage = _iPadImage;
@synthesize closeButton = _closeButton;
@synthesize controllerStr = _controllerStr;
@synthesize controllerTitle = _controllerTitle;
@synthesize badge = _badge;

#pragma mark - Lifecycle

-(id)initWithTitle:(NSString *)title image:(NSString *)image target:(NSString *)targetControllerStr deletable:(BOOL)_deletable {
	return [self initWithTitle:title 
                   iPhoneImage:image 
                     iPadImage:image 
                        target:targetControllerStr 
                   targetTitle:title 
                     deletable:_deletable];
}

-(id)initWithTitle:(NSString *)title iPhoneImage:(NSString *)image iPadImage:(NSString *)iPadImage target:(NSString *)targetControllerStr targetTitle:(NSString *)targetTitle deletable:(BOOL)_deletable {
    
    if((self = [super init]))
	{ 
		dragging = NO;
		deletable = _deletable;
		
		[self setTitle:title];
		[self setImage:image];
        [self setIPadImage:iPadImage];
		[self setControllerStr:targetControllerStr];
        [self setControllerTitle:targetTitle];
		
		[self setCloseButton:[[UIButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)]];
		self.closeButton.hidden = YES;
	}
	return self;
}

#pragma mark - Layout

-(void)layoutItem
{
	if(!self.image)
		return;
	
	for(id subview in [self subviews]) 
		[subview removeFromSuperview];
	
    UIImage *image = nil;
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad && [self iPadImage]) {
        image = [UIImage imageNamed:self.iPadImage];
    } else {
        image = [UIImage imageNamed:self.image];
    }
    
	UIImageView *itemImage = [[UIImageView alloc] initWithImage:image];
	CGFloat itemImageX = (self.bounds.size.width/2) - (itemImage.bounds.size.width/2);
	CGFloat itemImageY = (self.bounds.size.height/2) - (itemImage.bounds.size.height/2);
	itemImage.frame = CGRectMake(itemImageX, itemImageY, itemImage.bounds.size.width, itemImage.bounds.size.height);
	[self addSubview:itemImage];
    CGFloat itemImageWidth = itemImage.bounds.size.width;

    if(self.badge) {
        self.badge.frame = CGRectMake((itemImageX + itemImageWidth) - (self.badge.bounds.size.width - 6), 
                                      itemImageY-6, self.badge.bounds.size.width, self.badge.bounds.size.height);
        [self addSubview:self.badge];
    }
	
	if(deletable)
	{
		self.closeButton.frame = CGRectMake(itemImageX-10, itemImageY-10, 30, 30);
		[self.closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
		self.closeButton.backgroundColor = [UIColor clearColor];
		[self.closeButton addTarget:self action:@selector(closeItem:) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:self.closeButton];
	}
	
	CGFloat itemLabelY = itemImageY + itemImage.bounds.size.height;
	CGFloat itemLabelHeight = self.bounds.size.height - itemLabelY;
	
	UILabel *itemLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, itemLabelY, self.bounds.size.width, itemLabelHeight)];
	itemLabel.backgroundColor = [UIColor clearColor];
	itemLabel.font = [UIFont boldSystemFontOfSize:11];
	itemLabel.textColor = COLOR(46, 46, 46);
	itemLabel.textAlignment = UITextAlignmentCenter;
	itemLabel.lineBreakMode = UILineBreakModeTailTruncation;
	itemLabel.text = self.title;
	itemLabel.numberOfLines = 2;
	[self addSubview:itemLabel];
}

#pragma mark - Touch

-(void)closeItem:(id)sender
{
	[UIView animateWithDuration:0.1 
						  delay:0 
						options:UIViewAnimationOptionCurveEaseIn 
					 animations:^{	
						 self.alpha = 0;
						 self.transform = CGAffineTransformMakeScale(0.00001, 0.00001);
					 }
					 completion:nil];
	
	[[self delegate] didDeleteItem:self];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent *)event 
{
	[super touchesBegan:touches withEvent:event];
	[[self nextResponder] touchesBegan:touches withEvent:event];
}

- (void)touchesMoved:(NSSet*)touches withEvent:(UIEvent *)event 
{
	[super touchesMoved:touches withEvent:event];
	[[self nextResponder] touchesMoved:touches withEvent:event];
}

- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent *)event 
{
	[super touchesEnded:touches withEvent:event];
	[[self nextResponder] touchesEnded:touches withEvent:event];
}

#pragma mark - Setters and Getters

-(void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
}

-(void)setDragging:(BOOL)flag
{
	if(dragging == flag)
		return;
	
	dragging = flag;
	
	[UIView animateWithDuration:0.1
						  delay:0 
						options:UIViewAnimationOptionCurveEaseIn 
					 animations:^{
						 if(dragging) {
							 self.transform = CGAffineTransformMakeScale(1.4, 1.4);
							 self.alpha = 0.7;
						 }
						 else {
							 self.transform = CGAffineTransformIdentity;
							 self.alpha = 1;
						 }
					 }
					 completion:nil];
}

-(BOOL)dragging
{
	return dragging;
}

-(BOOL)deletable
{
	return deletable;
}

-(NSString *)badgeText {
    return self.badge.badgeText;
}

-(void)setBadgeText:(NSString *)text {
    if (text && [text length] > 0) {
        [self setBadge:[CustomBadge customBadgeWithString:text]];
    } else {
        [self setBadge:nil];
    }
    [self layoutItem];
}

-(void)setCustomBadge:(CustomBadge *)customBadge {
    [self setBadge:customBadge];
    [self layoutItem];
}

@end
