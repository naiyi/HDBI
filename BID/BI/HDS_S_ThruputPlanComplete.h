//
//  HDS_S_ThruputPlanComplete.h
//  吞吐量计划完成情况
//
//  Created by 毅 张 on 12-7-4.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//
#import "HDSViewController.h"

@interface HDS_S_ThruputPlanComplete : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer2;
@property (retain, nonatomic) IBOutlet UISegmentedControl *yearMonthSegment;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *yearBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *monthBtn;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1,*dataForPlot2;

- (IBAction)changeMonthTaped:(UIButton *)sender;
- (IBAction)changeSegmentTaped:(UISegmentedControl *)sender;

@end
