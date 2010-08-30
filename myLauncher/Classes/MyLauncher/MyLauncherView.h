//
//  MyLauncherView.h
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

#import <UIKit/UIKit.h>
#import "MyLauncherItem.h"
#import "MyLauncherPageControl.h"
#import "MyLauncherScrollView.h"

@protocol MyLauncherViewDelegate <NSObject>
-(void)launcherViewItemSelected:(MyLauncherItem*)item;
-(void)launcherViewDidBeginEditing:(id)sender;
-(void)launcherViewDidEndEditing:(id)sender;
@end

@interface MyLauncherView : UIView <UIScrollViewDelegate, MyLauncherItemDelegate>
{
	id <MyLauncherViewDelegate> delegate;
	MyLauncherScrollView *pagesScrollView;
	MyLauncherPageControl *pageControl;
	
	NSMutableArray *pages;
	NSTimer *itemHoldTimer;
	NSTimer *movePagesTimer;
	
	BOOL itemsAdded;
	BOOL editing;
	BOOL dragging;
	MyLauncherItem *draggingItem;
	
	int columnCount;
	int rowCount;
	CGFloat itemWidth;
	CGFloat itemHeight;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic, assign) MyLauncherScrollView *pagesScrollView;
@property (nonatomic, assign) MyLauncherPageControl *pageControl;
@property (nonatomic, copy) NSMutableArray *pages;

-(void)layoutLauncher;

@end
