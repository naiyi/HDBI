//
//  HDSViewController.h
//  HDBI
//
//  Created by 毅 张 on 12-7-16.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "HDSTableViewDataSource.h"
#import <CorePlot-CocoaTouch.h>
#import "SBJson.h"

#import "HDSRefreshDelegate.h"
#import "HDSTableView.h"
#import "HDSCompanyViewController.h"
#import "HDSUtil.h"
#import "HDSTreeNode.h"
#import "HDSPlotDelegate.h"
#import "HDSYearMonthPicker.h"
#import "HDSYAxisRangePlot.h"
#import "HDSCargoViewController.h"

#define SplitPopupBtnTag 300
#define SmallViewConditionFontSize 16

@interface HDSViewController : UIViewController <CPTBarPlotDataSource, CPTBarPlotDelegate,HDSRefreshDelegate,NSURLConnectionDelegate>{
    @protected
    __unsafe_unretained UIView *tableContainer;
    __unsafe_unretained UIButton *popPageBtn;
    __unsafe_unretained UIButton *refreshBtn;
    __unsafe_unretained UIButton *lastPageBtn;
    __unsafe_unretained UIButton *nextPageBtn;
    __unsafe_unretained UILabel *titleLabel;
    UIButton *chooseCompBtn;
    UILabel *companyLabel;
    UIButton *chooseCargoBtn;
    UILabel *cargoLabel;
    
    HDSTableView *tableView;
    
    BOOL isSmallView;   // 首页视图
    NSArray *pageViews;
    NSInteger currentViewIndex;
    
    NSArray *headerNames;
    
    UIPopoverController *compPopController;
    UIPopoverController *cargoPopController;
    
    NSString *qCompany;
    NSString *qCargo;
    
    NSDateComponents *currentBeginDate;
    NSDateComponents *currentEndDate;
    
    NSTimer *dataTimer; // 线图使用
    NSInteger pointCount;
    NSInteger fps;
    
    UIPageControl *pc;
    UIView *conditionPopup;
    BOOL isShowingCondition;
    
    BOOL isLog;
    NSDate *logBegin;
    NSDate *logEnd;
    
}

@property (assign,nonatomic,getter = isInHomePage) BOOL inHomePage;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *tableContainer;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *popPageBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *refreshBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *lastPageBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *nextPageBtn;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *titleLabel;
@property (retain, nonatomic) IBOutlet UIButton *chooseCompBtn;
@property (retain, nonatomic) IBOutlet UILabel *companyLabel;
@property (retain, nonatomic) IBOutlet UIButton *chooseCargoBtn;
@property (retain, nonatomic) IBOutlet UILabel *cargoLabel;

@property (retain,nonatomic) NSMutableArray *rootArray;

- (IBAction)pageButtonTaped:(UIButton *)sender;
- (IBAction)chooseCompBtnTaped:(UIButton *)sender;
- (IBAction)chooseCargoTaped:(UIButton *)sender;
- (void)smallViewChangeToIndex:(NSInteger)index;
- (void)insertPageControlToSmallView;

- (void)updateTheme:(NSNotification*)notification;

- (void) loadChildren:(HDSTreeNode *)node withData:(NSDictionary *)data;
- (void) loadChildren:(HDSTreeNode *)node withData:(NSDictionary *)data expand:(BOOL)expand;

-(void) addBarPlotView:(CPTGraphHostingView *)_plotView toContainer:(UIView *)container title:(NSString *)title xTitle:(NSString *)xTitle yTitle:(NSString *)yTitle plotNum:(NSInteger)plotNum identifier:(NSArray *)identifier useLegend:(BOOL)useLegend useLegendIcon:(BOOL)useLegendIcon;

-(void) addLinePlotView:(CPTGraphHostingView *)_plotView toContainer:(UIView *)container title:(NSString *)title xTitle:(NSString *)xTitle yTitle:(NSString *)yTitle plotNum:(NSInteger)plotNum identifier:(NSArray *)identifier useLegend:(BOOL)useLegend useLegendIcon:(BOOL)useLegendIcon;

-(void) refreshBarPlotView:(CPTGraphHostingView *)_plotView dataForPlot:(NSMutableArray *)_dataForPlot data:(NSArray *)array dataIsTreeNode:(BOOL)dataIsTreeNode xLabelKey:(NSString *)xLabelKey yLabelKey:(NSArray *)yLabelKey yTitleWidth:(CGFloat)yTitleWidth plotNum:(NSInteger)plotNum;

-(void) addPiePlotView:(CPTGraphHostingView *)_plotView toContainer:(UIView *)container title:(NSString *)title useLegend:(BOOL)useLegend useLegendIcon:(BOOL)useLegendIcon;

- (void)refreshPlotTheme:(CPTGraphHostingView *)plotView;

-(NSInteger)xAxisMaxCount:(NSInteger)plotNum plotView:(CPTGraphHostingView *)_plotView;

- (void)showConditionPopup;
- (void)createConditionView;
- (void)fillConditionView:(UIView *)view;
- (void)fillConditionView:(UIView *)view corpLine:(NSInteger)line;

@end
