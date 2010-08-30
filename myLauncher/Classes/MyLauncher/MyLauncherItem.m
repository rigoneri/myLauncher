//
//  MyLauncherItem.m
//  NMainMenu
//
//  Created by Rodrigo Neri on 8/1/10.
//  @rigoneri
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
@implementation MyLauncherItem

@synthesize delegate, targetController, title, image, closeButton, controllerStr;

-(id)initWithTitle:(NSString *)_title image:(NSString *)_image target:(NSString *)_controllerStr deletable:(BOOL)_deletable
{
	if((self = [super init]))
	{ 
		dragging = NO;
		deletable = _deletable;
		
		title = _title;
		image = _image;
		controllerStr = _controllerStr;
		
		AppDelegate *appDelegate = [[UIApplication sharedApplication] delegate];
		targetController = [appDelegate.appControllers objectForKey:controllerStr];		
		
		closeButton = [[UIButton alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
		closeButton.hidden = YES;
	}
	return self;
}

-(void)setFrame:(CGRect)frame
{
	[super setFrame:frame];
}

-(void)layoutItem
{
	if(!image)
		return;
	
	for(id subview in [self subviews]) 
		[subview removeFromSuperview];
	
	UIImageView *itemImage = [[UIImageView alloc] initWithImage:[UIImage imageNamed:image]];
	CGFloat itemImageX = (self.bounds.size.width/2) - (itemImage.bounds.size.width/2);
	CGFloat itemImageY = (self.bounds.size.height/2) - (itemImage.bounds.size.height/2);
	itemImage.frame = CGRectMake(itemImageX, itemImageY, itemImage.bounds.size.width, itemImage.bounds.size.height);
	[self addSubview:itemImage];
	[itemImage release];
	
	if(deletable)
	{
		closeButton.frame = CGRectMake(itemImageX-10, itemImageY-10, 30, 30);
		[closeButton setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
		closeButton.backgroundColor = [UIColor clearColor];
		[closeButton addTarget:self action:@selector(closeItem:) forControlEvents:UIControlEventTouchUpInside];
		[self addSubview:closeButton];
	}
	
	CGFloat itemLabelY = itemImageY + itemImage.bounds.size.height;
	CGFloat itemLabelHeight = self.bounds.size.height - itemLabelY;
	
	UILabel *itemLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, itemLabelY, self.bounds.size.width, itemLabelHeight)];
	itemLabel.backgroundColor = [UIColor clearColor];
	itemLabel.font = [UIFont boldSystemFontOfSize:11];
	itemLabel.textColor = COLOR(46, 46, 46);
	itemLabel.textAlignment = UITextAlignmentCenter;
	itemLabel.lineBreakMode = UILineBreakModeTailTruncation;
	itemLabel.text = title;
	itemLabel.numberOfLines = 2;
	[self addSubview:itemLabel];
	[itemLabel release];
}

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

- (void)dealloc 
{
	[closeButton release];
	[super dealloc];
}

@end
