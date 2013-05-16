//
//  HDS_C_ContainerCycle.h
//  HDBI
//
//  Created by 毅 张 on 12-8-17.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_C_ContainerCycle : HDSViewController <HDSTableViewDataSource,CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate,UIScrollViewDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer2;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer3;
@property (unsafe_unretained, nonatomic) IBOutlet UIScrollView *scrollView;
@property (unsafe_unretained, nonatomic) IBOutlet UIPageControl *pageControl;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1;
@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot2;
@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot3;

@property (unsafe_unretained, nonatomic) IBOutlet UIButton *monthBtn;

- (IBAction)changePage:(UIPageControl *)sender;
- (IBAction)changeMonthTaped:(UIButton *)sender;

@end
