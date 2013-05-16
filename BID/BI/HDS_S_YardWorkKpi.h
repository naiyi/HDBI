//
//  HDS_S_YardWorkKpi.h
//  HDBI
//
//  Created by 毅 张 on 12-8-9.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_S_YardWorkKpi : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *barContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *barContainer2;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1,*dataForPlot2;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *beginDateBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *endDateBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *toLabel;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segment;

- (IBAction)changeMonthTaped:(UIButton *)sender;
- (IBAction)changeSegmentTaped:(UISegmentedControl *)sender;

@end
