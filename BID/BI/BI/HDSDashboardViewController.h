//
//  HDSDashboardViewController.h
//  BI
//
//  Created by 毅 张 on 12-5-28.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HDSViewController.h"

@interface HDSDashboardViewController : UIViewController

@property (strong,nonatomic) NSMutableArray *gridViewControllers;
@property (strong,nonatomic) NSMutableArray *currentData;
@property (assign,nonatomic,getter = isLayoutChanged) BOOL layoutChanged;

- (void)addItem:(NSString *)functionName;
- (void)removeItem:(NSString *)functionName;
- (void)reloadView;
- (BOOL)saveHomePageModuleLayout;

@end
