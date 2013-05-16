//
//  HDS_S_CargoStopTime.h
//  HDBI
//
//  Created by 毅 张 on 12-8-6.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_S_CargoStopTime : HDSViewController <HDSTableViewDataSource,CPTPieChartDataSource,CPTPieChartDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *pieContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *pieContainer2;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *pieView;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *beginDateBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *endDateBtn;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1,*dataForPlot2;

- (IBAction)changeMonthTaped:(UIButton *)sender;

@end
