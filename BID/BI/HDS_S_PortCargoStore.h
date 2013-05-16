//
//  HDS_S_PortCargoStore.h
//  港存货物查询
//
//  Created by 毅 张 on 12-7-4.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//
#import "HDSViewController.h"

@interface HDS_S_PortCargoStore : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer2;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1,*dataForPlot2;

@end
