//
//  HDS_C_LineThruput.h
//  HDBI
//
//  Created by 毅 张 on 12-8-17.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSViewController.h"

@interface HDS_C_LineThruput : HDSViewController <HDSTableViewDataSource,CPTPieChartDataSource,CPTPieChartDelegate,HDSRefreshDelegate,SBJsonStreamParserAdapterDelegate,UIScrollViewDelegate>
@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *plotContainer2;
@property (unsafe_unretained, nonatomic) IBOutlet UIScrollView *scrollView;
@property (unsafe_unretained, nonatomic) IBOutlet UIPageControl *pageControl;

@property (unsafe_unretained, nonatomic) IBOutlet UIView *pieContainer1;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *pieContainer2;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *pieContainer3;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *beginDateBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *endDateBtn;

@property (readwrite, retain, nonatomic) NSMutableArray *dataForPlot1,*dataForPlot2;
@property (readwrite, retain, nonatomic) NSDictionary *dataForPie;

- (IBAction)changeMonthTaped:(UIButton *)sender;

@end
