//
//  HDSCompanyViewController.h
//  BI
//
//  Created by 毅 张 on 12-6-14.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSRefreshDelegate.h"

@interface HDSCompanyViewController : UITableViewController <UIPopoverControllerDelegate>

@property (strong,nonatomic) NSMutableArray *checkedIndex;
@property (unsafe_unretained,nonatomic) id<HDSRefreshDelegate> delegate;
//@property (unsafe_unretained, nonatomic) UILabel *companyLabel;
//@property (unsafe_unretained, nonatomic) UILabel *companyValue;

+ (NSArray *) companys;
+ (void) loadCompanys;
+ (void) setCompanys:(NSArray *)_companys;

@end
