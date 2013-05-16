//
//  HDS_C_ShipIOPortPlan.h
//  HDBI
//
//  Created by 毅 张 on 12-8-14.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"
#import "WEPopoverController.h"

@interface HDS_C_ShipIOPortPlan : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer;
@property (retain, nonatomic) IBOutlet UISegmentedControl *segment; // updateTheme时需要使用，定义strong防止引用被释放

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot;

@property (strong,nonatomic) UIPopoverController *shipInfoPop;
@property (nonatomic, retain) WEPopoverController *shipInfoPopWE;

- (IBAction)segmentChanged:(UISegmentedControl *)sender;

@end
