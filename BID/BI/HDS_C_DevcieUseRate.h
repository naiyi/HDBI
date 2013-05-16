//
//  HDS_C_DevcieUseRate.h
//  HDBI
//
//  Created by 毅 张 on 12-9-10.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_C_DevcieUseRate : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *barContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *barContainer2;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1,*dataForPlot2;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *monthBtn;

- (IBAction)changeMonthTaped:(UIButton *)sender;

@end
