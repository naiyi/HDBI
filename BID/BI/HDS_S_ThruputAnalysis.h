//
//  HDS_S_ThruputAnalysis.h
//  散杂货吞吐量分析
//
//  Created by 毅 张 on 12-6-27.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//
#import "HDSViewController.h"

@interface HDS_S_ThruputAnalysis : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *barContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *barContainer2;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *pieContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *pieContainer2;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1,*dataForPlot2;
@property (readwrite, retain, nonatomic) NSMutableDictionary *dataForPie;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *beginDateBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *endDateBtn;
@property (retain, nonatomic) IBOutlet UISegmentedControl *yearMonthSegment;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *yearBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *toLabel;

- (IBAction)changeMonthTaped:(UIButton *)sender;
- (IBAction)changeSegmentTaped:(UISegmentedControl *)sender;

@end
