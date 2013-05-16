//
//  HDS_C_YardUpsetRate.h
//  HDBI
//
//  Created by 毅 张 on 12-9-5.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_C_YardUpsetRate : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *beginDateBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *endDateBtn;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1;

- (IBAction)changeDateTaped:(UIButton *)sender;


@end
