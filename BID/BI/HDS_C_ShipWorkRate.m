//
//  HDS_C_ShipWorkRate.m
//  HDBI
//
//  Created by 毅 张 on 12-8-20.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_C_ShipWorkRate.h"

@implementation HDS_C_ShipWorkRate{
    
    CPTGraphHostingView *plotView1;
    
    UIPopoverController *beginDatePopover;
    UIPopoverController *endDatePopover;
    
    NSURLConnection *conn1; // 表格数据
    SBJsonStreamParser *parser1;
    SBJsonStreamParserAdapter *adapter1;
    NSURLConnection *conn2; // 图表数据
    SBJsonStreamParser *parser2;
    SBJsonStreamParserAdapter *adapter2;
    
    NSString *qBeginDate;
    NSString *qEndDate;
}

@synthesize plotContainer1;
@synthesize beginDateBtn;
@synthesize endDateBtn;
@synthesize dataForPlot1;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification];
    HDSSkinType skinType = [HDSUtil skinType];
    
    [beginDateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal_110.png"] forState:UIControlStateNormal];
    [beginDateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight_110.png"] forState:UIControlStateHighlighted];
    [endDateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal_110.png"] forState:UIControlStateNormal];
    [endDateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight_110.png"] forState:UIControlStateHighlighted];
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    [beginDateBtn setTitleColor:color forState:UIControlStateNormal];
    [endDateBtn setTitleColor:color forState:UIControlStateNormal];
    
    [self refreshPlotTheme:plotView1];
}

- (void)fillConditionView:(UIView *)view{
    // 开始日期
    beginDateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    beginDateBtn.frame = CGRectMake(20,10,119,31);
    beginDateBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    beginDateBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [beginDateBtn addTarget:self action:@selector(changeDateTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:beginDateBtn];
    // 结束日期
    endDateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    endDateBtn.frame = CGRectMake(147,10,119,31);
    endDateBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    endDateBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [endDateBtn addTarget:self action:@selector(changeDateTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:endDateBtn];
    
    [super fillConditionView:view];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,plotContainer1, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"单船作业效率";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    headerNames = [NSArray arrayWithObjects:@"船名航次",@"开工时间",@"完工时间",@"装卸船作业量",@"作业时间",@"船时效率",nil];
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView1 toContainer:plotContainer1 title:@"单船作业效率" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"作业效率",nil] useLegend:NO useLegendIcon:NO];
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot1 = [[NSMutableArray alloc] init];
    
    // 初始化默认月份
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *endDates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    [self refreshByDates:endDates fromPopupBtn:endDateBtn];
    NSDateComponents *beginDates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    [self refreshByDates:beginDates fromPopupBtn:beginDateBtn];
    // 默认全部权限的公司
    [self refreshByComps:[HDSCompanyViewController companys]];
    
    [self loadData];
}

-(void)viewDidLayoutSubviews{
    if(isSmallView)
        return;
    [tableView adjustRightTableViewWidth];
    [tableView positionVerticalScrollBar];
    plotView1.frame = plotContainer1.bounds;
}

- (void)viewDidUnload{
    [self setPlotContainer1:nil];
    [self setBeginDateBtn:nil];
    [self setEndDateBtn:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 6;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
//    return 2;
//}
// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column == 0) return 120.0f;
        if(column <= 2) return 120.0f;
        if(column == 3) return 90.0f;
        return 70.0f;
    }
    if(column == 0) return 131.0f;
    if(column <= 2) return 132.0f;
    if(column == 3) return 101.0f;
    return 80.0f;
}

- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
//    @"船名航次",@"开工时间",@"完工时间",@"装卸船作业量",@"作业时间",@"船时效率"
    switch (col) {
        case 0: return @"ship";
        case 1: return @"begTim";
        case 2: return @"endTim";
        case 3: return @"teuNum";
        case 4: return @"workHours";
        case 5: return @"efficiency";
        default:return @"";
    }
}


- (IBAction)changeDateTaped:(UIButton *)sender {
    if(sender == beginDateBtn){
        [self createDatePopovers];
        [beginDatePopover presentPopoverFromRect:beginDateBtn.frame inView:[beginDateBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }else if(sender == endDateBtn){
        [self createDatePopovers];
        [endDatePopover presentPopoverFromRect:endDateBtn.frame inView:[endDateBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)createDatePopovers{
    if(beginDatePopover == nil){
        HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearMonthPickerFormat popupBtn:beginDateBtn];
        picker.delegate = self;
        beginDatePopover= [[UIPopoverController alloc] initWithContentViewController:picker];
        beginDatePopover.popoverContentSize = picker.view.frame.size;
        beginDatePopover.delegate = picker;
    }
    if(endDatePopover == nil){
        HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearMonthPickerFormat popupBtn:endDateBtn];
        picker.delegate = self;
        endDatePopover= [[UIPopoverController alloc] initWithContentViewController:picker];
        endDatePopover.popoverContentSize = picker.view.frame.size;
        endDatePopover.delegate = picker;
    }
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{
    if(popupBtn == nil){    // smallView 时初始化没有按钮
        qBeginDate = [NSString stringWithFormat:@"%d%02d",[_dates year],[_dates month]];
        qEndDate = [NSString stringWithFormat:@"%d%02d",[_dates year],[_dates month]];
        return;
    }
    if(popupBtn == beginDateBtn){
        [beginDateBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year],[_dates month]] forState:UIControlStateNormal];
        qBeginDate = [NSString stringWithFormat:@"%d%02d",[_dates year] ,[_dates month]];
        currentBeginDate = _dates;
        // 若结束月份小于开始月份，则自动更新为开始月份
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *bDate = [calendar dateFromComponents:currentBeginDate];
        NSDate *eDate = [calendar dateFromComponents:currentEndDate];
        if([bDate timeIntervalSinceDate:eDate]>0){
            [endDateBtn setTitle:[beginDateBtn titleForState:UIControlStateNormal] forState:UIControlStateNormal];
            qEndDate = qBeginDate;
            currentEndDate = [currentBeginDate copy];
            // 回写pickView的选中行
            ((HDSYearMonthPicker *)endDatePopover.contentViewController).scrollToDate = currentEndDate;
        }
    }else if(popupBtn == endDateBtn){
        [endDateBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year],[_dates month]] forState:UIControlStateNormal];
        qEndDate = [NSString stringWithFormat:@"%d%02d",[_dates year] ,[_dates month]];
        currentEndDate = _dates;
        // 若开始月份大于结束月份，则自动更新为结束月份
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *bDate = [calendar dateFromComponents:currentBeginDate];
        NSDate *eDate = [calendar dateFromComponents:currentEndDate];
        if([bDate timeIntervalSinceDate:eDate]>0){
            [beginDateBtn setTitle:[endDateBtn titleForState:UIControlStateNormal] forState:UIControlStateNormal];
            qBeginDate = qEndDate;
            currentBeginDate = [currentEndDate copy];
            ((HDSYearMonthPicker *)beginDatePopover.contentViewController).scrollToDate = currentBeginDate;
        }
    }
}

#pragma mark -
#pragma mark Plot Data Source Methods
//-(NSString *)legendTitleForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index{
//    return [NSString stringWithFormat:@"Bar %lu", (unsigned long)(index + 1)];
//}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
    return [dataForPlot1 count];
}

- (double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    if(fieldEnum == CPTBarPlotFieldBarLocation ){
        return index+1;
    }else{  //CPTBarPlotFieldBarTip
        NSDictionary *dict = [dataForPlot1 objectAtIndex:index];
        return [(NSNumber *)[dict objectForKey:@"efficiency"] doubleValue];
    }
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView)
        return nil;
    
	CPTTextLayer *newLayer = nil;
    double num = [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
    if(num > 0.1){
        newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.0f", 
                                                       num] style:[HDSUtil plotTextStyle:10]];
    }
    
	return newLayer;
}

-(CPTFill *)barFillForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index{
	return [CPTFill fillWithGradient:[HDSUtil barChartGradientAtIndex:index]];
}

#pragma mark - 数据读取相关
- (void)loadData {
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
    adapter2 = [[SBJsonStreamParserAdapter alloc] init];
    adapter2.delegate = self;
    parser2 = [[SBJsonStreamParser alloc] init];
    parser2.delegate = adapter2;
	
    // 表格数据
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ShipWorkRateGrid" withExtension:@"json"]]];
        [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ShipWorkRateChart" withExtension:@"json"]]];
    }else{
        NSString *url,*url2;
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CShipWorkRate/list.json?beginYM=%@&endYM=%@&corps=%@",qBeginDate,qEndDate,qCompany];
        url2= [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CShipWorkRate/listChart.json?beginYM=%@&endYM=%@&corps=%@",qBeginDate,qEndDate,qCompany];
        
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        NSURLRequest *theRequest2=[NSURLRequest requestWithURL:[NSURL URLWithString:url2] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest2 delegate:self];
    }
}

#pragma mark SBJsonStreamParserAdapterDelegate methods
- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
    NSDictionary *data;
    if(parser == parser1){
        HDSTreeNode *node;
        [self.rootArray removeAllObjects];
        for(int i=0; i<array.count; i++){
            data = [array objectAtIndex:i];
            node = [[HDSTreeNode alloc] initWithProperties:[data objectForKey:@"properties"] parent:nil expanded:YES];
            [self.rootArray addObject:node];
        }
        [tableView reloadData];
    }else if(parser == parser2){
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:array dataIsTreeNode:false  xLabelKey:@"ship" yLabelKey:[NSArray arrayWithObjects:@"efficiency",nil] yTitleWidth:0 plotNum:1];
    }
}

- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {
}

#pragma mark- NSURLConnectionDelegate methods
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //	NSLog(@"Connection didReceiveData of length: %u", data.length);
    SBJsonStreamParser *parser ; 
    if(connection == conn1){
        parser = parser1;
    }else if(connection == conn2){
        parser = parser2;
    }
    SBJsonStreamParserStatus status = [parser parse:data];
	if (status == SBJsonStreamParserError) {
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"单船作业效率");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"单船作业效率");
	} else{

    }
}

@end
