//
//  HDS_S_ShipLoadEfficiency.m
//  单船装卸效率分析
//
//  Created by 毅 张 on 12-7-25.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_S_ShipLoadEfficiency.h"

@implementation HDS_S_ShipLoadEfficiency{
    
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
    NSString *qUnload;
    NSString *unload;
    
}

@synthesize plotContainer1;
@synthesize segment;
@synthesize beginDateBtn;
@synthesize endDateBtn;
@synthesize dataForPlot1;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification];
    HDSSkinType skinType = [HDSUtil skinType];
    
    [HDSUtil changeSegment:segment textAttributeBySkin:skinType]; 
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
    // segment
    segment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"装船",@"卸船", nil]];
    segment.segmentedControlStyle = UISegmentedControlStylePlain;
    segment.frame = CGRectMake(20, 10, 103, 31);
    segment.selectedSegmentIndex = 0;
    [segment addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    [view addSubview:segment];
    // 开始日期
    beginDateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    beginDateBtn.frame = CGRectMake(20,50,119,31);
    beginDateBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    beginDateBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [beginDateBtn addTarget:self action:@selector(changeDateTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:beginDateBtn];
    // 结束日期
    endDateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    endDateBtn.frame = CGRectMake(147,50,119,31);
    endDateBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    endDateBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [endDateBtn addTarget:self action:@selector(changeDateTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:endDateBtn];
    
    [super fillConditionView:view corpLine:2];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,plotContainer1, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"单船装卸效率分析";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    [HDSUtil changeUIControlFont:segment toSize:isSmallView?HDSFontSizeNormal:HDSFontSizeBig];
    
    headerNames = [NSArray arrayWithObjects:@"离港时间",@"船名",@"货名",@"操作过程",@"操作方法",@"操作吨",@"作业台时",@"装卸效率",nil];
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView1 toContainer:plotContainer1 title:@"各班次作业效率变化" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"作业效率",nil] useLegend:NO useLegendIcon:NO];
    
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
    
    [self segmentChanged:segment];
//    [self loadData];
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    
}

-(void)viewDidLayoutSubviews{
    if(isSmallView)
        return;
    [tableView adjustRightTableViewWidth];
    [tableView positionVerticalScrollBar];
    plotView1.frame = plotContainer1.bounds;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewDidUnload{
    [self setPlotContainer1:nil];
    [self setSegment:nil];
    [self setBeginDateBtn:nil];
    [self setEndDateBtn:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 8;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
//    return 2;
//}
// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column == 0) return 110.0f;
        if(column == 1) return 75.0f;
        return 65.0f;
    }
    if(column == 0) return 140.0f;
    if(column == 1) return 90.0f;
    return 80.0f;
}

- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
//    @"离港时间",@"船名",@"货名",@"操作过程",@"操作方法",@"操作吨",@"作业台时",@"装卸效率"
    switch (col) {
        case 0: return @"rtd";
        case 1: return @"ship";
        case 2: return @"cargo";
        case 3: return @"proc";
        case 4: return @"way";
        case 5: return @"wgt";
        case 6: return @"hours";
        case 7: return @"efficiency";
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

- (IBAction)segmentChanged:(UISegmentedControl *)sender {
    if(segment.selectedSegmentIndex == 0){
        qUnload = @"%2B";  // 转译＋
        unload = @"装船";
    }else{
        qUnload = @"-";
        unload = @"卸船";
    }
    [self loadData];
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    if(popupBtn == beginDateBtn){
        [beginDateBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year],[_dates month]] forState:UIControlStateNormal];
        qBeginDate = [NSString stringWithFormat:@"%d%02d",[_dates year] ,[_dates month]];
    }else if(popupBtn == endDateBtn){
        [endDateBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year],[_dates month]] forState:UIControlStateNormal];
        qEndDate = [NSString stringWithFormat:@"%d%02d",[_dates year] ,[_dates month]];
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
        return [(NSNumber *)[dict objectForKey:@"wgt"] doubleValue];
    }
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView)
        return nil;
    
	CPTTextLayer *newLayer = nil;
    double num = [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
    if(num > 0.1){
        newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.0f", 
            [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index]] style:[HDSUtil plotTextStyle:10]];
    }
    
	return newLayer;
}

#pragma mark - 数据读取相关
- (void)loadData {
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
	
    // 表格数据
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ShipLoadEfficiency_list" withExtension:@"json"]]];
    }else{
        NSString *url;
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SShipLoadRate/list.json?beginYM=%@&endYM=%@&unload=%@&corps=%@",qBeginDate,qEndDate==nil?qBeginDate:qEndDate,qUnload,qCompany];
        
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
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
        // 查询完数据默认选中第一行
        [tableView doSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }else if(parser == parser2){
         [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:array dataIsTreeNode:false  xLabelKey:@"time" yLabelKey:[NSArray arrayWithObjects:@"wgt",nil] yTitleWidth:0 plotNum:1];
    }
}

-(NSString *)transformXLabel:(NSString *)xLabel{
//    if(isSmallView){    // 去掉年度
        return [xLabel substringFromIndex:5];
//    }
//    return xLabel;
}

-(void)tableView:(HDSTableView *)tableView didSelectRowAtNode:(HDSTreeNode *)node{
    NSDictionary *prop = node.properties;
    
    adapter2 = [[SBJsonStreamParserAdapter alloc] init];
    adapter2.delegate = self;
    parser2 = [[SBJsonStreamParser alloc] init];
    parser2.delegate = adapter2;
    if([HDSUtil isOffline]){    // 离线数据
        [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ShipLoadEfficiency_chart" withExtension:@"json"]]];
    }else{
        NSString *url;
        url = [[[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SShipLoadRate/listChart.json?rtd=%@&ship=%@&cargoCod=%@&procCod=%@&wayCod=%@",[prop objectForKey:@"rtd"],[prop objectForKey:@"ship"],[prop objectForKey:@"cargoCod"],[prop objectForKey:@"procCod"],[prop objectForKey:@"wayCod"]] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }
    plotView1.hostedGraph.title = [NSString stringWithFormat:@"%@%@各班次作业效率变化",[prop objectForKey:@"ship"],unload ];
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"单船装卸效率分析");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"单船装卸效率分析");
	} else{
        //        NSLog(@"Parser over.");
    }
}

@end

