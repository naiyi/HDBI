//
//  HDSCargoViewController.h
//  BI
//
//  Created by 毅 张 on 12-6-14.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSRefreshDelegate.h"

@interface HDSCargoViewController : UITableViewController <UIPopoverControllerDelegate>

@property (strong,nonatomic) NSMutableArray *checkedIndex;
@property (unsafe_unretained,nonatomic) id<HDSRefreshDelegate> delegate;
//@property (unsafe_unretained, nonatomic) UILabel *cargoLabel;
//@property (unsafe_unretained, nonatomic) UILabel *cargoValue;

+ (NSArray *) cargos;
+ (void) loadCargos;
+ (void) setCargos:(NSArray *)_cargos;

@end
