//
//  HDS_C_BerthUseRate.m
//  HDBI
//
//  Created by 毅 张 on 12-8-28.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_C_BerthUseRate.h"

@implementation HDS_C_BerthUseRate{
    
    CPTGraphHostingView *plotView1;
    CPTGraphHostingView *plotView2;
    
    UIPopoverController *beginMonthPopover;
    UIPopoverController *endMonthPopover;
    
    NSURLConnection *conn1; // 表格数据
    NSURLConnection *conn2; // 环比图表
    NSURLConnection *conn3; // 同比图表
    SBJsonStreamParser *parser1;
    SBJsonStreamParser *parser2;
    SBJsonStreamParser *parser3;
    SBJsonStreamParserAdapter *adapter1;
    SBJsonStreamParserAdapter *adapter2;
    SBJsonStreamParserAdapter *adapter3;
    
    NSString *qBeginDate;
    NSString *qEndDate;
}

@synthesize barContainer1,barContainer2;
@synthesize dataForPlot1,dataForPlot2;
@synthesize beginDateBtn;
@synthesize endDateBtn;
@synthesize toLabel;

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
    [self refreshPlotTheme:plotView2];
}

- (void)refreshPlotTheme:(CPTGraphHostingView *)plotView{
    plotView.layer.borderColor = [HDSUtil plotBorderColor].CGColor;
    CPTGraph *graph = plotView.hostedGraph;
    NSArray *axes = graph.axisSet.axes;
    [HDSUtil setAxis:[axes objectAtIndex:0] titleFontSize:0 labelFontSize:isSmallView?10.0f:12.0f];
    [HDSUtil setAxis:[axes objectAtIndex:1] titleFontSize:isSmallView?12.0f:14.0f labelFontSize:isSmallView?10.0:12.0];
    [HDSUtil setAxis:[axes objectAtIndex:2] titleFontSize:isSmallView?12.0f:14.0f labelFontSize:isSmallView?10.0:12.0];
    graph.titleTextStyle = [HDSUtil plotTextStyle:isSmallView?14.0f:16.0f];
    graph.fill = [HDSUtil plotBackgroundFill];
    graph.legend.textStyle = [HDSUtil plotTextStyle:isSmallView?12.0f:14.0f];
    [graph.legend setNeedsDisplay];
    UIButton *legendSwitch = (UIButton *)[plotView viewWithTag:Legend_Switch_Tag];
    [legendSwitch setImage:[HDSUtil loadImageSkin:[HDSUtil skinType] imageName:@"tile_legend.png"] forState:UIControlStateNormal];
    for(CPTPlot *plot in [graph allPlots])  [plot reloadData];
}

- (void)fillConditionView:(UIView *)view{
    // 开始日期
    beginDateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    beginDateBtn.frame = CGRectMake(20,10,119,31);
    beginDateBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    beginDateBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [beginDateBtn addTarget:self action:@selector(changeMonthTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:beginDateBtn];
    // 结束日期
    endDateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    endDateBtn.frame = CGRectMake(147,10,119,31);
    endDateBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    endDateBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [endDateBtn addTarget:self action:@selector(changeMonthTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:endDateBtn];
    
    [super fillConditionView:view];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,barContainer1,barContainer2, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"泊位利用率分析";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    headerNames = [NSArray arrayWithObjects:@"泊位名称",@"泊位长度",@"日历小时",@"占用小时",@"作业小时",@"吞吐量",@"泊位占用率",@"泊位利用率",@"每米码头吞吐量",nil];
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    tableView.dataMaxDepth = 2;
    tableView.treeInOneCell = YES;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self constructPlotInView:plotView1 container:barContainer1 title:@"泊位指标环比变化趋势"];
    plotView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self constructPlotInView:plotView2 container:barContainer2 title:@"泊位指标同比变化趋势"];
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot1 = [[NSMutableArray alloc] init];
    self.dataForPlot2 = [[NSMutableArray alloc] init];
    
    // 初始化默认月份
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:[NSDate date]];
    [self refreshByDates:dates fromPopupBtn:beginDateBtn];
    [self refreshByDates:dates fromPopupBtn:endDateBtn];
    // 初始化默认公司
    [self refreshByComps:[HDSCompanyViewController companys]];
    
    [self loadData];
}

-(void)constructPlotInView:(CPTGraphHostingView *)_plotView container:(UIView *)container title:(NSString *)title {
    _plotView.frame = container.bounds;
    _plotView.autoresizesSubviews = false;
    _plotView.autoresizingMask =  UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _plotView.layer.borderColor = [HDSUtil plotBorderColor].CGColor;
    _plotView.layer.borderWidth = 1.0f;
    _plotView.layer.cornerRadius = isSmallView? Table_Corner_Small:Table_Corner;
    _plotView.layer.masksToBounds = true;
    [container addSubview:_plotView];
    
    CPTXYGraph *graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
	[graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
	_plotView.hostedGraph = graph;
    
    [HDSUtil setTitle:title forGraph:graph withFontSize:isSmallView?14.0f:16.0f];
    [HDSUtil setInnerPaddingTop:6.0 right:15.0 bottom:25.0 left:0.0 forGraph:graph];
    [HDSUtil setPadding:0 forGraph:graph withBounds:_plotView.bounds];
    
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
    plotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.5) length:CPTDecimalFromFloat(12.0)];
    
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
	CPTXYAxis *x = axisSet.xAxis;
    [HDSUtil setAxis:x majorIntervalLength:1.0 minorTicksPerInterval:0 title:nil titleOffset:35 titleFontSize:isSmallView?12.0f:14.0f labelFontSize:isSmallView?10.0f:12.0f ];
    // 自定义坐标轴label
	x.labelingPolicy = CPTAxisLabelingPolicyNone;
    
	CPTXYAxis *y = axisSet.yAxis;
    [HDSUtil setAxis:y majorIntervalLength:0 minorTicksPerInterval:0 title:@"占用率/作业率(%)" titleOffset:35 titleFontSize:isSmallView?12.0f:14.0f labelFontSize:isSmallView?10.0f:12.0f];
    y.orthogonalCoordinateDecimal = CPTDecimalFromCGFloat(0.5);
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    y.labelFormatter = nf;
    
    // 双y轴
    CPTXYPlotSpace *newPlotSpace = (CPTXYPlotSpace *)[graph newPlotSpace];
    newPlotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.5) length:CPTDecimalFromFloat(12.0)];
    [graph addPlotSpace:newPlotSpace];
    
    plotSpace.allowsUserInteraction = NO;
    newPlotSpace.allowsUserInteraction = NO;
    
    CPTXYAxis *y2 = [[CPTXYAxis alloc] init];
    y2.coordinate = CPTCoordinateY;
    [HDSUtil setAxis:y2 majorIntervalLength:0 minorTicksPerInterval:0 title:@"每米码头吞吐量(吨)" titleOffset:35.0 titleFontSize:isSmallView?12.0f:14.0f labelFontSize:isSmallView?10.0f:12.0f];
    y2.orthogonalCoordinateDecimal = CPTDecimalFromCGFloat(12.5);
    y2.tickDirection = CPTSignPositive;
    y2.plotSpace = newPlotSpace;
    y2.labelFormatter = nf;
    graph.axisSet.axes = [NSArray arrayWithObjects:x, y, y2, nil];
    
    // 线图
	CPTScatterPlot *linePlot = [[CPTScatterPlot alloc] init];
	linePlot.identifier = @"吞吐量";
    
	CPTMutableLineStyle *lineStyle = [linePlot.dataLineStyle mutableCopy];
	lineStyle.lineWidth				 = 2.0f;
	lineStyle.lineColor				 = [CPTColor colorWithCGColor:[HDSUtil lineChartColorAtIndex:2].CGColor];
	linePlot.dataLineStyle = lineStyle;
	linePlot.dataSource = self;
    
    // 线图节点形状
    CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    plotSymbol.fill			 = [CPTFill fillWithColor:[CPTColor colorWithCGColor:[HDSUtil lineChartPointColorAtIndex:2].CGColor]];
    plotSymbol.lineStyle	 = nil;
    CGFloat symbolSize = isSmallView?5.0f:8.0f;
    plotSymbol.size	= CGSizeMake(symbolSize, symbolSize);
    linePlot.plotSymbol = plotSymbol;
    
	// 柱状图
    CPTBarPlot *barPlot= [CPTBarPlot tubularBarPlotWithColor:[CPTColor clearColor] horizontalBars:NO];
    barPlot.fill	   = [CPTFill fillWithGradient:[HDSUtil barChartGradientAtIndex:0]];
    barPlot.lineStyle  = nil;   //[HDSUtil plotBorderStyle];
    barPlot.baseValue  = CPTDecimalFromString(@"0");
    barPlot.dataSource = self;
    barPlot.barCornerRadius = 0.0f;
    barPlot.identifier = @"占用率";
    barPlot.barOffset  = CPTDecimalFromFloat(-0.2f);
    barPlot.barWidth = CPTDecimalFromFloat(0.4f);
    barPlot.labelOffset = 1.0f;
    [graph addPlot:barPlot toPlotSpace:plotSpace ];
    
    CPTBarPlot *barPlot2= [CPTBarPlot tubularBarPlotWithColor:[CPTColor clearColor] horizontalBars:NO];
    barPlot2.fill	   = [CPTFill fillWithGradient:[HDSUtil barChartGradientAtIndex:1]];
    barPlot2.lineStyle  = nil;   //[HDSUtil plotBorderStyle];
    barPlot2.baseValue  = CPTDecimalFromString(@"0");
    barPlot2.dataSource = self;
    barPlot2.barCornerRadius = 0.0f;
    barPlot2.identifier = @"作业率";
    barPlot2.barOffset  = CPTDecimalFromFloat(+0.2f);
    barPlot2.barWidth = CPTDecimalFromFloat(0.4f);
    barPlot2.labelOffset = 1.0f;
    [graph addPlot:barPlot2 toPlotSpace:plotSpace ];
    
    // 最后增加linePlot保证不被barPlot挡住
    [graph addPlot:linePlot toPlotSpace:newPlotSpace];
    
    CPTLegend *theLegend = [CPTLegend legendWithGraph:graph];
    theLegend.fill = [CPTFill fillWithColor:[CPTColor clearColor]];
    if(isSmallView){
        theLegend.fill = [CPTFill fillWithColor:[CPTColor grayColor]];
        UIButton *legendSwitch = [UIButton buttonWithType:UIButtonTypeCustom];
        legendSwitch.tag = Legend_Switch_Tag;
        [legendSwitch setImage:[HDSUtil loadImageSkin:[HDSUtil skinType] imageName:@"tile_legend.png"] forState:UIControlStateNormal];
        legendSwitch.frame = CGRectMake(_plotView.bounds.size.width-29-5, 5, 29, 29);
        // 图表内y坐标系相反，需要旋转图例图标
        legendSwitch.layer.transform =CATransform3DRotate(CATransform3DRotate(CATransform3DIdentity, M_PI, 0, 0, 1.0),M_PI, 0, 1.0, 0);
        [legendSwitch addTarget:self action:@selector(showLegend:) forControlEvents:UIControlEventTouchUpInside];
        [_plotView addSubview:legendSwitch];
        theLegend.opacity = 0;
        [HDSUtil setLegend:theLegend withCorner:5.0 swatch:10.0 font:12.0 rowMargin:5.0 numberOfRows:0 padding:3.0];
        theLegend.numberOfColumns = 1;
        graph.legendAnchor		 = CPTRectAnchorBottomRight;
        graph.legendDisplacement = CGPointMake(0.0, 0.0);
        
    }else{
        [HDSUtil setLegend:theLegend withCorner:5.0 swatch:12.0 font:14.0 rowMargin:5.0 numberOfRows:1 padding:5.0];
        graph.legendAnchor		 = CPTRectAnchorTopRight;
        graph.legendDisplacement = CGPointMake(0.0, 0.0);
    }
	graph.legend = theLegend;
}

- (void)showLegend:(UIButton *)legendSwitch{
    legendSwitch.hidden = YES;
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    anim.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:0.0],nil ];
    anim.keyTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.2],[NSNumber numberWithFloat:0.8],[NSNumber numberWithInt:1.0],nil ];
    anim.duration = 5.0f;
    anim.removedOnCompletion = NO;
    anim.delegate			 = self;
    CPTLegend *theLegend = ((CPTGraphHostingView *)[legendSwitch superview]).hostedGraph.legend;
    [theLegend addAnimation:anim forKey:@"legendAnimation"];
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if(anim == [plotView1.hostedGraph.legend animationForKey:@"legendAnimation"]){
        [plotView1 viewWithTag:Legend_Switch_Tag].hidden = NO;
    }else if(anim == [plotView2.hostedGraph.legend animationForKey:@"legendAnimation"]){
        [plotView2 viewWithTag:Legend_Switch_Tag].hidden = NO;
    }
}

-(NSInteger)xAxisMaxCount:(NSInteger)plotNum plotView:(CPTGraphHostingView *)_plotView{
    return 12;
}

-(void)viewDidLayoutSubviews{
    if(isSmallView)
        return;
    [tableView adjustRightTableViewWidth];
    [tableView positionVerticalScrollBar];
    plotView1.frame = barContainer1.bounds;
    plotView2.frame = barContainer2.bounds;
}


- (void)viewDidUnload{
    [self setBarContainer1:nil];
    [self setBarContainer2:nil];
    [self setBeginDateBtn:nil];
    [self setEndDateBtn:nil];
    [self setToLabel:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 9;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
//    return 1;
//}

// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column == 0) return 90;
        if(column <= 4) return 65;
        if(column == 5) return 90;
        if(column <= 7) return 70;
        return 100;
    }
    if(column == 0) return 100;
    if(column <= 4) return 80;
    if(column == 5) return 105;
    if(column <= 7) return 90;
    return 120;
}

// @"泊位名称",@"泊位长度",@"日历小时",@"占用小时",@"作业小时",@"吞吐量",@"泊位占用率",@"泊位利用率",@"每米码头吞吐量"
- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return node.depth == 0?  @"corp":@"berth";
        case 1: return @"length";
        case 2: return @"calTim";
        case 3: return @"occuTim";
        case 4: return @"workTim";
        case 5: return @"teuNum";
        case 6: return @"occuRate";
        case 7: return @"workRate";
        case 8: return @"meterTeu";
        default:return @""; 
    }
}

-(NSInteger)tableView:(HDSTableView *)tableView canBeExpandedColumnIndexAtNode:(HDSTreeNode *)node{
    return 0;
}

-(void)tableView:(HDSTableView *)tableView didSelectRowAtNode:(HDSTreeNode *)node{
    if(node.depth == 0) return ;
    NSString *corpNam=[node.parent.properties objectForKey:@"corp"];
    NSString *corpCod=[node.parent.properties objectForKey:@"corpCod"];
    NSString *berthNam=[node.properties objectForKey:@"berth"];
    NSString *berthCod=[node.properties objectForKey:@"berthCod"];
    
    NSString *urlHB,*urlTB;
    NSURLRequest *theRequest;
    adapter2 = [[SBJsonStreamParserAdapter alloc] init];
    adapter2.delegate = self;
    adapter3 = [[SBJsonStreamParserAdapter alloc] init];
    adapter3.delegate = self;
    parser2 = [[SBJsonStreamParser alloc] init];
    parser2.delegate = adapter2;
    parser3 = [[SBJsonStreamParser alloc] init];
    parser3.delegate = adapter3;
    
    if([HDSUtil isOffline]){    // 离线数据
        [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_BerthUseRateChart1" withExtension:@"json"]]];
        [parser3 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_BerthUseRateChart2" withExtension:@"json"]]];
    }else{
        urlHB = [[[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CBerthUseRate/listHbChart.json?beginYM=%@&endYM=%@&corpCod=%@&berthCod=%@",qBeginDate,qEndDate,corpCod,berthCod] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        urlTB = [[[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CBerthUseRate/listTbChart.json?beginYM=%@&endYM=%@&corpCod=%@&berthCod=%@",qBeginDate,qEndDate,corpCod,berthCod] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:urlHB] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:urlTB] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn3 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }
    plotView1.hostedGraph.title = [NSString stringWithFormat:@"%@%@泊位指标环比变化趋势",corpNam,berthNam];
    plotView2.hostedGraph.title = [NSString stringWithFormat:@"%@%@泊位指标同比变化趋势",corpNam,berthNam];
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    if(popupBtn == nil){    // smallView 时初始化没有按钮
        qBeginDate = [NSString stringWithFormat:@"%d%02d",[_dates year],[_dates month]];
        qEndDate = [NSString stringWithFormat:@"%d%02d",[_dates year],[_dates month]];
        return;
    }
    
    if(popupBtn == beginDateBtn){
        [beginDateBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year],[_dates month]] forState:UIControlStateNormal];
        qBeginDate = [NSString stringWithFormat:@"%d%02d",[_dates year],[_dates month]];
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
            ((HDSYearMonthPicker *)endMonthPopover.contentViewController).scrollToDate = currentEndDate;
        }
    }else if(popupBtn == endDateBtn){
        [endDateBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year],[_dates month]] forState:UIControlStateNormal];
        qEndDate = [NSString stringWithFormat:@"%d%02d",[_dates year],[_dates month]];
        currentEndDate = _dates;
        // 若开始月份大于结束月份，则自动更新为结束月份
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *bDate = [calendar dateFromComponents:currentBeginDate];
        NSDate *eDate = [calendar dateFromComponents:currentEndDate];
        if([bDate timeIntervalSinceDate:eDate]>0){
            [beginDateBtn setTitle:[endDateBtn titleForState:UIControlStateNormal] forState:UIControlStateNormal];
            qBeginDate = qEndDate;
            currentBeginDate = [currentEndDate copy];
            ((HDSYearMonthPicker *)beginMonthPopover.contentViewController).scrollToDate = currentBeginDate;
        }
    } 
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
    if ( plot == [plotView1.hostedGraph plotAtIndex:0] || plot == [plotView1.hostedGraph plotAtIndex:1] || plot == [plotView1.hostedGraph plotAtIndex:2]) {
		return [dataForPlot1 count];
	}else if ( plot == [plotView2.hostedGraph plotAtIndex:0] || plot == [plotView2.hostedGraph plotAtIndex:1] || plot == [plotView2.hostedGraph plotAtIndex:2]) {
		return [dataForPlot2 count];
	}else {
		return 0;
	}
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    if ( [plot isKindOfClass:[CPTScatterPlot class]]){
        if(fieldEnum == CPTScatterPlotFieldX){
            return index+1;
        }else{  //CPTScatterPlotFieldY
            NSDictionary *dict;
            if(plot == [plotView1.hostedGraph plotAtIndex:2]){
                dict = [dataForPlot1 objectAtIndex:index];
            }else if(plot == [plotView2.hostedGraph plotAtIndex:2]){
                dict = [dataForPlot2 objectAtIndex:index];
            }
            return [(NSNumber *)[dict objectForKey:@"meterTeu"] doubleValue];
        }
    }else if( [plot isKindOfClass:[CPTBarPlot class]] ){
        if(fieldEnum == CPTBarPlotFieldBarLocation ){
            return index+1;
        }else{  //CPTBarPlotFieldBarTip
            NSDictionary *dict;
            if(plot == [plotView1.hostedGraph plotAtIndex:0] || plot == [plotView1.hostedGraph plotAtIndex:1]){
                dict = [dataForPlot1 objectAtIndex:index];
                if(plot == [plotView1.hostedGraph plotAtIndex:0]){
                    return [(NSNumber *)[dict objectForKey:@"occuRate"] doubleValue];
                }else{
                    return [(NSNumber *)[dict objectForKey:@"workRate"] doubleValue];
                }
            }else if(plot == [plotView2.hostedGraph plotAtIndex:0] || plot == [plotView2.hostedGraph plotAtIndex:1]){
                dict = [dataForPlot2 objectAtIndex:index];
                if(plot == [plotView2.hostedGraph plotAtIndex:0]){
                    return [(NSNumber *)[dict objectForKey:@"occuRate"] doubleValue];
                }else{
                    return [(NSNumber *)[dict objectForKey:@"workRate"] doubleValue];
                }
            }
        }
    }
    return 0;
    
}

//-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
//    if(isSmallView && ![plot isKindOfClass:[CPTPieChart class]] )
//        return nil;
//    
//    CPTTextLayer *newLayer;
//    double num = [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
//    if(num > 0){
//        newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.2f", num] style:[HDSUtil plotTextStyle:10]];
//    }
//	return newLayer;
//}

//-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index{
//    CPTGradient *newInstance = [HDSUtil pieChartGradientAtIndex:index];
//    newInstance.angle = 270.0f;
//	return [CPTFill fillWithGradient:newInstance];
//}

//-(NSString *)legendTitleForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index{
//    HDSTreeNode *node = [dataForPlot objectAtIndex:index];
//	return [node.properties objectForKey:[NSString stringWithFormat:@"name%i",node.depth+1]];
//}

#pragma mark - 数据读取相关
- (void)loadData {
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
    
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_BerthUseRateGrid" withExtension:@"json"]]];
    }else{
        // 表格数据
        NSString *url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CBerthUseRate/list.json?beginYM=%@&endYM=%@&corps=%@",qBeginDate,qEndDate,qCompany];
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
            NSMutableDictionary *prop = [data objectForKey:@"properties"];
            node = [[HDSTreeNode alloc] initWithProperties:prop parent:nil expanded:YES];
            [self.rootArray addObject:node];
            [self loadChildren:node withData:data];
        }
        [tableView reloadData];
        // 查询完数据默认选中第二行
        if(self.rootArray.count>0 && [tableView.rightTableView numberOfRowsInSection:0]>1){
            [tableView doSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        }
        
    }else if(parser == parser2){
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:array dataIsTreeNode:false  xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"occuRate",@"workRate",@"meterTeu",nil] yTitleWidth:isSmallView?16.0f:18.0f plotNum:1];
        
    }else if(parser == parser3){
        [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot2 data:array dataIsTreeNode:false  xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"occuRate",@"workRate",@"meterTeu",nil] yTitleWidth:isSmallView?16.0f:18.0f plotNum:1];
    } 
}

-(void) refreshBarPlotView:(CPTGraphHostingView *)_plotView dataForPlot:(NSMutableArray *)_dataForPlot data:(NSArray *)array dataIsTreeNode:(BOOL)dataIsTreeNode xLabelKey:(NSString *)xLabelKey yLabelKey:(NSArray *)yLabelKey yTitleWidth:(CGFloat)yTitleWidth plotNum:(NSInteger)plotNum{
    
    [_dataForPlot removeAllObjects];
    [_dataForPlot addObjectsFromArray:array];
    NSMutableArray *customLabels = [[NSMutableArray alloc] init];
    CPTAxisLabel *newLabel;
    float maxY = 0.0f,maxY2 = 0.0f;
    float maxX = 0.0f,maxHeight = 0.0f;
    int xAxisMaxCount ;
    NSArray *axisSet = _plotView.hostedGraph.axisSet.axes;
    CPTXYAxis *x = [axisSet objectAtIndex:0];
    xAxisMaxCount = [self xAxisMaxCount:plotNum plotView:_plotView];
    
    for (int i=0;i<_dataForPlot.count;i++ ) {
        NSDictionary *_data = [_dataForPlot objectAtIndex:i];
        NSString *xLabel = [_data objectForKey:xLabelKey];
        
        CGSize s = [xLabel sizeWithFont:[UIFont fontWithName:x.labelTextStyle.fontName size:x.labelTextStyle.fontSize] constrainedToSize:CGSizeMake(MAXFLOAT, 30) lineBreakMode:UILineBreakModeWordWrap];
        maxX = MAX(maxX, s.width);
        maxHeight = MAX(maxHeight, s.height);
        
        newLabel = [[CPTAxisLabel alloc] initWithText:xLabel textStyle:x.labelTextStyle];
        newLabel.tickLocation = CPTDecimalFromInt(i+1);
        newLabel.offset		  = x.labelOffset+5.0f;
        [customLabels addObject:newLabel];
        
        for(int j = 0;j<2; j++){
            NSNumber *y = [_data objectForKey:[yLabelKey objectAtIndex:j] ];
            maxY = MAX(maxY,[y floatValue]);
        }
        NSNumber *y = [_data objectForKey:[yLabelKey objectAtIndex:2] ];
        maxY2 = MAX(maxY2,[y floatValue]);
    }
    
    float plotWidth = _plotView.hostedGraph.plotAreaFrame.plotArea.frame.size.width ;
    if(plotWidth == 0){
        plotWidth = _plotView.hostedGraph.bounds.size.width - 50;
    }
    float perBarWidth = plotWidth/MIN(_dataForPlot.count,xAxisMaxCount);
    if(maxX>perBarWidth){
        float radian = acosf(perBarWidth/maxX)/2;
        for(newLabel in customLabels){
            newLabel.rotation = radian;
        }
        _plotView.hostedGraph.plotAreaFrame.paddingBottom = maxX * sinf(radian)+maxHeight;
    }else{
        _plotView.hostedGraph.plotAreaFrame.paddingBottom = 25.0f;
    }
    
    x.axisLabels = [NSSet setWithArray:customLabels];
    CPTXYAxis *y1 = [_plotView.hostedGraph.axisSet.axes objectAtIndex:1];
    CPTXYAxis *y2 = [_plotView.hostedGraph.axisSet.axes objectAtIndex:2];
    
    // y轴label宽度根据数字长度调节
    CGSize yLabelSize = [[NSString stringWithFormat:@"%.0f",maxY*1.2] sizeWithFont:[UIFont fontWithName:y1.labelTextStyle.fontName size:y1.labelTextStyle.fontSize] constrainedToSize:CGSizeMake(MAXFLOAT, 30) lineBreakMode:UILineBreakModeWordWrap];
    y1.titleOffset = yLabelSize.width +5.0f/*tick宽度*/+5.0f/*title与label的空白*/;
    _plotView.hostedGraph.plotAreaFrame.paddingLeft = y1.titleOffset+yTitleWidth/*title宽度*/;
    
    yLabelSize = [[NSString stringWithFormat:@"%.0f",maxY2*1.2] sizeWithFont:[UIFont fontWithName:y2.labelTextStyle.fontName size:y2.labelTextStyle.fontSize] constrainedToSize:CGSizeMake(MAXFLOAT, 30) lineBreakMode:UILineBreakModeWordWrap];
    y2.titleOffset = yLabelSize.width +5.0f/*tick宽度*/+5.0f/*title与label的空白*/;
    _plotView.hostedGraph.plotAreaFrame.paddingRight = y2.titleOffset+yTitleWidth/*title宽度*/;
    
    //    ((CPTXYPlotSpace *)[_plotView.hostedGraph plotSpaceAtIndex:0]).xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.5) length:CPTDecimalFromInteger(MIN(_dataForPlot.count,xAxisMaxCount)  ) ];
    ((CPTXYPlotSpace *)[_plotView.hostedGraph plotSpaceAtIndex:0]).yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(maxY*1.2)];
    ((CPTXYPlotSpace *)[_plotView.hostedGraph plotSpaceAtIndex:1]).yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(maxY2*1.2)];
    
    [_plotView.hostedGraph reloadData];
    
    for(int i=0;i<3;i++){
        CPTPlot *plot = [_plotView.hostedGraph plotAtIndex:i];
        if([plot isKindOfClass:[CPTBarPlot class]] ){
            [HDSUtil setAnimation:@"transform.scale.y" toLayer:plot fromValue:0.1 toValue:1 forKey:@"barScaleY"];
        }else if([plot isKindOfClass:[CPTScatterPlot class]]){
            [HDSUtil setAnimation:@"opacity" toLayer:plot fromValue:0.1 toValue:1 forKey:@"lineOpacity"];
        }
    }
}

//-(void)newData:(NSTimer *)theTimer{
//    if(pointCount < dataForPlot1.count){
//        pointCount++;
//        [[plotView1.hostedGraph plotAtIndex:0] insertDataAtIndex:pointCount-1 numberOfRecords:1];
//        [[plotView2.hostedGraph plotAtIndex:0] insertDataAtIndex:pointCount-1 numberOfRecords:1];
//    }else{
//        [theTimer invalidate];
//    }
//}

- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //    NSLog(@"Connection didReceiveData of length: %u", data.length);
    SBJsonStreamParser *parser ; 
    if(connection == conn1){
        parser = parser1;
    }else if(connection == conn2){
        parser = parser2;
    }else if(connection == conn3){
        parser = parser3;
    }
    SBJsonStreamParserStatus status = [parser parse:data];
	if (status == SBJsonStreamParserError) {
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"泊位利用率");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"泊位利用率");
	} else{
        //        NSLog(@"Parser over.");
    }
}

- (IBAction)changeMonthTaped:(UIButton *)sender {
    if(sender == beginDateBtn){
        [self createDatePopovers];
        [beginMonthPopover presentPopoverFromRect:beginDateBtn.frame inView:[beginDateBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }else if(sender == endDateBtn){
        [self createDatePopovers];
        [endMonthPopover presentPopoverFromRect:endDateBtn.frame inView:[endDateBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)createDatePopovers{
    if(beginMonthPopover == nil){
        HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearMonthPickerFormat popupBtn:beginDateBtn];
        picker.delegate = self;
        beginMonthPopover= [[UIPopoverController alloc] initWithContentViewController:picker];
        beginMonthPopover.popoverContentSize = picker.view.frame.size;
        beginMonthPopover.delegate = picker;
    }
    if(endMonthPopover == nil){
        HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearMonthPickerFormat popupBtn:endDateBtn];
        picker.delegate = self;
        endMonthPopover= [[UIPopoverController alloc] initWithContentViewController:picker];
        endMonthPopover.popoverContentSize = picker.view.frame.size;
        endMonthPopover.delegate = picker;
    }
}

@end
