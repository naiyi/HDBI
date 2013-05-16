//
//  HDS_S_ShipChargeQuery.h
//  船舶计费情况查询
//
//  Created by 毅 张 on 12-7-24.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_S_ShipChargeQuery : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (strong, nonatomic) IBOutlet UIView *plotContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *monthBtn;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1;

@property (strong,nonatomic) UIPopoverController *piePop;

- (IBAction)changeMonthTaped:(UIButton *)sender;

@end
