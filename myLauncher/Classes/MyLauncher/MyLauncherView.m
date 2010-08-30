//
//  MyLauncherView.m
//  @rigoneri
//  
//  Copyright 2010 Rodrigo Neri
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

#import "MyLauncherView.h"

struct NItemLocation {
	NSInteger page; 
	NSInteger sindex; 
};
typedef struct NItemLocation NItemLocation;

static const int pControllHeight = 30;
static const int maxItemsPageCount = 9;
static const int maxPageCount = 6;

static const int portraitItemWidth = 106;
static const int portraitItemHeight = 106;
static const int portraitColumnCount = 3;
static const int portraitRowCount = 3;

static const int landscapeItemWidth = 96;
static const int landscapeItemHeight = 96;
static const int landscapeColumnCount = 5;
static const int landscapeRowCount = 2;

@interface MyLauncherView (hidden)
-(void)layoutItems;
-(void)beginEditing;
-(void)animateItems;
-(void)organizePages;
-(NItemLocation)itemLocation;
-(void)savePages;
-(void)saveToUserDefaults:(id)object key:(NSString *)key;
@end

@implementation MyLauncherView

@synthesize delegate, pagesScrollView, pageControl, pages;

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
	{
		dragging = NO;
		editing = NO;
		itemsAdded = NO;
		columnCount = portraitColumnCount;
		rowCount = portraitRowCount;
		itemWidth = portraitItemWidth;
		itemHeight = portraitItemHeight;
		
		pagesScrollView = [[MyLauncherScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height - pControllHeight)];
		pagesScrollView.delegate = self;
		pagesScrollView.pagingEnabled = YES;
		pagesScrollView.showsHorizontalScrollIndicator = NO;
		pagesScrollView.showsVerticalScrollIndicator = NO;
		pagesScrollView.alwaysBounceHorizontal = YES;
		pagesScrollView.scrollsToTop = NO;
		pagesScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		pagesScrollView.delaysContentTouches = YES;
		pagesScrollView.multipleTouchEnabled = NO;
		[self addSubview:pagesScrollView];
		
		pageControl = [[MyLauncherPageControl alloc] initWithFrame:CGRectMake(0, frame.size.height - pControllHeight - 45, frame.size.width, pControllHeight)]; //if starts landscape this will break...
		pageControl.numberOfPages = 1;
		pageControl.currentPage = 0;
		pageControl.backgroundColor = [UIColor clearColor];
		[pageControl addTarget:self action:@selector(pageChanged) forControlEvents:UIControlEventValueChanged];
		[self addSubview:pageControl];
    }
    return self;
}

-(void)pageChanged
{
	pagesScrollView.contentOffset = CGPointMake(pageControl.currentPage * pagesScrollView.frame.size.width, 0);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView 
{
	pageControl.currentPage = floor((pagesScrollView.contentOffset.x - pagesScrollView.frame.size.width / 2) / pagesScrollView.frame.size.width) + 1;
	
}

-(void)itemTouchedUpInside:(MyLauncherItem *)item
{
	if(editing)
	{
		dragging = NO;
		[draggingItem setDragging:NO];
		draggingItem = nil;
		pagesScrollView.scrollEnabled = YES;
		[UIView beginAnimations:nil context:nil];
		[UIView setAnimationDuration:0.3];
		[self layoutItems];
		[UIView commitAnimations];
	}
	else 
	{
		[movePagesTimer invalidate];
		movePagesTimer = nil;
		[itemHoldTimer invalidate];
		itemHoldTimer = nil;
		[[self delegate] launcherViewItemSelected:item];
		pagesScrollView.scrollEnabled = YES;
	}
}

-(void)itemTouchedUpOutside:(MyLauncherItem *)item
{
	[movePagesTimer invalidate];
	movePagesTimer = nil;
	[itemHoldTimer invalidate];
	itemHoldTimer = nil;
	dragging = NO;
	[draggingItem setDragging:NO];
	draggingItem = nil;
	pagesScrollView.scrollEnabled = YES;
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.3];
	[self layoutItems];
	[UIView commitAnimations];
}

-(void)itemTouchedDown:(MyLauncherItem *)item
{
	if(editing)
	{
		if(!draggingItem)
		{
			draggingItem = (MyLauncherItem*)item; 
			[draggingItem setDragging:YES];
			[pagesScrollView addSubview:draggingItem];
			dragging = YES;			
		}
	}
	else 
	{
		[itemHoldTimer invalidate];
		itemHoldTimer = nil;
	
		itemHoldTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(itemHoldTimer:) userInfo:item repeats:NO];
	}
}

-(void)itemHoldTimer:(NSTimer *)timer
{
	itemHoldTimer = nil;

	[self beginEditing];	
	
	draggingItem = (MyLauncherItem*)timer.userInfo; 
	draggingItem.selected = NO;
	draggingItem.highlighted = NO;
	
	[draggingItem setDragging:YES];
	[pagesScrollView addSubview:draggingItem];
	dragging = YES;
	pagesScrollView.scrollEnabled = NO;
}

-(void)organizePages
{
	int currentPageIndex = 0;
	for(NSMutableArray *page in pages)
	{
		if(page.count > maxItemsPageCount)
		{
			NSInteger nextPageIndex = currentPageIndex+1;
			NSMutableArray *nextPage = [pages objectAtIndex:nextPageIndex];
			if(nextPage)
			{
				MyLauncherItem *moveItem = [[page lastObject] retain];
				[page removeObject:moveItem];
				[nextPage insertObject:moveItem atIndex:0];
			}
			else
			{
				[pages addObject:[NSMutableArray array]];
				nextPage = [pages lastObject];
				MyLauncherItem *moveItem = [[page lastObject] retain];
				[page removeObject:moveItem];
				[nextPage addObject:moveItem];
			}
		}
		currentPageIndex++;
	}	
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesMoved:touches withEvent:event];
	
	if(dragging) 
	{
		for (UITouch* touch in touches) 
		{
			CGPoint location = [touch locationInView:self];
			draggingItem.center = CGPointMake(location.x + pagesScrollView.contentOffset.x, location.y);
			
			NItemLocation sItemLocation = [self itemLocation];
			NSInteger page = sItemLocation.page;
			NSInteger sindex = sItemLocation.sindex;
			
			CGFloat dragItemX = draggingItem.center.x - pagesScrollView.contentOffset.x;
			CGFloat dragItemY = draggingItem.center.y;
	
			NSInteger dragItemColumn = floor(dragItemX/itemWidth);
			NSInteger dragItemRow = floor(dragItemY/itemHeight);
			NSInteger dragIndex = (dragItemRow * columnCount) + dragItemColumn;
						
			if(sindex != dragIndex)
			{
				[[draggingItem retain] autorelease];
				NSMutableArray *itemPage = [pages objectAtIndex:page];
				[itemPage removeObjectAtIndex:sindex];
				
				NSInteger currentPageIndex = floor(pagesScrollView.contentOffset.x/pagesScrollView.frame.size.width);
				NSMutableArray *currentPage = [pages objectAtIndex:currentPageIndex];
				if(dragIndex > currentPage.count)
				{
					dragIndex = currentPage.count;
					[currentPage insertObject:draggingItem atIndex:dragIndex];
					[self organizePages];
				}
				else 
				{
					[currentPage insertObject:draggingItem atIndex:dragIndex];
					[self organizePages];
					[UIView beginAnimations:nil context:nil];
					[UIView setAnimationDuration:0.3];
					[self layoutItems];
					[UIView commitAnimations];
				}
			}
			
			//Moving Pages
			NSInteger currentPageIndex = floor(pagesScrollView.contentOffset.x/pagesScrollView.frame.size.width);
			
			if(location.x + pagesScrollView.contentOffset.x < pagesScrollView.contentOffset.x + 20)
			{
				if(currentPageIndex > 0)
				{
					if(!movePagesTimer)
						movePagesTimer = [NSTimer scheduledTimerWithTimeInterval:0.7
																		  target:self 
																		selector:@selector(movePagesTimer:) 
																		userInfo:@"left" 
																		 repeats:NO];
				}
			}
			else if(location.x + pagesScrollView.contentOffset.x > pagesScrollView.contentOffset.x + pagesScrollView.frame.size.width - 20)
			{
				if(!movePagesTimer)
					movePagesTimer = [NSTimer scheduledTimerWithTimeInterval:0.7
																	  target:self 
																	selector:@selector(movePagesTimer:) 
																	userInfo:@"right" 
																	 repeats:NO];
			}
			else
			{
				[movePagesTimer invalidate];
				movePagesTimer = nil;
			}
		}
	}
}

-(void)movePagesTimer:(NSTimer*)timer
{
	movePagesTimer = nil;
	
	if([(NSString*)timer.userInfo isEqualToString:@"right"])
	{	
		CGFloat newX = pagesScrollView.contentOffset.x + pagesScrollView.frame.size.width;
		
		NSInteger currentPageIndex = floor(newX/pagesScrollView.frame.size.width);
		if(currentPageIndex + 1 > pages.count)
		{
			if(pages.count <= maxPageCount)
			{
				[pages addObject:[NSMutableArray array]];
				pageControl.numberOfPages = pages.count;
			}
		}
		pageControl.currentPage = currentPageIndex;
		
		CGPoint offset = CGPointMake(newX, 0);
		[pagesScrollView setContentOffset:offset animated:YES];
		draggingItem.frame = CGRectMake(draggingItem.frame.origin.x + pagesScrollView.frame.size.width, 
										draggingItem.frame.origin.y, 
										draggingItem.frame.size.width, 
										draggingItem.frame.size.height);	
		
	}
	else if([(NSString*)timer.userInfo isEqualToString:@"left"])
	{
		NSInteger currentPageIndex = floor(pagesScrollView.contentOffset.x/pagesScrollView.frame.size.width);
		pageControl.currentPage = --currentPageIndex;
		CGFloat newX = pagesScrollView.contentOffset.x - pagesScrollView.frame.size.width;
		CGPoint offset = CGPointMake(newX, 0);
		[pagesScrollView setContentOffset:offset animated:YES];
		draggingItem.frame = CGRectMake(draggingItem.frame.origin.x - pagesScrollView.frame.size.width, 
										draggingItem.frame.origin.y, 
										draggingItem.frame.size.width, 
										draggingItem.frame.size.height);	
	}
}

-(void)beginEditing
{
	if(editing)
		return;
	
	editing = YES;
	
	if(pages.count <= 6)
	{
		[pages addObject:[NSMutableArray array]];
		pageControl.numberOfPages = pages.count;
		pagesScrollView.contentSize = CGSizeMake(pages.count*pagesScrollView.frame.size.width, pagesScrollView.frame.size.height);
	}
		
	[self animateItems];
	[[self delegate] launcherViewDidBeginEditing:self];
}

-(void)endEditing
{
	editing = NO;
	pagesScrollView.scrollEnabled = YES;
	
	for (int i = 0; i < pages.count; ++i) 
	{
		NSArray* itemPage = [pages objectAtIndex:i];
		if(itemPage.count == 0)
		{
			[pages removeObjectAtIndex:i];
			--i;
		}
		else 
		{
			for (MyLauncherItem* item in itemPage) 
				item.transform = CGAffineTransformIdentity;
		}
	}
	
	pageControl.numberOfPages = pages.count;
	pagesScrollView.contentSize = CGSizeMake(pagesScrollView.frame.size.width * pages.count, pagesScrollView.frame.size.height);
	
	[self layoutItems];
	[self savePages];
	[[self delegate] launcherViewDidEndEditing:self];
}

-(void)animateItems 
{
	static BOOL animatesLeft = NO;
	
	if (editing) 
	{
		CGAffineTransform animateUp = CGAffineTransformMakeScale(1.0, 1.0);
		CGAffineTransform animateDown = CGAffineTransformMakeScale(0.9, 0.9);
		
		[UIView beginAnimations:nil context:nil];
		
		NSInteger i = 0;
		NSInteger animatingItems = 0;
		for (NSArray* itemPage in pages) 
		{
			for (MyLauncherItem* item in itemPage) 
			{
				item.closeButton.hidden = !editing;
				if (item != draggingItem) 
				{
					++animatingItems;
					if (i % 2) 
						item.transform = animatesLeft ? animateDown : animateUp;
					else 
						item.transform = animatesLeft ? animateUp : animateDown;
				}
				++i;
			}
		}
		
		if (animatingItems >= 1) 
		{
			[UIView setAnimationDuration:0.05];
			[UIView setAnimationDelegate:self];
			[UIView setAnimationDidStopSelector:@selector(animateItems)];
			animatesLeft = !animatesLeft;
		} 
		else 
		{
			[NSObject cancelPreviousPerformRequestsWithTarget:self];
			[self performSelector:@selector(animateItems) withObject:nil afterDelay:0.05];
		}
		
		[UIView commitAnimations];
	}
}
					 
-(void)setPages:(NSMutableArray *)newPages
{
	if (pages != newPages) 
	{	
        [pages release];
        pages = [newPages mutableCopy];
    }
	
	[self layoutItems];
}

-(void)layoutLauncher
{
	pagesScrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - pControllHeight);
	pageControl.frame = CGRectMake(0, self.frame.size.height - pControllHeight, self.frame.size.width, pControllHeight);
	[pageControl setNeedsDisplay];

	[self layoutItems];
	[self pageChanged];
}

-(void)layoutItems
{	
	CGFloat pageWidth = pagesScrollView.frame.size.width;
	
	CGFloat padding = 0;
	CGFloat x = 0;
	CGFloat minX = 0;
	columnCount = portraitColumnCount;
	rowCount = portraitRowCount;
	itemWidth = portraitItemWidth;
	itemHeight = portraitItemHeight;
	
	if ([UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeLeft || [UIDevice currentDevice].orientation == UIDeviceOrientationLandscapeRight)
	{
		columnCount = landscapeColumnCount;
		rowCount = landscapeRowCount;
		itemWidth = landscapeItemWidth;
		itemHeight = landscapeItemHeight;
	}
	
	for (NSMutableArray *page in pages)
	{
		CGFloat y = 0;
		int itemsCount = 1;
		for (MyLauncherItem *item in page)
		{
			if(itemsAdded) 
			{
				CGRect prevFrame = CGRectMake(x, y, itemWidth, itemHeight);
			
				if(!item.dragging)
				{
					item.transform = CGAffineTransformIdentity;
					if(item.frame.origin.x != x || item.frame.origin.y != y)
						item.frame = prevFrame;
				}
			}
			else
			{
				item.frame = CGRectMake(x, y, itemWidth, itemHeight);
				item.delegate = self;
				[item layoutItem];
				[item addTarget:self action:@selector(itemTouchedUpInside:) forControlEvents:UIControlEventTouchUpInside];
				[item addTarget:self action:@selector(itemTouchedUpOutside:) forControlEvents:UIControlEventTouchUpOutside];
				[item addTarget:self action:@selector(itemTouchedDown:) forControlEvents:UIControlEventTouchDown];
				[pagesScrollView addSubview:item];
			}
			item.closeButton.hidden = editing ? NO : YES;
			x += itemWidth + padding;
			
			if ( itemsCount % columnCount == 0)
			{
				y += itemHeight + padding;
				x = minX;
			}
			
			itemsCount++;
		}
		
		minX += pageWidth;
		x = minX;
	}
	
	pageControl.numberOfPages = pages.count;
	pagesScrollView.contentSize = CGSizeMake(pagesScrollView.frame.size.width * pages.count, rowCount * itemHeight);
	
	itemsAdded = YES;
}

-(NItemLocation)itemLocation
{
	NItemLocation i;
	
	int itemPage = 0;
	for (NSMutableArray *page in pages)
	{
		int itemOrder = 0;
		for (MyLauncherItem *item in page)
		{
			if(item == draggingItem)
			{
				i.page = itemPage;
				i.sindex = itemOrder;
				return i;
			}
			itemOrder++;
		}
	
		itemPage++;
	}
	i.page = 0;
	i.sindex = 0;
	
	return i;
}

-(void)didDeleteItem:(id)item
{
	MyLauncherItem *ditem = (MyLauncherItem*)item;
	
	for (NSMutableArray *page in pages)
	{
		int i = 0;
		for (MyLauncherItem *aitem in page)
		{
			if(aitem == ditem)
			{
				[page removeObjectAtIndex:i];
				[UIView beginAnimations:nil context:nil];
				[UIView setAnimationDuration:0.3];
				[self layoutItems];
				[UIView commitAnimations];
				return;
			}
			i++;
		}
	}
}

-(void)savePages
{
	NSMutableArray *pagesToSave = [[NSMutableArray alloc] init];
	
	for(NSArray *page in pages)
	{
		NSMutableArray *pageToSave = [[NSMutableArray alloc] init];
		
		for(MyLauncherItem *item in page)
		{
			NSMutableDictionary *itemToSave = [[NSMutableDictionary alloc] init];
			[itemToSave setObject:item.title forKey:@"title"];
			[itemToSave setObject:item.image forKey:@"image"];
			[itemToSave setObject:[NSString stringWithFormat:@"%d", [item deletable]] forKey:@"deletable"];
			[itemToSave setObject:item.controllerStr forKey:@"controller"];
			
			[pageToSave addObject:itemToSave];
			[itemToSave release];
		}
		[pagesToSave addObject:pageToSave];
		[pageToSave release];
	}
	
	[self saveToUserDefaults:pagesToSave key:@"myLauncherView"];
	
	[pagesToSave release];
}

-(void)saveToUserDefaults:(id)object key:(NSString *)key
{
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	
	if (standardUserDefaults) 
	{
		[standardUserDefaults setObject:object forKey:key];
		[standardUserDefaults synchronize];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return YES;
}

- (void)dealloc 
{
	[pagesScrollView release];
	[pageControl release];
	[pages release];
	
    [super dealloc];
}


@end
