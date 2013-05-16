//
//  HDS_S_ShipLoadEfficiency.h
//  单船装卸效率分析
//
//  Created by 毅 张 on 12-7-25.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_S_ShipLoadEfficiency : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer1;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segment;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *beginDateBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *endDateBtn;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1;

- (IBAction)changeDateTaped:(UIButton *)sender;
- (IBAction)segmentChanged:(UISegmentedControl *)sender;


@end
