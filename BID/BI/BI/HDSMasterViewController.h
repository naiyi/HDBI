//
//  HDSMasterViewController.h
//  BI
//
//  Created by 毅 张 on 12-5-23.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "GMGridView.h"
#import "HDSViewController.h"

@class HDSDetailViewController;

@interface HDSMasterViewController : HDSViewController <UITableViewDataSource,UITableViewDelegate,UISplitViewControllerDelegate>

@property (strong, nonatomic) UIViewController *detailViewController;
@property (strong, nonatomic) IBOutlet UISegmentedControl *segButton;   // updateTheme时需要使用，定义strong防止引用被释放
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *switchButton;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *settingButton;

- (IBAction)segButtonChanged:(UISegmentedControl *)sender;
@property (unsafe_unretained, nonatomic) IBOutlet UITableView *tableView;
- (IBAction)switchButtonTaped:(UIButton *)sender;
- (IBAction)settingButtonTaped:(UIButton *)sender;

@property (assign,nonatomic) BOOL showedInSetting;
- (void)reloadMenuData;
@property (retain,nonatomic) NSIndexPath *lastSelected;

@end
