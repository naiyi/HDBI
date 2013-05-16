//
//  HDS_S_ShipInPortDynamic.h
//  HDBI
//
//  Created by 毅 张 on 12-7-9.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_S_ShipInPortDynamic : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer1;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segment;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *beginDateBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *endDateBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *toLabel;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1;

- (IBAction)changeDateTaped:(UIButton *)sender;
- (IBAction)segmentChanged:(UISegmentedControl *)sender;


@end
