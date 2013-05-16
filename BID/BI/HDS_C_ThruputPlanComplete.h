//
//  HDS_C_ThruputPlanComplete.h
//  HDBI
//
//  Created by 毅 张 on 12-8-15.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_C_ThruputPlanComplete : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *barContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *barContainer2;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *pieContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *pieContainer2;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1,*dataForPlot2;
@property (readwrite, retain, nonatomic) NSMutableDictionary *dataForPie;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *beginDateBtn;
@property (retain, nonatomic) IBOutlet UISegmentedControl *yearMonthSegment;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *yearBtn;

- (IBAction)changeMonthTaped:(UIButton *)sender;
- (IBAction)changeSegmentTaped:(UISegmentedControl *)sender;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *line1Title;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *line2Title;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *plan1;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *work1;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *rate1;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *iNum1;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *eNum1;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *plan2;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *work2;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *rate2;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *iNum2;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *eNum2;

@end