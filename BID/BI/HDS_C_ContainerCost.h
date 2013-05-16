//
//  HDS_C_ContainerCost.h
//  HDBI
//
//  Created by 毅 张 on 12-9-11.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_C_ContainerCost : HDSViewController <HDSTableViewDataSource,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIButton *yearBtn;

- (IBAction)changeMonthTaped:(UIButton *)sender;

@end
