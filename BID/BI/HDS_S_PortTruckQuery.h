//
//  HDS_S_PortTruckQuery.h
//  在港车辆查询
//
//  Created by 毅 张 on 12-6-27.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//
#import "HDSViewController.h"

@interface HDS_S_PortTruckQuery : HDSViewController <HDSTableViewDataSource,CPTPieChartDataSource,CPTPieChartDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *pieContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *pieContainer2;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *pieView;
@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1,*dataForPlot2;


@end
