//
//  RootViewController.m
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

#import "RootViewController.h"
#import "MyLauncherItem.h"


@implementation RootViewController

-(void)loadView
{
	[super loadView];
	
	if(!launcherItems)
	{
		[launcherView setPages:[NSMutableArray arrayWithObjects: 
								[NSMutableArray arrayWithObjects: 
								 [[[MyLauncherItem alloc] initWithTitle:@"Item 1"
																image:@"itemImage"
															   target:@"ItemViewController" 
															deletable:NO] autorelease],
							   [[[MyLauncherItem alloc] initWithTitle:@"Item 2"
																image:@"itemImage"
															   target:@"ItemViewController" 
															deletable:YES] autorelease],
							   [[[MyLauncherItem alloc] initWithTitle:@"Item 3"
																image:@"itemImage"
															   target:@"ItemViewController" 
															deletable:NO] autorelease],
							   [[[MyLauncherItem alloc] initWithTitle:@"Item 4"
																image:@"itemImage"
															   target:@"ItemViewController" 
															deletable:NO] autorelease],
							   [[[MyLauncherItem alloc] initWithTitle:@"Item 5"
																image:@"itemImage"
															   target:@"ItemViewController" 
															deletable:YES] autorelease],
							   [[[MyLauncherItem alloc] initWithTitle:@"Item 6"
																image:@"itemImage"
															   target:@"ItemViewController" 
															deletable:NO] autorelease],
							   [[[MyLauncherItem alloc] initWithTitle:@"Item 7"
																image:@"itemImage"
															   target:@"ItemViewController" 
															deletable:NO] autorelease],
							   nil], 
							  [NSMutableArray arrayWithObjects: 
							   [[[MyLauncherItem alloc] initWithTitle:@"Item 8"
																image:@"itemImage"
															   target:@"ItemViewController" 
															deletable:NO] autorelease],
							   [[[MyLauncherItem alloc] initWithTitle:@"Item 9"
																image:@"itemImage"
															   target:@"ItemViewController" 
															deletable:YES] autorelease],
							   [[[MyLauncherItem alloc] initWithTitle:@"Item 10"
																image:@"itemImage"
															   target:@"ItemViewController" 
															deletable:NO] autorelease],
							   nil],
							  nil]];
	}
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	//If you don't want to support multiple orientations uncomment the line below
	//return NO;
	return [super shouldAutorotateToInterfaceOrientation:toInterfaceOrientation];
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload 
{
    [super viewDidUnload];
}

- (void)dealloc 
{
    [super dealloc];
}

@end
