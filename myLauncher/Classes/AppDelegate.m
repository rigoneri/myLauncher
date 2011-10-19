//
//  AppDelegate.m
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

#import "AppDelegate.h"

@implementation AppDelegate

@synthesize window, navigationController;

- (void)applicationDidFinishLaunching:(UIApplication*)application 
{
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    if (!window) 
    {
        return;
    }
    window.backgroundColor = [UIColor blackColor];
							
	navigationController = [[UINavigationController alloc] initWithRootViewController:
							[[RootViewController alloc] init]];
	navigationController.navigationBar.tintColor = COLOR(2, 100, 162);
	
    [window addSubview:navigationController.view];
    [window makeKeyAndVisible];
    [window layoutSubviews];    
}

@end