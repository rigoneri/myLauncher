//
//  MyLauncherViewController.m
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

#import "MyLauncherViewController.h"

@interface MyLauncherViewController(hidden)
-(NSMutableArray *)savedLauncherItems;
-(NSArray*)retrieveFromUserDefaults:(NSString *)key;
@end

@implementation MyLauncherViewController

@synthesize launcherNavigationController, launcherView, launcherItems;

-(id)init
{
	if((self = [super init]))
	{ 
		self.title = @"myLauncher";
	}
	return self;
}

-(void)loadView
{
	[super loadView];
	
	launcherView = [[MyLauncherView alloc] initWithFrame:self.view.bounds];
	[launcherView setBackgroundColor:COLOR(234,237,250)];
	[launcherView setDelegate:self];
	self.view = launcherView;
	
	launcherItems = [self savedLauncherItems];
	
	if(launcherItems)
		[launcherView setPages:launcherItems];
}

-(NSMutableArray *)savedLauncherItems
{
	NSArray *savedPages = [self retrieveFromUserDefaults:@"myLauncherView"];
	
	if(savedPages)
	{
		NSMutableArray *savedLauncherItems = [[NSMutableArray alloc] init];
		
		for (NSArray *page in savedPages)
		{
			NSMutableArray *savedPage = [[NSMutableArray alloc] init];
			for(NSDictionary *item in page)
			{
				[savedPage addObject:[[[MyLauncherItem alloc] 
									   initWithTitle:[item objectForKey:@"title"]
									   image:[item objectForKey:@"image"]
									   target:[item objectForKey:@"controller"] 
									   deletable:[[item objectForKey:@"deletable"] boolValue]] autorelease]];	
			}
			
			[savedLauncherItems addObject:savedPage];
			[savedPage release];
		}
		
		return [savedLauncherItems autorelease];
	}

	return nil;
}

-(void)launcherViewItemSelected:(MyLauncherItem*)item
{
	UIViewController *controller = [[[item.targetController alloc] init] autorelease];

	if(launcherNavigationController)
		[launcherNavigationController release];
	
	launcherNavigationController = [[UINavigationController alloc] initWithRootViewController:controller];	
	[[launcherNavigationController topViewController] setTitle:item.title];
	
	if(self.view.frame.size.width == 480)
		launcherNavigationController.view.frame = CGRectMake(0, 0, 480, 320);
	
	[controller.navigationItem setLeftBarButtonItem:
	 [[[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"launcher"]
									  style:UIBarButtonItemStyleBordered 
									 target:self 
									 action:@selector(closeView)] autorelease]];
				
	UIView *viewToLaunch = [[launcherNavigationController topViewController] view];
	
	[self.parentViewController.view addSubview:[launcherNavigationController view]];
	viewToLaunch.alpha = 0;		
	viewToLaunch.transform = CGAffineTransformMakeScale(0.00001, 0.00001);
	
	if (!overlayView) 
	{
		overlayView = [[UIView alloc] initWithFrame:launcherView.bounds];
		overlayView.backgroundColor = [UIColor blackColor];
		overlayView.alpha = 0;
		overlayView.autoresizesSubviews = YES;
		overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		[self.view addSubview:overlayView];
	}
	
	launcherView.frame = overlayView.bounds;
	launcherView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[UIView animateWithDuration:0.3 
						  delay:0 
						options:UIViewAnimationOptionCurveEaseIn 
					 animations:^{
						 viewToLaunch.alpha = 1.0;		
						 viewToLaunch.transform = CGAffineTransformIdentity;
						 overlayView.alpha = 0.7;
					 }
					 completion:nil];
}

-(void)launcherViewDidBeginEditing:(id)sender
{
	[self.navigationItem setRightBarButtonItem:[[[UIBarButtonItem alloc] 
												 initWithBarButtonSystemItem:UIBarButtonSystemItemDone
												 target:launcherView action:@selector(endEditing)] autorelease] animated:YES];
}

-(void)launcherViewDidEndEditing:(id)sender
{
	[self.navigationItem setRightBarButtonItem:nil];
}

- (void)closeView 
{	
	UIView *viewToClose = [[launcherNavigationController topViewController] view];
	viewToClose.transform = CGAffineTransformIdentity;
	
	[UIView animateWithDuration:0.3 
						  delay:0 
						options:UIViewAnimationOptionCurveEaseOut 
					 animations:^{
						 viewToClose.alpha = 0;		
						 viewToClose.transform = CGAffineTransformMakeScale(0.00001, 0.00001);
						 overlayView.alpha = 0;
					 }
					 completion:^(BOOL finished){
						 [[launcherNavigationController topViewController] viewWillDisappear:NO];
						 [[launcherNavigationController view] removeFromSuperview];
						 [[launcherNavigationController topViewController] viewDidDisappear:NO];
						 [self.parentViewController viewWillAppear:NO];
						 [self.parentViewController viewDidAppear:NO];
					 }];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{	
	if(launcherNavigationController)
		[launcherNavigationController setNavigationBarHidden:YES];
	
	return YES;
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	if(launcherNavigationController)	
		[launcherNavigationController setNavigationBarHidden:NO];
	
	overlayView.frame = launcherView.frame;
	[launcherView layoutLauncher];
}

-(NSArray*)retrieveFromUserDefaults:(NSString *)key
{
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	NSArray *val = nil;
	
	if (standardUserDefaults) 
		val = [standardUserDefaults objectForKey:key];
	
	return val;
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
	[launcherNavigationController release];
	[launcherView release];
    [super dealloc];
}


@end
