//
//  HDS_C_YardStockDensity.h
//  HDBI
//
//  Created by 毅 张 on 12-9-7.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_C_YardStockDensity : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer1;
@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1;

@end
