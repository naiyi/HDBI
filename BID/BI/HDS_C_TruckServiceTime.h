//
//  HDS_C_TruckServiceTime.h
//  HDBI
//
//  Created by 毅 张 on 12-9-3.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_C_TruckServiceTime : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer;
@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *monthBtn;

- (IBAction)changeMonthTaped:(UIButton *)sender;

@end