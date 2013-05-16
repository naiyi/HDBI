//
//  HDSAppDelegate.h
//  BI
//
//  Created by 毅 张 on 12-5-23.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import <UIKit/UIKit.h>

@class HDSLoginViewController;
@class HDSDashboardViewController;

@interface HDSAppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;
//@property (strong, nonatomic) UIStoryboard *storyboard;
@property UIDeviceOrientation deviceOrientation;

@property (strong, nonatomic) HDSLoginViewController *loginVC;
@property (strong, nonatomic) HDSDashboardViewController *dashVC;
@property (strong, nonatomic) UISplitViewController *splitVC;

- (HDSLoginViewController *) sharedLoginVC;
- (HDSDashboardViewController *) sharedDashVC;
- (UISplitViewController *) sharedSplitVC;


@end
