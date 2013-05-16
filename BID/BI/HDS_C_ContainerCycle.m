//
//  HDS_C_ContainerCycle.m
//  HDBI
//
//  Created by 毅 张 on 12-8-17.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#define L_Width 663
#define P_Width 728

#import "HDS_C_ContainerCycle.h"

@implementation HDS_C_ContainerCycle{
    
    CPTGraphHostingView *plotView1;
    CPTGraphHostingView *plotView2;
    CPTGraphHostingView *plotView3;
    
    UIPopoverController *datePopover;
    
    NSURLConnection *conn1; // 表格数据
    SBJsonStreamParser *parser1;
    SBJsonStreamParserAdapter *adapter1;
    
    NSString *qMonth;
}
@synthesize pageControl;

@synthesize plotContainer1;
@synthesize plotContainer2;
@synthesize plotContainer3;
@synthesize dataForPlot1;
@synthesize dataForPlot2;
@synthesize dataForPlot3;
@synthesize scrollView;
@synthesize monthBtn;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification]; 
    
    HDSSkinType skinType = [HDSUtil skinType];
    [monthBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal_110.png"] forState:UIControlStateNormal];
    [monthBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight_110.png"] forState:UIControlStateHighlighted];
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    [monthBtn setTitleColor:color forState:UIControlStateNormal];
    
    [self refreshPlotTheme:plotView1];
    [self refreshPlotTheme:plotView2];
    [self refreshPlotTheme:plotView3];
}

- (void)fillConditionView:(UIView *)view{
    // 年度
    monthBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    monthBtn.frame = CGRectMake(20,10,119,31);
    monthBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    monthBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [monthBtn addTarget:self action:@selector(changeMonthTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:monthBtn];
    
    [super fillConditionView:view];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,plotContainer1,plotContainer2,plotContainer3, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"集装箱周转时间统计";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    headerNames = [NSArray arrayWithObjects:@"航线",@"箱量",@"总堆天数",@"平均堆存天数",nil];
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    
    int width = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])? L_Width:P_Width;
    scrollView.contentSize = CGSizeMake(width*4, 286);  //scrollview的滚动范围
    scrollView.delegate = self;
    scrollView.layer.borderColor = [HDSUtil plotBorderColor].CGColor;
    scrollView.layer.borderWidth = 1.0f;
    scrollView.layer.cornerRadius = isSmallView? Table_Corner_Small:Table_Corner;
    scrollView.layer.masksToBounds = true;
    
    UIInterfaceOrientation orientation =[[UIApplication sharedApplication] statusBarOrientation];
    [self changePlotContainerFrame:plotContainer1 index:0 orientation:orientation];
    [self changePlotContainerFrame:plotContainer2 index:1 orientation:orientation];
    [self changePlotContainerFrame:plotContainer3 index:2 orientation:orientation];
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView1 toContainer:plotContainer1 title:@"航线箱量" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"箱量",nil] useLegend:NO useLegendIcon:NO];
    
    plotView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView2 toContainer:plotContainer2 title:@"总堆天数" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"总堆天数",nil] useLegend:NO useLegendIcon:NO];
    
    plotView3 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView3 toContainer:plotContainer3 title:@"平均堆存天数" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"平均天数",nil] useLegend:NO useLegendIcon:NO];
    
    if(!isSmallView){
        plotView1.layer.borderWidth = 0;
        plotView1.layer.cornerRadius = isSmallView? Table_Corner_Small:0;
        plotView2.layer.borderWidth = 0;
        plotView2.layer.cornerRadius = isSmallView? Table_Corner_Small:0;
        plotView3.layer.borderWidth = 0;
        plotView3.layer.cornerRadius = isSmallView? Table_Corner_Small:0;
    }
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot1 = [[NSMutableArray alloc] init];
    self.dataForPlot2 = [[NSMutableArray alloc] init];
    self.dataForPlot3 = [[NSMutableArray alloc] init];
    
    // 初始化默认月份
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:[NSDate date]];
    [self refreshByDates:dates fromPopupBtn:monthBtn];
    // 默认全部权限的公司
    [self refreshByComps:[HDSCompanyViewController companys]];
    [self loadData];
}

- (void)changePlotContainerFrame:(UIView *)container index:(NSInteger)index orientation:(UIInterfaceOrientation) orientation{
    if(isSmallView) return;
    int width = UIInterfaceOrientationIsLandscape(orientation)? L_Width:P_Width;
    CGRect f = container.frame;
    f.origin.x = index*width;
    f.size.width = width;
    container.frame = f;
}

//- (void)scrollViewDidScroll:(UIScrollView *)sender {
//    int width = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])? L_Width:P_Width;
//    int page = scrollView.contentOffset.x / width;
//    pageControl.currentPage = page;
//}
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
//
//}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)_scrollView{
    int width = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])? L_Width:P_Width;
    int page = _scrollView.contentOffset.x / width;
    pageControl.currentPage = page;
}


- (IBAction)changePage:(UIPageControl *)sender {
    int width = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])? L_Width:P_Width;
    int page = pageControl.currentPage;
    [scrollView setContentOffset:CGPointMake(width * page, 0)];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    if(isSmallView) return;
    UIInterfaceOrientation toOrientation = UIInterfaceOrientationIsLandscape(fromInterfaceOrientation)?UIInterfaceOrientationPortrait:UIInterfaceOrientationLandscapeLeft;
    [self changePlotContainerFrame:plotContainer1 index:0 orientation:toOrientation];
    [self changePlotContainerFrame:plotContainer2 index:1 orientation:toOrientation];
    [self changePlotContainerFrame:plotContainer3 index:2 orientation:toOrientation];
    int width = UIInterfaceOrientationIsLandscape(toOrientation)? L_Width:P_Width;
    scrollView.contentSize = CGSizeMake(width*4, 286); 
    [self changePage:nil];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    
}

//- (void)showLegend:(UIButton *)legendSwitch{
//    legendSwitch.hidden = YES;
//    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
//    anim.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:0.0],nil ];
//    anim.keyTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.2],[NSNumber numberWithFloat:0.8],[NSNumber numberWithInt:1.0],nil ];
//    anim.duration = 5.0f;
//    anim.removedOnCompletion = NO;
//    anim.delegate			 = self;
//    CPTLegend *theLegend = plotView1.hostedGraph.legend;
//    [theLegend addAnimation:anim forKey:@"legendAnimation"];
//}
//
//-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
//    if(anim == [plotView1.hostedGraph.legend animationForKey:@"legendAnimation"]){
//        [plotView1 viewWithTag:Legend_Switch_Tag].hidden = NO;
//    }
//}

-(void)viewDidLayoutSubviews{
    if(isSmallView)
        return;
    [tableView adjustRightTableViewWidth];
    [tableView positionVerticalScrollBar];
    plotView1.frame = plotContainer1.bounds;
    plotView2.frame = plotContainer2.bounds;
    plotView3.frame = plotContainer3.bounds;
}

- (void)viewDidUnload{
    [self setPlotContainer1:nil];
    [self setScrollView:nil];
    [self setPageControl:nil];
    [self setPlotContainer2:nil];
    [self setPlotContainer3:nil];
    [self setDataForPlot1:nil];
    [self setDataForPlot2:nil];
    [self setDataForPlot3:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 4;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
//    return 2;
//}

// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
//        if(column==0)   return 160.0f;
//        if(column==1)   return 90.0f;
        return 80.0f;
    }
    if(column==0)   return 148.0f;
    return 170.0f;
}

- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"line";
        case 1: return @"cntrNum";
        case 2: return @"totalDays";
        case 3: return @"avgDays";
        default:return @"";
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

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    NSString *graphId = (NSString *)plot.graph.identifier;
    NSString *plotProp;
    if([graphId isEqualToString:@"航线箱量"]){
        plotProp = @"cntrNum";
    }else if([graphId isEqualToString:@"总堆天数"]){
        plotProp = @"totalDays";
    }else if([graphId isEqualToString:@"平均堆存天数"]){
        plotProp = @"avgDays";
    }
    if(fieldEnum == CPTBarPlotFieldBarLocation ){
        return index+1;
    }else{  //CPTBarPlotFieldBarTip
        NSDictionary *dict = [(HDSTreeNode *)[dataForPlot1 objectAtIndex:index] properties];
        return [(NSNumber *)[dict objectForKey:plotProp] doubleValue];
    }
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView)
        return nil;
    
	CPTTextLayer *newLayer = nil;
    NSString *format ;
    NSString *graphId = (NSString *)plot.graph.identifier;
    if([graphId isEqualToString:@"航线箱量"]){
        format = @"%.0f";
    }else if([graphId isEqualToString:@"总堆天数"]){
        format = @"%.1f";
    }else if([graphId isEqualToString:@"平均堆存天数"]){
        format = @"%.2f";
    }
    double num = [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
    newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:format, 
                                                num] style:[HDSUtil plotTextStyle:10]];
    
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
	
    // 表格数据
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ContainerCycleGrid" withExtension:@"json"]]];
    }else{
        NSString *url;
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CContainerCycle/list.json?yearMonth=%@&corps=%@",qMonth,qCompany];
        
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }
    
}

#pragma mark SBJsonStreamParserAdapterDelegate methods
- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
    NSDictionary *data;
    NSMutableDictionary *prop;
    if(parser == parser1){
        HDSTreeNode *node;
        [self.rootArray removeAllObjects];
        for(int i=0; i<array.count; i++){
            data = [array objectAtIndex:i];
            prop = (NSMutableDictionary *)[data objectForKey:@"properties"];
            node = [[HDSTreeNode alloc] initWithProperties:prop parent:nil expanded:YES];
            [self.rootArray addObject:node];
        }
        [tableView reloadData];
        
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:self.rootArray dataIsTreeNode:true  xLabelKey:@"line" yLabelKey:[NSArray arrayWithObjects:@"cntrNum",nil] yTitleWidth:0 plotNum:1];
        [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot2 data:self.rootArray dataIsTreeNode:true  xLabelKey:@"line" yLabelKey:[NSArray arrayWithObjects:@"totalDays",nil] yTitleWidth:0 plotNum:1];
        [self refreshBarPlotView:plotView3 dataForPlot:dataForPlot3 data:self.rootArray dataIsTreeNode:true  xLabelKey:@"line" yLabelKey:[NSArray arrayWithObjects:@"avgDays",nil] yTitleWidth:0 plotNum:1];
    }
}

//-(NSString *)transformXLabel:(NSString *)xLabel{
//    if(xLabel.length>10){
//        return [[xLabel substringWithRange:NSMakeRange(0, 10)] stringByAppendingString:@"..."];
//    }
//    return xLabel;
//}

- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //	NSLog(@"Connection didReceiveData of length: %u", data.length);
    SBJsonStreamParser *parser ; 
    if(connection == conn1){
        parser = parser1;
    }
    SBJsonStreamParserStatus status = [parser parse:data];
	if (status == SBJsonStreamParserError) {
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"集装箱周转时间统计");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"集装箱周转时间统计");
	} else{
        
    }
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    [monthBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year] ,[_dates month]] forState:UIControlStateNormal];
    qMonth = [NSString stringWithFormat:@"%d%02d",[_dates year] ,[_dates month]];
}

- (IBAction)changeMonthTaped:(UIButton *)sender {
    if(datePopover == nil){
        HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearMonthPickerFormat popupBtn:sender];
        picker.delegate = self;
        datePopover= [[UIPopoverController alloc] initWithContentViewController:picker];
        datePopover.popoverContentSize = picker.view.frame.size;
        datePopover.delegate = picker;
    }
    [datePopover presentPopoverFromRect:monthBtn.frame inView:[monthBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

@end
