//
//  MyLauncherView.m
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

#import "MyLauncherView.h"

struct NItemLocation {
	NSInteger page; 
	NSInteger sindex; 
};
typedef struct NItemLocation NItemLocation;

static const int pControllHeight = 30;
static const int maxPageCount = 6;

/* iPhone */
static const int maxItemsPageCount = 9;

static const int portraitItemWidth = 106;
static const int portraitItemHeight = 106;
static const int portraitColumnCount = 3;
static const int portraitRowCount = 3;
static const CGFloat portraitItemXStart = 0;
static const CGFloat portraitItemYStart = 0;
static const CGFloat portraitXPadding = 0;
static const CGFloat portraitYPadding = 0;

static const int landscapeItemWidth = 96;
static const int landscapeItemHeight = 96;
static const int landscapeColumnCount = 5;
static const int landscapeRowCount = 2;
static const CGFloat landscapeItemXStart = 0;
static const CGFloat landscapeItemYStart = 0;
static const CGFloat landscapeXPadding = 0;
static const CGFloat landscapeYPadding = 0;

/* iPad */
static const int iPadMaxItemsPageCount = 20;

static const int iPadPortraitItemWidth = 122;
static const int iPadPortraitItemHeight = 122;
static const int iPadPortraitColumnCount = 4;
static const int iPadPortraitRowCount = 5;
static const CGFloat iPadPortraitItemXStart = 58;
static const CGFloat iPadPortraitItemYStart = 30;
static const CGFloat iPadPortraitXPadding = 50;
static const CGFloat iPadPortraitYPadding = 50;

static const int iPadLandscapeItemWidth = 112;
static const int iPadLandscapeItemHeight = 112;
static const int iPadLandscapeColumnCount = 5;
static const int iPadLandscapeRowCount = 4;
static const CGFloat iPadLandscapeItemXStart = 58;
static const CGFloat iPadLandscapeItemYStart = 30;
static const CGFloat iPadLandscapeXPadding = 80;
static const CGFloat iPadLandscapeYPadding = 30;

@interface MyLauncherView ()
-(void)setupCurrentViewLayoutSettings;
-(void)layoutItems;
-(void)beginEditing;
-(void)animateItems;
-(void)organizePages;
-(NItemLocation)itemLocation;
-(BOOL)itemMovable:(MyLauncherItem *)itemToSearch;
-(void)savePages;
-(void)saveToUserDefaults:(id)object key:(NSString *)key;
-(UIDeviceOrientation)currentLayoutOrientation;
@property (nonatomic, retain) NSTimer *itemHoldTimer;
@property (nonatomic, retain) NSTimer *movePagesTimer;
@property (nonatomic, retain) MyLauncherItem *draggingItem;
@end

@implementation MyLauncherView

@synthesize editingAllowed, numberOfImmovableItems;
@synthesize delegate = _delegate;
@synthesize pagesScrollView = _pageScrollView;
@synthesize pageControl = _pageControl;
@synthesize pages = _pages;
@synthesize itemHoldTimer = _itemHoldTimer;
@synthesize movePagesTimer = _movePagesTimer;
@synthesize draggingItem = _draggingItem;

#pragma mark - View lifecycle

- (id)initWithFrame:(CGRect)frame 
{
    if ((self = [super initWithFrame:frame])) 
	{
		dragging = NO;
		editing = NO;
		itemsAdded = NO;
        editingAllowed = YES;
        numberOfImmovableItems = -1;
		[self setupCurrentViewLayoutSettings];
		
		[self setPagesScrollView:[[MyLauncherScrollView alloc] initWithFrame:CGRectMake(0, 0, frame.size.width, frame.size.height - pControllHeight)]];
		self.pagesScrollView.delegate = self;
		self.pagesScrollView.pagingEnabled = YES;
		self.pagesScrollView.showsHorizontalScrollIndicator = NO;
		self.pagesScrollView.showsVerticalScrollIndicator = NO;
		self.pagesScrollView.alwaysBounceHorizontal = YES;
		self.pagesScrollView.scrollsToTop = NO;
		self.pagesScrollView.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
		self.pagesScrollView.delaysContentTouches = YES;
		self.pagesScrollView.multipleTouchEnabled = NO;
		[self addSubview:self.pagesScrollView];
		
		[self setPageControl:[[MyLauncherPageControl alloc] initWithFrame:CGRectMake(0, frame.size.height - pControllHeight - 45, frame.size.width, pControllHeight)]]; //if starts landscape this will break...
		self.pageControl.numberOfPages = 1;
		self.pageControl.currentPage = 0;
        self.pageControl.maxNumberOfPages = maxPageCount;
		self.pageControl.backgroundColor = [UIColor clearColor];
		[self.pageControl addTarget:self action:@selector(pageChanged) forControlEvents:UIControlEventValueChanged];
		[self addSubview:self.pageControl];
        
        [self addObserver:self forKeyPath:@"frame" options:0 context:nil];
    }
    return self;
}

-(void)viewDidAppear:(BOOL)animated
{
    [self layoutItems];
}

- (void)dealloc
{
    [self removeObserver:self forKeyPath:@"frame"];
}

#pragma mark - Setters

-(void)setPages:(NSMutableArray *)pages {
    [self setPages:pages animated:YES];
}

-(void)setPages:(NSMutableArray *)pages animated:(BOOL)animated {
    if (pages != _pages) {
        if (_pages) {
            for (NSArray *page in _pages) {
                for (UIView *item in page) {
                    [item removeFromSuperview];
                }
            }
        }
        
        _pages = pages;
        itemsAdded = NO;
        [self layoutLauncherAnimated:animated];
    }
}

-(void)setPages:(NSMutableArray *)pages numberOfImmovableItems:(NSInteger)items {
    [self setPages:pages numberOfImmovableItems:items animated:YES];
}

-(void)setPages:(NSMutableArray *)pages numberOfImmovableItems:(NSInteger)items animated:(BOOL)animated {
    [self setPages:pages animated:animated];
    [self setNumberOfImmovableItems:items];
}

#pragma mark - View Orientation

- (void)setCurrentOrientation:(UIInterfaceOrientation)newOrientation {
    if (newOrientation != currentOrientation && 
        newOrientation != UIDeviceOrientationUnknown && 
        newOrientation != UIDeviceOrientationFaceUp && 
        newOrientation != UIDeviceOrientationFaceDown) {
        currentOrientation = (UIDeviceOrientation)newOrientation;
    }
}

- (UIDeviceOrientation)currentLayoutOrientation {
    UIDeviceOrientation deviceOrientation = [UIDevice currentDevice].orientation;
    [self setCurrentOrientation:(UIInterfaceOrientation)deviceOrientation];
    return currentOrientation;
}

#pragma mark - ScrollView and PageControl Management

- (void)pageChanged
{
	self.pagesScrollView.contentOffset = CGPointMake(self.pageControl.currentPage * self.pagesScrollView.frame.size.width, 0);
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView 
{
	self.pageControl.currentPage = floor((self.pagesScrollView.contentOffset.x - self.pagesScrollView.frame.size.width / 2) / 
                                         self.pagesScrollView.frame.size.width) + 1;
	
}

- (void)updateFrames
{
    self.pagesScrollView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height - pControllHeight);
	self.pageControl.frame = CGRectMake(0, self.frame.size.height - pControllHeight, self.frame.size.width, pControllHeight);
	[self.pageControl setNeedsDisplay];
}

-(void)didChangeValueForKey:(NSString *)key {
    if ([key isEqualToString:@"frame"]) {
        [self updateFrames];
    }
}

#pragma mark - Layout Settings

-(int)maxItemsPerPage {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return iPadMaxItemsPageCount;
    }
    return maxItemsPageCount;
}

-(int)maxPages {
    return maxPageCount;
}

-(void)setupCurrentViewLayoutSettings {    
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        if (UIDeviceOrientationIsLandscape([self currentLayoutOrientation])) {
            minX = iPadLandscapeItemXStart;
            minY = iPadLandscapeItemYStart;
            paddingX = iPadLandscapeXPadding;
            paddingY = iPadLandscapeYPadding;
            columnCount = iPadLandscapeColumnCount;
            rowCount = iPadLandscapeRowCount;
            itemWidth = iPadLandscapeItemWidth;
            itemHeight = iPadLandscapeItemHeight;
        } else {
            minX = iPadPortraitItemXStart;
            minY = iPadPortraitItemYStart;
            paddingX = iPadPortraitXPadding;
            paddingY = iPadPortraitYPadding;
            columnCount = iPadPortraitColumnCount;
            rowCount = iPadPortraitRowCount;
            itemWidth = iPadPortraitItemWidth;
            itemHeight = iPadPortraitItemHeight;
        }
        
    } else {
        if (UIDeviceOrientationIsLandscape([self currentLayoutOrientation]))
        {
            minX = landscapeItemXStart;
            minY = landscapeItemYStart;
            paddingX = landscapeXPadding;
            paddingY = landscapeYPadding;
            columnCount = landscapeColumnCount;
            rowCount = landscapeRowCount;
            itemWidth = landscapeItemWidth;
            itemHeight = landscapeItemHeight;
        } else {
            minX = portraitItemXStart;
            minY = portraitItemYStart;
            paddingX = portraitXPadding;
            paddingY = portraitYPadding;
            columnCount = portraitColumnCount;
            rowCount = portraitRowCount;
            itemWidth = portraitItemWidth;
            itemHeight = portraitItemHeight;
        }
    }
}

#pragma mark - Layout Management

-(void)layoutLauncher
{
	[self layoutLauncherAnimated:YES];
}

-(void)layoutLauncherAnimated:(BOOL)animated
{
    [self updateFrames];
    
    [UIView animateWithDuration:animated ? 0.3 : 0
                     animations:^{
                         [self layoutItems];
                     }];
    
	[self pageChanged];
}

-(void)layoutItems
{
	CGFloat pageWidth = self.pagesScrollView.frame.size.width;
	
    [self setupCurrentViewLayoutSettings];
    
	for (NSMutableArray *page in self.pages)
	{
        CGFloat x = minX;
        CGFloat y = minY;
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
                [item addTarget:self action:@selector(itemTouchCancelled:) forControlEvents:UIControlEventTouchCancel];
				[self.pagesScrollView addSubview:item];
			}
			item.closeButton.hidden = editing ? NO : YES;
			x += itemWidth + paddingX;
			
			if ( itemsCount % columnCount == 0)
			{
				y += itemHeight + paddingY;
				x = minX;
			}
			
			itemsCount++;
		}
		
		minX += pageWidth;
	}
	
	self.pageControl.numberOfPages = self.pages.count;
	self.pagesScrollView.contentSize = CGSizeMake(self.pagesScrollView.frame.size.width * self.pages.count, 
                                                  rowCount * itemHeight);
	
	itemsAdded = YES;
}

-(void)organizePages
{
	int currentPageIndex = 0;
	for(NSMutableArray *page in self.pages)
	{
        int imaxItemsPageCount = [[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad ? iPadMaxItemsPageCount : maxItemsPageCount;
		if(page.count > imaxItemsPageCount)
		{
			NSInteger nextPageIndex = currentPageIndex+1;
			NSMutableArray *nextPage = [self.pages objectAtIndex:nextPageIndex];
			if(nextPage)
			{
				MyLauncherItem *moveItem = [page lastObject];
				[page removeObject:moveItem];
				[nextPage insertObject:moveItem atIndex:0];
                moveItem = nil;
			}
			else
			{
				[self.pages addObject:[NSMutableArray array]];
				nextPage = [self.pages lastObject];
				MyLauncherItem *moveItem = [page lastObject];
				[page removeObject:moveItem];
				[nextPage addObject:moveItem];
                moveItem = nil;
			}
		}
		currentPageIndex++;
	}	
}

#pragma mark - Touch Management

-(void)itemTouchedUpInside:(MyLauncherItem *)item
{
	if(editing)
	{
		dragging = NO;
		[self.draggingItem setDragging:NO];
		self.draggingItem = nil;
		self.pagesScrollView.scrollEnabled = YES;
		[UIView animateWithDuration:0.3 
                         animations:^{
                             [self layoutItems]; 
                         }];
	}
	else 
	{
		[self.movePagesTimer invalidate];
		self.movePagesTimer = nil;
		[self.itemHoldTimer invalidate];
		self.itemHoldTimer = nil;
		[[self delegate] launcherViewItemSelected:item];
		self.pagesScrollView.scrollEnabled = YES;
	}
}

-(void)itemTouchedUpOutside:(MyLauncherItem *)item
{
	[self.movePagesTimer invalidate];
	self.movePagesTimer = nil;
	[self.itemHoldTimer invalidate];
	self.itemHoldTimer = nil;
	dragging = NO;
	[self.draggingItem setDragging:NO];
	self.draggingItem = nil;
	self.pagesScrollView.scrollEnabled = YES;
	[UIView animateWithDuration:0.3 
                     animations:^{
                         [self layoutItems]; 
                     }];
}

-(void)itemTouchedDown:(MyLauncherItem *)item
{
	if (editing)
	{
		if (!self.draggingItem && [self itemMovable:item])
		{
			self.draggingItem = (MyLauncherItem*)item; 
			[self.draggingItem setDragging:YES];
			[self.pagesScrollView addSubview:self.draggingItem];
			dragging = YES;			
		}
	}
	else if (editingAllowed)
	{
		[self.itemHoldTimer invalidate];
		self.itemHoldTimer = nil;
        
		self.itemHoldTimer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(itemHoldTimer:) userInfo:item repeats:NO];
	}
}

-(void)itemTouchCancelled:(MyLauncherItem *)item
{
    if (editing) {
        [self itemTouchedUpInside:item];
    } else {
        [self itemTouchedUpOutside:item];
    }
}

-(void)itemHoldTimer:(NSTimer *)timer
{
	self.itemHoldTimer = nil;
    
	[self beginEditing];	
	
    MyLauncherItem *heldItem = (MyLauncherItem*)timer.userInfo;
    if ([self itemMovable:heldItem]) {
        self.draggingItem = heldItem; 
        [self.draggingItem setSelected:NO];
        [self.draggingItem setHighlighted:NO];
        [self.draggingItem setDragging:YES];
        
        [self.pagesScrollView addSubview:self.draggingItem];
        dragging = YES;
    }
    self.pagesScrollView.scrollEnabled = NO;
}

-(void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event
{
	[super touchesMoved:touches withEvent:event];
	
	if(dragging) 
	{
		for (UITouch* touch in touches) 
		{
			CGPoint location = [touch locationInView:self];
			self.draggingItem.center = CGPointMake(location.x + self.pagesScrollView.contentOffset.x, location.y);
            [self setupCurrentViewLayoutSettings];
			
			NItemLocation sItemLocation = [self itemLocation];
			NSInteger page = sItemLocation.page;
			NSInteger sindex = sItemLocation.sindex;
			
			CGFloat dragItemX = self.draggingItem.center.x - self.pagesScrollView.contentOffset.x;
			CGFloat dragItemY = self.draggingItem.center.y;
            CGFloat distanceWidth = itemWidth + paddingX;
            CGFloat distanceHeight = itemHeight + paddingY;
            
			NSInteger dragItemColumn = floor(dragItemX/distanceWidth); // item width
			NSInteger dragItemRow = floor(dragItemY/distanceHeight); // item height
			NSInteger dragIndex = (dragItemRow * columnCount) + dragItemColumn;
            NSInteger currentPageIndex = floor(self.pagesScrollView.contentOffset.x/self.pagesScrollView.frame.size.width);
            
            NSMutableArray *itemPage = [self.pages objectAtIndex:page];
            if(currentPageIndex != page && dragIndex >= [itemPage count])
            {
                dragIndex = 0;
            }
            
			if(sindex != dragIndex || (dragIndex == 0 && [itemPage count] == 1 && currentPageIndex != page))
			{
                if (dragIndex < [itemPage count])
                {
                    MyLauncherItem *itemToMove = [itemPage objectAtIndex:dragIndex];
                    if ([self itemMovable:itemToMove]) {
                        [itemPage removeObjectAtIndex:sindex];
                        
                        NSMutableArray *currentPage = [self.pages objectAtIndex:currentPageIndex];
                        if(dragIndex > currentPage.count)
                        {
                            dragIndex = currentPage.count;
                            [currentPage insertObject:self.draggingItem atIndex:dragIndex];
                            [self organizePages];
                        }
                        else 
                        {
                            [currentPage insertObject:self.draggingItem atIndex:dragIndex];
                            [self organizePages];
                            [UIView animateWithDuration:0.3 
                                             animations:^{
                                                 [self layoutItems]; 
                                             }];
                        }
                    }
                }
			}
			
			//Moving Pages
			if(location.x + self.pagesScrollView.contentOffset.x < self.pagesScrollView.contentOffset.x + 20)
			{
				if(currentPageIndex > 0)
				{
					if(!self.movePagesTimer)
						[self setMovePagesTimer:[NSTimer scheduledTimerWithTimeInterval:0.7
                                                                                 target:self 
                                                                               selector:@selector(movePagesTimer:) 
                                                                               userInfo:@"left" 
                                                                                repeats:NO]];
				}
			}
			else if(location.x + self.pagesScrollView.contentOffset.x > self.pagesScrollView.contentOffset.x + self.pagesScrollView.frame.size.width - 20)
			{
				if(!self.movePagesTimer)
					[self setMovePagesTimer:[NSTimer scheduledTimerWithTimeInterval:0.7
                                                                             target:self 
                                                                           selector:@selector(movePagesTimer:) 
                                                                           userInfo:@"right" 
                                                                            repeats:NO]];
			}
			else
			{
				[self.movePagesTimer invalidate];
				self.movePagesTimer = nil;
			}
		}
	}
}

-(void)movePagesTimer:(NSTimer*)timer
{
	self.movePagesTimer = nil;
	
	if([(NSString*)timer.userInfo isEqualToString:@"right"])
	{	
		CGFloat newX = self.pagesScrollView.contentOffset.x + self.pagesScrollView.frame.size.width;
		
		NSInteger currentPageIndex = floor(newX/self.pagesScrollView.frame.size.width);
		if(currentPageIndex + 1 > self.pages.count)
		{
			if(self.pages.count <= maxPageCount)
			{
				[self.pages addObject:[NSMutableArray array]];
				self.pageControl.numberOfPages = self.pages.count;
			}
		}
		self.pageControl.currentPage = currentPageIndex;
		
		CGPoint offset = CGPointMake(newX, 0);
        [UIView animateWithDuration:0.3 animations:^{
            [self.pagesScrollView setContentOffset:offset]; 
            self.draggingItem.frame = CGRectMake(self.draggingItem.frame.origin.x + self.pagesScrollView.frame.size.width, 
                                                 self.draggingItem.frame.origin.y, 
                                                 self.draggingItem.frame.size.width, 
                                                 self.draggingItem.frame.size.height);
        }];	
	}
	else if([(NSString*)timer.userInfo isEqualToString:@"left"])
	{
		NSInteger currentPageIndex = floor(self.pagesScrollView.contentOffset.x/self.pagesScrollView.frame.size.width);
		self.pageControl.currentPage = --currentPageIndex;
		CGFloat newX = self.pagesScrollView.contentOffset.x - self.pagesScrollView.frame.size.width;
		CGPoint offset = CGPointMake(newX, 0);
        [UIView animateWithDuration:0.3 animations:^{
            [self.pagesScrollView setContentOffset:offset];
            self.draggingItem.frame = CGRectMake(self.draggingItem.frame.origin.x - self.pagesScrollView.frame.size.width, 
                                                 self.draggingItem.frame.origin.y, 
                                                 self.draggingItem.frame.size.width, 
                                                 self.draggingItem.frame.size.height);
        }];
	}
}

-(NItemLocation)itemLocation
{
	NItemLocation i;
	
	int itemPage = 0;
	for (NSMutableArray *page in self.pages)
	{
		int itemOrder = 0;
		for (MyLauncherItem *item in page)
		{
			if(item == self.draggingItem)
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

#pragma mark -
#pragma mark Editing Management

-(void)beginEditing
{
	if(editing)
		return;
	
	editing = YES;
	
	if(self.pages.count <= maxPageCount)
	{
		[self.pages addObject:[NSMutableArray array]];
		self.pageControl.numberOfPages = self.pages.count;
		self.pagesScrollView.contentSize = CGSizeMake(self.pages.count*self.pagesScrollView.frame.size.width, 
                                                      self.pagesScrollView.frame.size.height);
	}
    
	[self animateItems];
	[[self delegate] launcherViewDidBeginEditing:self];
}

-(void)endEditing
{
	editing = NO;
	self.pagesScrollView.scrollEnabled = YES;
	
	for (int i = 0; i < self.pages.count; ++i) 
	{
		NSArray* itemPage = [self.pages objectAtIndex:i];
		if(itemPage.count == 0)
		{
			[self.pages removeObjectAtIndex:i];
			--i;
		}
		else 
		{
			for (MyLauncherItem* item in itemPage) 
				item.transform = CGAffineTransformIdentity;
		}
	}
	
	self.pageControl.numberOfPages = self.pages.count;
	self.pagesScrollView.contentSize = CGSizeMake(self.pagesScrollView.frame.size.width * self.pages.count, 
                                                  self.pagesScrollView.frame.size.height);
	
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
		for (NSArray* itemPage in self.pages) 
		{
			for (MyLauncherItem* item in itemPage) 
			{
				item.closeButton.hidden = !editing;
				if (item != self.draggingItem && [self itemMovable:item]) 
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

-(void)didDeleteItem:(id)item
{
	MyLauncherItem *ditem = (MyLauncherItem*)item;
	
	for (NSMutableArray *page in self.pages)
	{
		int i = 0;
		for (MyLauncherItem *aitem in page)
		{
			if(aitem == ditem)
			{
                if (i < numberOfImmovableItems)
                    numberOfImmovableItems--;
				[page removeObjectAtIndex:i];
                [UIView animateWithDuration:0.3 
                                 animations:^{
                                     [self layoutItems]; 
                                 }];
				return;
			}
			i++;
		}
	}
}

-(BOOL)itemMovable:(MyLauncherItem *)itemToSearch
{
    int count = 0;
    for (NSMutableArray *page in self.pages) {
        if ([page containsObject:itemToSearch]) {
            count = count + [page indexOfObject:itemToSearch];
            if (count >= numberOfImmovableItems) {
                break;
            }
            return NO;
        } else {
            count = count + [page count];
            if (count >= numberOfImmovableItems) {
                break;
            } if ([page count] < maxItemsPageCount) {
                numberOfImmovableItems = [page count];
                break;
            }
        }
    }
    return YES;
}

#pragma mark - myLauncher caching

-(void)savePages
{
	NSMutableArray *pagesToSave = [[NSMutableArray alloc] init];
	
	for(NSArray *page in self.pages)
	{
		NSMutableArray *pageToSave = [[NSMutableArray alloc] init];
		
		for(MyLauncherItem *item in page)
		{
			NSMutableDictionary *itemToSave = [[NSMutableDictionary alloc] init];
			[itemToSave setObject:item.title forKey:@"title"];
			[itemToSave setObject:item.image forKey:@"image"];
            [itemToSave setObject:item.iPadImage forKey:@"iPadImage"];
			[itemToSave setObject:[NSString stringWithFormat:@"%d", [item deletable]] forKey:@"deletable"];
			[itemToSave setObject:item.controllerStr forKey:@"controller"];
            [itemToSave setObject:item.controllerTitle forKey:@"controllerTitle"];
            [itemToSave setObject:[NSNumber numberWithInt:2] forKey:@"myLauncherViewItemVersion"];
			
			[pageToSave addObject:itemToSave];
		}
		[pagesToSave addObject:pageToSave];
	}
	
	[self saveToUserDefaults:pagesToSave key:@"myLauncherView"];
    [self saveToUserDefaults:[NSNumber numberWithInt:numberOfImmovableItems] key:@"myLauncherViewImmovable"];
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

@end
