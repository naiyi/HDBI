//
//  HDS_S_ShipDayNightPlan.h
//  集疏港计划完成情况
//
//  Created by 毅 张 on 12-7-5.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_S_IOPortPlanComplete : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *dateBtn;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segment;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1;

- (IBAction)changeDateTaped:(UIButton *)sender;
- (IBAction)segmentChanged:(UISegmentedControl *)sender;


@end
