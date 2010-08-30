//
//  AppDelegate.m
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

#import "AppDelegate.h"
#import "ItemViewController.h"

@implementation AppDelegate

@synthesize window, navigationController, appControllers;

- (void)applicationDidFinishLaunching:(UIApplication*)application 
{
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    if (!window) 
    {
        [self release];
        return;
    }
    window.backgroundColor = [UIColor blackColor];
	
	appControllers = [[NSMutableDictionary alloc] init];
	[appControllers setObject:[ItemViewController class] forKey:@"ItemViewController"];
	
	//Add your view controllers here to be picked up by the launcher
	//[appControllers setObject:[MyCustomViewController class] forKey:@"MyCustomViewController"];
	//[appControllers setObject:[MyOtherCustomViewController class] forKey:@"MyOtherCustomViewController"];
							
	navigationController = [[UINavigationController alloc] initWithRootViewController:
							[[[RootViewController alloc] init] autorelease]];
	navigationController.navigationBar.tintColor = COLOR(2, 100, 162);
	
    [window addSubview:navigationController.view];
    [window makeKeyAndVisible];
    [window layoutSubviews];    
}

- (void)dealloc 
{
    [navigationController release];
    [window release];
	[appControllers release];
    [super dealloc];
}

@end