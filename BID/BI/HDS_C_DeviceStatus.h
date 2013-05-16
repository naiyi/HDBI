//
//  HDS_C_DeviceStatus.h
//  HDBI
//
//  Created by 毅 张 on 12-9-4.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_C_DeviceStatus : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer1;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1;

@end
