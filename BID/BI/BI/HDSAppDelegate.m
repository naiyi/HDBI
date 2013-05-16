//
//  HDSAppDelegate.m
//  BI
//
//  Created by 毅 张 on 12-5-23.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSAppDelegate.h"
#import "HDSMasterViewController.h"
#import "HDSDetailViewController.h"
#import "HDSLoginViewController.h"
#import "HDSDashboardViewController.h"

@implementation HDSAppDelegate{

}
@synthesize loginVC,dashVC,splitVC;

@synthesize window = _window;
//@synthesize storyboard = _storyboard;
@synthesize deviceOrientation;

- (HDSLoginViewController *) sharedLoginVC{
    @synchronized(self){
		if (loginVC == nil ) {
//			loginVC = [self.storyboard instantiateViewControllerWithIdentifier:@"login"];
            loginVC = [[HDSLoginViewController alloc] initWithNibName:@"HDSLoginViewController" bundle:nil];
		}
	}
	return loginVC;
}

- (HDSDashboardViewController *) sharedDashVC{
    @synchronized(self){
		if (dashVC == nil ) {
			dashVC = [[HDSDashboardViewController alloc] init];
		}
	}
	return dashVC;
}

- (UISplitViewController *) sharedSplitVC{
    @synchronized(self){
		if (splitVC == nil ) {
//            splitVC = [self.storyboard instantiateViewControllerWithIdentifier:@"splitView"];
//            UIViewController *masterController = [splitVC.viewControllers objectAtIndex:0];
//            splitVC.delegate = (id)masterController;
            splitVC = [[UISplitViewController alloc] init];
            HDSMasterViewController *master = [[HDSMasterViewController alloc] initWithNibName:@"HDSMasterViewController" bundle:nil];
            HDSDetailViewController *detail = [[HDSDetailViewController alloc] initWithNibName:@"HDSDetailViewController" bundle:nil];
            splitVC.viewControllers = [NSArray arrayWithObjects:master,detail,nil];
            splitVC.delegate = master;
		}
	}
	return splitVC;
}

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    
    // 手动加载storyboard,目的是修改默认的window.rootViewController
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
//    self.storyboard = [UIStoryboard storyboardWithName:@"MainStoryboard" bundle:nil];
//    self.window.rootViewController = [self.storyboard instantiateInitialViewController];
    
    [self.window addSubview:[self sharedLoginVC].view];
    [self.window makeKeyAndVisible];
    
    // 根据皮肤修改控件样式
    [HDSUtil setSegmentSkin:[HDSUtil skinType]];

    return YES;
}
	
-(void)applicationDidReceiveMemoryWarning:(UIApplication *)application
{
	NSLog(@"AppDelegate:applicationDidReceiveMemoryWarning");
}

- (void)applicationWillResignActive:(UIApplication *)application
{
    // 不使用sharedDashVC，因为有可能从登录页面跳出，没有必要创建dashVC
    if(dashVC != nil){
        [dashVC saveHomePageModuleLayout];
    }
}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later. 
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}

- (void)applicationWillEnterForeground:(UIApplication *)application
{
    // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
}

- (void)applicationDidBecomeActive:(UIApplication *)application
{
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}

- (void)applicationWillTerminate:(UIApplication *)application
{
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
