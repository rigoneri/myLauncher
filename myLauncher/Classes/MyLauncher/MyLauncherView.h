//
//  MyLauncherView.h
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

#import <UIKit/UIKit.h>
#import "MyLauncherItem.h"
#import "MyLauncherPageControl.h"
#import "MyLauncherScrollView.h"

@protocol MyLauncherViewDelegate <NSObject>
-(void)launcherViewItemSelected:(MyLauncherItem*)item;
-(void)launcherViewDidBeginEditing:(id)sender;
-(void)launcherViewDidEndEditing:(id)sender;
@end

@interface MyLauncherView : UIView <UIScrollViewDelegate, MyLauncherItemDelegate> {	
    UIDeviceOrientation currentOrientation;
	BOOL itemsAdded;
	BOOL editing;
	BOOL dragging;
    BOOL editingAllowed;
	NSInteger numberOfImmovableItems;
    
	int columnCount;
	int rowCount;
	CGFloat itemWidth;
	CGFloat itemHeight;
    CGFloat minX;
    CGFloat minY;
    CGFloat paddingX;
    CGFloat paddingY;
}

@property (nonatomic) BOOL editingAllowed;
@property (nonatomic) NSInteger numberOfImmovableItems;
@property (nonatomic, strong) id <MyLauncherViewDelegate> delegate;
@property (nonatomic, strong) MyLauncherScrollView *pagesScrollView;
@property (nonatomic, strong) MyLauncherPageControl *pageControl;
@property (nonatomic, strong) NSMutableArray *pages;

// Default for animation below is YES

-(void)setPages:(NSMutableArray *)pages animated:(BOOL)animated;
-(void)setPages:(NSMutableArray *)pages numberOfImmovableItems:(NSInteger)items;
-(void)setPages:(NSMutableArray *)pages numberOfImmovableItems:(NSInteger)items animated:(BOOL)animated;

-(void)viewDidAppear:(BOOL)animated;
-(void)setCurrentOrientation:(UIInterfaceOrientation)newOrientation;
-(void)layoutLauncher;
-(void)layoutLauncherAnimated:(BOOL)animated;
-(int)maxItemsPerPage;
-(int)maxPages;

@end
