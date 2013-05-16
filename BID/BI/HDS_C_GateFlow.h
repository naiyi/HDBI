//
//  HDS_C_GateFlow.h
//  HDBI
//
//  Created by 毅 张 on 12-8-17.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_C_GateFlow : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer2;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *yearBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *tableContainer2;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1,*dataForPlot2;
@property (readwrite, retain, nonatomic) NSMutableArray *rootArray2;

- (IBAction)changeMonthTaped:(UIButton *)sender;

@end
