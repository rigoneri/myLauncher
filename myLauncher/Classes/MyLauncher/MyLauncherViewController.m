//
//  MyLauncherViewController.m
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

#import "MyLauncherViewController.h"

@interface MyLauncherViewController ()
-(NSMutableArray *)savedLauncherItems;
-(NSArray*)retrieveFromUserDefaults:(NSString *)key;
-(void)saveToUserDefaults:(id)object key:(NSString *)key;
@property (nonatomic, strong) UIView *overlayView;
@property (nonatomic, strong) UIViewController *currentViewController;
@end

@implementation MyLauncherViewController

@synthesize launcherNavigationController = _launcherNavigationController;
@synthesize launcherView = _launcherView;
@synthesize appControllers = _appControllers;
@synthesize overlayView = _overlayView;
@synthesize currentViewController = _currentViewController;

#pragma mark - ViewController lifecycle

-(id)init {
	if((self = [super init])) { 
		self.title = @"myLauncher";
	}
	return self;
}

-(void)loadView {
	[super loadView];
	
	[self setLauncherView:[[MyLauncherView alloc] initWithFrame:self.view.bounds]];
	[self.launcherView setBackgroundColor:COLOR(234,237,250)];
	[self.launcherView setDelegate:self];
	self.view = self.launcherView;
	
    [self.launcherView setPages:[self savedLauncherItems]];
    [self.launcherView setNumberOfImmovableItems:[(NSNumber *)[self retrieveFromUserDefaults:@"myLauncherViewImmovable"] intValue]];
    
    [self setAppControllers:[[NSMutableDictionary alloc] init]];
}

- (void)viewDidAppear:(BOOL)animated {
    [self.launcherView viewDidAppear:animated];
}


- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation {		
	return YES;
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration {
    [self.launcherView setCurrentOrientation:toInterfaceOrientation];
    if (self.launcherNavigationController) {
        [self.launcherNavigationController setNavigationBarHidden:YES];
        [self.launcherNavigationController willRotateToInterfaceOrientation:toInterfaceOrientation duration:duration];
    }
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation {
	if(self.launcherNavigationController) {
        [self.launcherNavigationController setNavigationBarHidden:NO];
        [self.launcherNavigationController didRotateFromInterfaceOrientation:fromInterfaceOrientation];
    }
	
	self.overlayView.frame = self.launcherView.frame;
	[self.launcherView layoutLauncher];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)viewDidUnload {
    [super viewDidUnload];
}

#pragma mark - MyLauncherItem management

-(BOOL)hasSavedLauncherItems {
    return ([self retrieveFromUserDefaults:@"myLauncherView"] != nil);
}

-(void)launcherViewItemSelected:(MyLauncherItem*)item {
    if (![self appControllers] || [self launcherNavigationController]) {
        return;
    }
    Class viewCtrClass = [[self appControllers] objectForKey:[item controllerStr]];
	UIViewController *controller = [[viewCtrClass alloc] init];
	
	[self setLauncherNavigationController:[[UINavigationController alloc] initWithRootViewController:controller]];
	[[self.launcherNavigationController topViewController] setTitle:item.controllerTitle];
    [self.launcherNavigationController setDelegate:self];
	
	if(self.view.frame.size.width == 480)
		self.launcherNavigationController.view.frame = CGRectMake(0, 0, 480, 320);
    if(self.view.frame.size.width == 1024)
        self.launcherNavigationController.view.frame = CGRectMake(0, 0, 1024, 768);
	
	[controller.navigationItem setLeftBarButtonItem:
	 [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"launcher"]
									  style:UIBarButtonItemStyleBordered 
									 target:self 
									 action:@selector(closeView)]];
				
	UIView *viewToLaunch = [[self.launcherNavigationController topViewController] view];
	
	[self.parentViewController.view addSubview:[self.launcherNavigationController view]];
	viewToLaunch.alpha = 0;		
	viewToLaunch.transform = CGAffineTransformMakeScale(0.00001, 0.00001);
	
	if (!self.overlayView) 
	{
		[self setOverlayView:[[UIView alloc] initWithFrame:self.launcherView.bounds]];
		self.overlayView.backgroundColor = [UIColor blackColor];
		self.overlayView.alpha = 0;
		self.overlayView.autoresizesSubviews = YES;
		self.overlayView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleBottomMargin;
		[self.view addSubview:self.overlayView];
	}
	
	self.launcherView.frame = self.overlayView.bounds;
	self.launcherView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
	
	[UIView animateWithDuration:0.3 
						  delay:0 
						options:UIViewAnimationOptionCurveEaseIn 
					 animations:^{
						 viewToLaunch.alpha = 1.0;		
						 viewToLaunch.transform = CGAffineTransformIdentity;
						 self.overlayView.alpha = 0.7;
					 }
					 completion:nil];
}

-(void)launcherViewDidBeginEditing:(id)sender {
	[self.navigationItem setRightBarButtonItem:[[UIBarButtonItem alloc]
												 initWithBarButtonSystemItem:UIBarButtonSystemItemDone
												 target:self.launcherView action:@selector(endEditing)] animated:YES];
}

-(void)launcherViewDidEndEditing:(id)sender {
	[self.navigationItem setRightBarButtonItem:nil];
}

- (void)closeView {	
	UIView *viewToClose = [[self.launcherNavigationController topViewController] view];
	viewToClose.transform = CGAffineTransformIdentity;
	
	[UIView animateWithDuration:0.3 
						  delay:0 
						options:UIViewAnimationOptionCurveEaseOut 
					 animations:^{
						 viewToClose.alpha = 0;		
						 viewToClose.transform = CGAffineTransformMakeScale(0.00001, 0.00001);
						 self.overlayView.alpha = 0;
					 }
					 completion:^(BOOL finished){
						 [[self.launcherNavigationController topViewController] viewWillDisappear:NO];
						 [[self.launcherNavigationController view] removeFromSuperview];
						 [[self.launcherNavigationController topViewController] viewDidDisappear:NO];
                         [self.launcherNavigationController setDelegate:nil];
                         [self setLauncherNavigationController:nil];
                         [self setCurrentViewController:nil];
						 [self.parentViewController viewWillAppear:NO];
						 [self.parentViewController viewDidAppear:NO];
					 }];
}

#pragma mark - UINavigationControllerDelegate

-(void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.currentViewController) {
        [self.currentViewController viewWillDisappear:animated];
    }
    [viewController viewWillAppear:animated];
}

-(void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated {
    if (self.currentViewController) {
        [self.currentViewController viewDidDisappear:animated];
    }
    [viewController viewDidAppear:animated];
    [self setCurrentViewController:viewController];
}

#pragma mark - myLauncher caching

-(NSMutableArray *)savedLauncherItems {
	NSArray *savedPages = (NSArray *)[self retrieveFromUserDefaults:@"myLauncherView"];
	
	if(savedPages)
	{
		NSMutableArray *savedLauncherItems = [[NSMutableArray alloc] init];
		
		for (NSArray *page in savedPages)
		{
			NSMutableArray *savedPage = [[NSMutableArray alloc] init];
			for(NSDictionary *item in page)
			{
                NSNumber *version;
                if ((version = [item objectForKey:@"myLauncherViewItemVersion"])) {
                    if ([version intValue] == 2) {
                        [savedPage addObject:[[MyLauncherItem alloc]
                                               initWithTitle:[item objectForKey:@"title"]
                                               iPhoneImage:[item objectForKey:@"image"]
                                               iPadImage:[item objectForKey:@"iPadImage"]
                                               target:[item objectForKey:@"controller"] 
                                               targetTitle:[item objectForKey:@"controllerTitle"]
                                               deletable:[[item objectForKey:@"deletable"] boolValue]]];
                    }
                } else {
                    [savedPage addObject:[[MyLauncherItem alloc]
                                           initWithTitle:[item objectForKey:@"title"]
                                           image:[item objectForKey:@"image"]
                                           target:[item objectForKey:@"controller"]
                                           deletable:[[item objectForKey:@"deletable"] boolValue]]];
                }
			}
			
			[savedLauncherItems addObject:savedPage];
		}
		
		return savedLauncherItems;
	}
    
	return nil;
}

-(void)clearSavedLauncherItems {
    [self saveToUserDefaults:nil key:@"myLauncherView"];
    [self saveToUserDefaults:nil key:@"myLauncherViewImmovable"];
}

-(id)retrieveFromUserDefaults:(NSString *)key {
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	
	if (standardUserDefaults) 
		return [standardUserDefaults objectForKey:key];
	return nil;
}

-(void)saveToUserDefaults:(id)object key:(NSString *)key {
    NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	
	if (standardUserDefaults) 
	{
		[standardUserDefaults setObject:object forKey:key];
		[standardUserDefaults synchronize];
	}
}

@end
