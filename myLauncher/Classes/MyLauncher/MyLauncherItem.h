//
//  MyLauncherItem.h
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

@protocol MyLauncherItemDelegate <NSObject>
-(void)didDeleteItem:(id)item;
@end

@interface MyLauncherItem : UIControl 
{
	id <MyLauncherItemDelegate> delegate;
	Class targetController;
	NSString *title;
	NSString *image;
	NSString *controllerStr;
	
	BOOL dragging;
	BOOL deletable;
	UIButton *closeButton;
}

@property (nonatomic, assign) id delegate;
@property (nonatomic) Class targetController;
@property (nonatomic, retain) NSString *title;
@property (nonatomic, retain) NSString *image;
@property (nonatomic, retain) NSString *controllerStr;
@property (nonatomic, retain) UIButton *closeButton;

-(id)initWithTitle:(NSString *)_title image:(NSString *)_image target:(NSString *)_targetControllerStr deletable:(BOOL)_deletable;
-(void)layoutItem;
-(void)setDragging:(BOOL)flag;
-(BOOL)dragging;
-(BOOL)deletable;


@end
