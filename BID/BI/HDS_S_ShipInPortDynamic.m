//
//  HDS_S_ThruputPlanComplete.m
//  集疏港计划完成情况
//
//  Created by 毅 张 on 12-7-4.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_S_ShipInPortDynamic.h"

#define One_Week 7*24*60*60
#define One_Day 24*60*60

@implementation HDS_S_ShipInPortDynamic{
    
    CPTGraphHostingView *plotView1;
    
    UIPopoverController *beginDatePopover;
    UIPopoverController *endDatePopover;
    
    NSURLConnection *conn1; // 表格数据
    SBJsonStreamParser *parser1;
    SBJsonStreamParserAdapter *adapter1;
    
    NSString *qBeginDate;
    NSString *qEndDate;
    
}

@synthesize plotContainer1;
@synthesize segment;
@synthesize beginDateBtn;
@synthesize endDateBtn;
@synthesize toLabel;
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
    // segment在港船/离港船
    segment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"在港船",@"离港船", nil]];
    segment.segmentedControlStyle = UISegmentedControlStylePlain;
    segment.frame = CGRectMake(20, 10, 139, 31);
    segment.selectedSegmentIndex = 0;
    [segment addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    [view addSubview:segment];
    // 开始日期
    beginDateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    beginDateBtn.frame = CGRectMake(20,50,119,31);
    beginDateBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    beginDateBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    beginDateBtn.hidden = true;  
    [beginDateBtn addTarget:self action:@selector(changeDateTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:beginDateBtn];
    // 结束日期
    endDateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    endDateBtn.frame = CGRectMake(147,50,119,31);
    endDateBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    endDateBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    endDateBtn.hidden = true;
    [endDateBtn addTarget:self action:@selector(changeDateTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:endDateBtn];
    [super fillConditionView:view corpLine:2];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,plotContainer1, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"船舶在港动态查询";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    [HDSUtil changeUIControlFont:segment toSize:isSmallView?HDSFontSizeNormal:HDSFontSizeBig];
    
    headerNames = [NSArray arrayWithObjects:@"船舶",@"状态",@"状态开始时间",@"状态结束时间",@"持续时间", nil];
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataMaxDepth = 2;
    tableView.dataSource = self;
//    tableView.treeInOneCell = YES; // 树状结构单列显示
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addPlotView:plotView1 toContainer:plotContainer1];
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot1 = [[NSMutableArray alloc] init];
    
    // 初始化默认月份
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *endDates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    [self refreshByDates:endDates fromPopupBtn:endDateBtn];
    NSDateComponents *beginDates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate dateWithTimeInterval:-One_Week sinceDate:[NSDate date]]];
    [self refreshByDates:beginDates fromPopupBtn:beginDateBtn];
    // 默认全部权限的公司
    [self refreshByComps:[HDSCompanyViewController companys]];
    
    [self segmentChanged:segment];
//    [self loadData];
}

-(void) addPlotView:(CPTGraphHostingView *)_plotView toContainer:(UIView *)container{
    _plotView.frame = container.bounds;
    _plotView.autoresizingMask =  UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _plotView.layer.borderColor = [HDSUtil plotBorderColor].CGColor;
    _plotView.layer.borderWidth = 1.0f;
    _plotView.layer.cornerRadius = isSmallView? Table_Corner_Small:Table_Corner;
    _plotView.layer.masksToBounds = true;
    [container addSubview:_plotView];
    
    CPTXYGraph *graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
	[graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
	_plotView.hostedGraph = graph;
    
    [HDSUtil setTitle:@"船舶在港动态变化图" forGraph:graph withFontSize:isSmallView?14.0f:16.0f];
    [HDSUtil setInnerPaddingTop:10.0 right:15.0 bottom:30.0 left:50.0 forGraph:graph];
    [HDSUtil setPadding:0 forGraph:graph withBounds:_plotView.bounds];
    
	// Axes
	CPTXYAxisSet *xyAxisSet = (id)graph.axisSet;
	CPTXYAxis *xAxis		= xyAxisSet.xAxis;
    CPTXYAxis *yAxis        = xyAxisSet.yAxis;
    [HDSUtil setAxis:xAxis majorIntervalLength:One_Day/2.0 minorTicksPerInterval:0 title:nil titleOffset:0 titleFontSize:0 labelFontSize:isSmallView?10.0f:12.0f];
    [HDSUtil setAxis:yAxis majorIntervalLength:1.0 minorTicksPerInterval:0 title:nil titleOffset:0 titleFontSize:0 labelFontSize:isSmallView?10.0f:12.0f];
	NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MM/dd HH:mm";
//	dateFormatter.dateStyle = kCFDateFormatterShortStyle;
//    dateFormatter.timeStyle = kCFDateFormatterShortStyle;
	CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
	xAxis.labelFormatter		= timeFormatter;
//    xAxis.labelRotation = M_PI/16;
    CPTMutableTextStyle *labelTextStyle = [CPTMutableTextStyle textStyle];
    labelTextStyle.fontName = @"STHeitiSC-Medium";
    labelTextStyle.fontSize = isSmallView?10.0f:12.0f;
    xAxis.labelTextStyle = labelTextStyle;
    if(isSmallView){
        xAxis.labelRotation = M_PI/8;
    }
    
    // 坐标轴端点的箭头样式
	CPTLineCap *lineCap = [[CPTLineCap alloc] init];
	lineCap.lineStyle	 = xAxis.axisLineStyle;
	lineCap.lineCapType	 = CPTLineCapTypeSweptArrow;
	lineCap.size		 = CGSizeMake(12.0, 15.0);
	lineCap.fill		 = [CPTFill fillWithColor:xAxis.axisLineStyle.lineColor];
	xAxis.axisLineCapMax = lineCap;
    
	yAxis.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0.5);
    
	CPTMutableShadow *whiteShadow = [CPTMutableShadow shadow];
	whiteShadow.shadowOffset	 = CGSizeMake(2.0, -2.0);
	whiteShadow.shadowBlurRadius = 4.0;
	whiteShadow.shadowColor		 = [CPTColor whiteColor];
    
	// OHLC plot
	CPTMutableLineStyle *whiteLineStyle = [CPTMutableLineStyle lineStyle];
	whiteLineStyle.lineColor = [CPTColor whiteColor];
	whiteLineStyle.lineWidth = 2.0;
    
	HDSYAxisRangePlot *ohlcPlot = [(HDSYAxisRangePlot *)[HDSYAxisRangePlot alloc] initWithFrame:graph.bounds];
	ohlcPlot.identifier = @"OHLC";
//	ohlcPlot.lineStyle	= whiteLineStyle;
//	CPTMutableTextStyle *whiteTextStyle = [CPTMutableTextStyle textStyle];
//	whiteTextStyle.color	 = [CPTColor whiteColor];
//	whiteTextStyle.fontSize	 = 12.0;
//	ohlcPlot.labelTextStyle	 = whiteTextStyle;
	ohlcPlot.labelOffset	 = 0.0;
	ohlcPlot.barCornerRadius = 0.0;
	ohlcPlot.barWidth		 = isSmallView?10.0f:15.0f;
    CPTGradient *gradient0 = [HDSUtil barChartGradientAtIndex:0];
    gradient0.angle = 90.0f;
    CPTGradient *gradient1 = [HDSUtil barChartGradientAtIndex:1];
    gradient1.angle = 90.0f;
	ohlcPlot.increaseFill	 =[CPTFill fillWithGradient:gradient0];;
	ohlcPlot.decreaseFill	 =[CPTFill fillWithGradient:gradient1];;
	ohlcPlot.dataSource		 = self;
	ohlcPlot.plotStyle		 = CPTTradingRangePlotStyleCandleStick;
    ohlcPlot.cachePrecision  = CPTPlotCachePrecisionDouble;
//	ohlcPlot.shadow			 = whiteShadow;
//	ohlcPlot.labelShadow	 = whiteShadow;
	[graph addPlot:ohlcPlot];
    
	// Set plot ranges
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.allowsUserInteraction = YES;
    // 使坐标轴固定且图表可以横向拖动
    xAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    yAxis.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    plotSpace.delegate = [HDSUtil getPlotDelegate];
    
	plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.5) length:CPTDecimalFromDouble(dataForPlot1.count+1)];
	plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromInteger(0) length:CPTDecimalFromInteger(3*One_Day)];
}

- (void)showLegend:(UIButton *)legendSwitch{
    legendSwitch.hidden = YES;
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    anim.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:0.0],nil ];
    anim.keyTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.2],[NSNumber numberWithFloat:0.8],[NSNumber numberWithInt:1.0],nil ];
    anim.duration = 5.0f;
    anim.removedOnCompletion = NO;
    anim.delegate			 = self;
    CPTLegend *theLegend = plotView1.hostedGraph.legend;
    [theLegend addAnimation:anim forKey:@"legendAnimation"];
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if(anim == [plotView1.hostedGraph.legend animationForKey:@"legendAnimation"]){
        [plotView1 viewWithTag:Legend_Switch_Tag].hidden = NO;
    }
}

-(void)viewDidLayoutSubviews{
    if(isSmallView)
        return;
    [tableView adjustRightTableViewWidth];
    [tableView positionVerticalScrollBar];
//    plotView1.frame = CGRectInset(plotContainer1.bounds,5.0f,5.0f);
    plotView1.frame = plotContainer1.bounds;
}

- (void)viewDidUnload{
    [self setPlotContainer1:nil];
    [self setSegment:nil];
    [self setBeginDateBtn:nil];
    [self setEndDateBtn:nil];
    [self setToLabel:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 5;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
//    return 2;
//}
// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column == 0 || column == 1) return 80.0f;
        if(column == 2 || column == 3) return 110.0f;
        return 60.0f;
    }
    if(column == 0 || column == 1) return 120.0f;
    if(column == 2 || column == 3) return 165.0f;
    return 87.0f;
}

- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"ship";
        case 1: return @"status";
        case 2: return @"beginStr";
        case 3: return @"endStr";
        case 4: return @"duration";
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
        HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearMonthDayPickerFormat popupBtn:beginDateBtn];
        picker.delegate = self;
        beginDatePopover= [[UIPopoverController alloc] initWithContentViewController:picker];
        beginDatePopover.popoverContentSize = picker.view.frame.size;
        beginDatePopover.delegate = picker;
    }
    if(endDatePopover == nil){
        HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearMonthDayPickerFormat popupBtn:endDateBtn];
        picker.delegate = self;
        endDatePopover= [[UIPopoverController alloc] initWithContentViewController:picker];
        endDatePopover.popoverContentSize = picker.view.frame.size;
        endDatePopover.delegate = picker;
    }
}

- (IBAction)segmentChanged:(UISegmentedControl *)sender {
    if(segment.selectedSegmentIndex == 0){
        beginDateBtn.hidden = true;
        endDateBtn.hidden = true;
        toLabel.hidden = true;
        if(!isSmallView){
            CGRect f = chooseCompBtn.frame; 
            f.origin.x = 163.0f;
            chooseCompBtn.frame = f;
            f = companyLabel.frame; 
            f.origin.x = 271.0f;
            f.size.width = 412.0f;
            companyLabel.frame = f; 
        }
        
    }else{
        beginDateBtn.hidden = false;
        endDateBtn.hidden = false;
        toLabel.hidden = false;
        if(!isSmallView){
            CGRect f = chooseCompBtn.frame; 
            f.origin.x = 422.0f;
            chooseCompBtn.frame = f;
            f = companyLabel.frame; 
            f.origin.x = 530.0f;
            f.size.width = 153.0f;
            companyLabel.frame = f;
        }
    }
    [self loadData];
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    if(popupBtn == beginDateBtn){
        [beginDateBtn setTitle:[NSString stringWithFormat:@"   %d-%02d-%02d",[_dates year],[_dates month],[_dates day]] forState:UIControlStateNormal];
        qBeginDate = [NSString stringWithFormat:@"%d%02d%02d",[_dates year] ,[_dates month],[_dates day]];
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
        [endDateBtn setTitle:[NSString stringWithFormat:@"   %d-%02d-%02d",[_dates year],[_dates month],[_dates day]] forState:UIControlStateNormal];
        qEndDate = [NSString stringWithFormat:@"%d%02d%02d",[_dates year] ,[_dates month],[_dates day]];
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

-(NSNumber *)numberForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index
{
	NSDecimalNumber *num ;
    
    num = [[dataForPlot1 objectAtIndex:index] objectForKey:[NSNumber numberWithUnsignedInteger:fieldEnum]];
//    NSLog(@"%d:%ld",fieldEnum,[num longValue]);
	return num;
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView)
        return nil;
    
	static CPTMutableTextStyle *whiteText = nil;
    
	if ( !whiteText ) {
		whiteText		= [[CPTMutableTextStyle alloc] init];
		whiteText.color = [CPTColor blackColor];
	}
    
	CPTTextLayer *newLayer = nil;
    newLayer = [[CPTTextLayer alloc] initWithText:@"test" style:whiteText];
    
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
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ShipInPortDynamic" withExtension:@"json"]]];
    }else{
        NSString *url;
        if(segment.selectedSegmentIndex == 0){  // 在港船
            url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SShipPortStatus/listIn.json?corps=%@",qCompany];
        }else{  // 离港船
            url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SShipPortStatus/listOut.json?begin=%@&end=%@&corps=%@",qBeginDate,qEndDate,qCompany];
        }
        
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
            [self loadChildren:node withData:data];
        }
        [tableView reloadData];
        // 查询完数据默认选中第一行
        [tableView doSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }
}

- (NSInteger)tableView:(HDSTableView *)tableView canBeExpandedColumnIndexAtNode:(HDSTreeNode *)node{
    return 0;
}

-(void)tableView:(HDSTableView *)tableView didSelectRowAtNode:(HDSTreeNode *)node{
    if(node.depth > 0 ){
        return;
    }
    [dataForPlot1 removeAllObjects];
    NSDictionary *firstNode = [(HDSTreeNode *)[node.children objectAtIndex:0] properties];
    NSDate *refDate = [NSDate dateWithTimeIntervalSince1970: [(NSNumber *)[firstNode objectForKey:@"begin"] doubleValue]/1000 ];
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    dateFormatter.dateFormat = @"MM/dd HH:mm";
//	dateFormatter.dateStyle = kCFDateFormatterShortStyle;
//    dateFormatter.timeStyle = kCFDateFormatterShortStyle;
	CPTTimeFormatter *timeFormatter = [[CPTTimeFormatter alloc] initWithDateFormatter:dateFormatter];
    timeFormatter.referenceDate = refDate;
	((CPTXYAxisSet *)plotView1.hostedGraph.axisSet).xAxis.labelFormatter= timeFormatter;
    
    NSDictionary *prop,*data;
    NSMutableArray *customLabels = [[NSMutableArray alloc] init];
    CPTAxisLabel *newLabel;
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)plotView1.hostedGraph.axisSet;
    CPTXYAxis *y = axisSet.yAxis;
    
    for(int i=0;i<node.children.count;i++){
        prop = [(HDSTreeNode *)[node.children objectAtIndex:i] properties];
        NSNumber *begin = [NSNumber numberWithDouble:
            [(NSNumber *)[prop objectForKey:@"begin"] doubleValue]/1000 - [(NSNumber *)[firstNode objectForKey:@"begin"] doubleValue]/1000];
        NSNumber *end;
        
        if([prop objectForKey:@"end"] == nil){
            // 离港船不显示最后一个状态的时间
            if(segment.selectedSegmentIndex == 1){
                continue;
            }
            // 在港船最后一个状态没有结束时间,取当前时间,反向显示
            end = begin;
            begin = [NSNumber numberWithDouble:
                     [[NSDate date] timeIntervalSince1970] - [(NSNumber *)[firstNode objectForKey:@"begin"] doubleValue]/1000];
        }else{
            end = [NSNumber numberWithDouble:
               [(NSNumber *)[prop objectForKey:@"end"] doubleValue]/1000 - [(NSNumber *)[firstNode objectForKey:@"begin"] doubleValue]/1000];
        }  
         
        data = [NSDictionary dictionaryWithObjectsAndKeys:
            [NSDecimalNumber numberWithDouble:i+1], 
            [NSNumber numberWithInt:HDSTradingRangePlotFieldX],
            begin,  [NSNumber numberWithLong:HDSTradingRangePlotFieldOpen],
            end,    [NSNumber numberWithLong:HDSTradingRangePlotFieldHigh],
            begin,  [NSNumber numberWithLong:HDSTradingRangePlotFieldLow],
            end,    [NSNumber numberWithLong:HDSTradingRangePlotFieldClose],
            nil];
        [dataForPlot1 addObject:data];
        newLabel = [[CPTAxisLabel alloc] initWithText:[prop objectForKey:@"status"]  textStyle:y.labelTextStyle];
        newLabel.tickLocation = CPTDecimalFromInt(i+1);
        newLabel.offset		  = y.labelOffset+5.0f;
        [customLabels addObject:newLabel];
    }
    y.axisLabels = [NSSet setWithArray:customLabels];
    CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)plotView1.hostedGraph.defaultPlotSpace;
	plotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromDouble(0.5) length:CPTDecimalFromDouble(dataForPlot1.count)];
      
    [plotView1.hostedGraph reloadData];
    [HDSUtil setAnimation:@"transform.scale.x" toLayer:[plotView1.hostedGraph plotAtIndex:0] fromValue:0.1 toValue:1 forKey:@"barScaleY"];
    
}

- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {
}

#pragma mark- NSURLConnectionDelegate methods
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //	NSLog(@"Connection didReceiveData of length: %u", data.length);
    SBJsonStreamParser *parser ; 
    if(connection == conn1){
        parser = parser1;
    }
    SBJsonStreamParserStatus status = [parser parse:data];
	if (status == SBJsonStreamParserError) {
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"船舶在港动态");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data");
	} else{
        //        NSLog(@"Parser over.");
    }
}

@end
