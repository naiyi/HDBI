//
//  HDS_S_ShipLoadSchedule.h
//  船舶装卸作业进度
//
//  Created by 毅 张 on 12-7-5.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//
#import "HDSViewController.h"

@interface HDS_S_ShipLoadSchedule : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer1;
@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1;

@end
