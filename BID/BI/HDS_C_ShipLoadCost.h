//
//  HDS_C_ShipLoadCost.h
//  HDBI
//
//  Created by 毅 张 on 12-9-11.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_C_ShipLoadCost : HDSViewController <HDSTableViewDataSource,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIButton *dateBtn;

- (IBAction)changeDateTaped:(UIButton *)sender;


@end
