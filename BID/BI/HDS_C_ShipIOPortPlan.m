//
//  HDS_C_ShipIOPortPlan.m
//  HDBI
//
//  Created by 毅 张 on 12-8-14.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_C_ShipIOPortPlan.h"
#import "HDS_S_ShipInfo.h"

@implementation HDS_C_ShipIOPortPlan{
    
    CPTGraphHostingView *scatterPlotView;
	CPTXYGraph *graph;
    CPTScatterPlot *linePlot;
    CPTBarPlot *barPlot;
    
    CPTLegend *theLegend;
    UIButton *legendSwitch;
    
    NSURLConnection *conn1; // 表格数据
    NSURLConnection *conn2; // 图表数据
    NSURLConnection *conn3; // 船舶资料
    SBJsonStreamParser *parser1;
    SBJsonStreamParser *parser2;
    SBJsonStreamParser *parser3;
    SBJsonStreamParserAdapter *adapter1;
    SBJsonStreamParserAdapter *adapter2;
    SBJsonStreamParserAdapter *adapter3;
    
    NSString *qIoPort;   // 预抵预离
    HDS_S_ShipInfo *ship;
}

@synthesize plotContainer;
@synthesize segment;
@synthesize shipInfoPop;
@synthesize dataForPlot;
@synthesize shipInfoPopWE;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification];
    [HDSUtil changeSegment:segment textAttributeBySkin:[HDSUtil skinType]];
    
    scatterPlotView.layer.borderColor = [HDSUtil plotBorderColor].CGColor;
    NSArray *axes = graph.axisSet.axes;
    [HDSUtil setAxis:[axes objectAtIndex:0] titleFontSize:0 labelFontSize:isSmallView?10.0f:12.0f];
    [HDSUtil setAxis:[axes objectAtIndex:1] titleFontSize:14 labelFontSize:isSmallView?10.0f:12.0f];
    [HDSUtil setAxis:[axes objectAtIndex:2] titleFontSize:14 labelFontSize:isSmallView?10.0f:12.0f];
    graph.titleTextStyle = [HDSUtil plotTextStyle:isSmallView?14.0f:16.0f];
    graph.fill = [HDSUtil plotBackgroundFill];
    graph.legend.textStyle = [HDSUtil plotTextStyle:isSmallView?12.0f:14.0f];
    [graph.legend setNeedsDisplay];
    [legendSwitch setImage:[HDSUtil loadImageSkin:[HDSUtil skinType] imageName:@"tile_legend.png"] forState:UIControlStateNormal];
    for(CPTPlot *plot in [graph allPlots])  [plot reloadData];
}

- (void)fillConditionView:(UIView *)view{
    // segment预抵港/预离港
    segment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"预抵港",@"预离港", nil]];
    segment.segmentedControlStyle = UISegmentedControlStylePlain;
    segment.frame = CGRectMake(20, 10, 161, 31);
    segment.selectedSegmentIndex = 0;
    [segment addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    [view addSubview:segment];
    [super fillConditionView:view];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,plotContainer, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"船舶进出港计划";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    [HDSUtil changeUIControlFont:segment toSize:isSmallView?HDSFontSizeNormal:HDSFontSizeBig];
    
    headerNames = [NSArray arrayWithObjects:@"航线",@"配船数",@"船名",@"进口航次",@"出口航次",@"预抵时间",@"截关时间", nil];
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    tableView.treeInOneCell = false;
    tableView.dataMaxDepth = 2;
    
    CGRect frame = plotContainer.bounds;
    scatterPlotView = [[CPTGraphHostingView alloc] initWithFrame:frame];
    scatterPlotView.layer.borderColor = [HDSUtil plotBorderColor].CGColor;
    scatterPlotView.layer.borderWidth = 1.0f;
    scatterPlotView.layer.cornerRadius = isSmallView? Table_Corner_Small:Table_Corner;
    scatterPlotView.layer.masksToBounds = true;
    [plotContainer addSubview:scatterPlotView];
    
    [self constructPlot];
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot = [[NSMutableArray alloc] init];
    qIoPort = @"listArrive";
    // 默认全部权限的公司
    [self refreshByComps:[HDSCompanyViewController companys]];
    [self loadData];
    
}

-(void)viewDidLayoutSubviews{
    if(isSmallView)
        return;
    [tableView adjustRightTableViewWidth];
    [tableView positionVerticalScrollBar];
    //    scatterPlotView.frame = CGRectInset(plotContainer.bounds,1.0f,1.0f);
    scatterPlotView.frame = plotContainer.bounds;
}

- (void)viewDidUnload{
    [self setSegment:nil];
    [self setPlotContainer:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource
// 定义该方法则使用多个控件组合成一个tableCell，否则只使用一个UILabel来填充文字内容
//- (UIView *)tableView:(HDSTableView *)tableView cellForIndexPath:(NSIndexPath *)indexPath column:(NSInteger)col
//{
//    UILabel *l = [[[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, colWidth, 40.0f)] autorelease];
//    l.numberOfLines = 0;
//    l.lineBreakMode = UILineBreakModeWordWrap;
//    return l;
//}

// 该函数与上一个配套使用，自定义cell后必须自定义cellContent
//- (void)tableView:(HDSTableView *)tableView setContentForCell:(UIView *)cell indexPath:(NSIndexPath *)indexPath column:(NSInteger)col{
//    UILabel *l = (UILabel *)cell;
//    l.text = [[[data objectAtIndex:indexPath.section] objectAtIndex:indexPath.row] objectAtIndex:col];
//    
//    CGRect f = l.frame;
//    f.size.width = [self tableView:tableView widthForColumn:col];
//    l.frame = f;
//    
//    [l sizeToFit];
//}

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 7;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
//    return 2;
//}

- (NSInteger)tableView:(HDSTableView *)tableView canBeExpandedColumnIndexAtNode:(HDSTreeNode *)node{
    return 0;
}

// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column == 0) return 70.0f;
        if(column == 1) return 50.0f;
        if(column == 2) return 70.0f;
        if(column <= 4) return 58.0f;
        return 115.0f;
    }
    if(column == 0) return 90.0f;
    if(column == 1) return 50.0f;
    if(column == 2) return 109.0f;
    if(column <= 4) return 68.0f;
    return 135.0f;
}


- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"line";
        case 1: return @"count";
        case 2: return @"ship";
        case 3: return @"iVoyage";
        case 4: return @"eVoyage";
        case 5: return @"time";
        case 6: return @"endDte";
        default:return @"";
    }
}

- (IBAction)segmentChanged:(UISegmentedControl *)sender {
    if([sender selectedSegmentIndex] == 0){
        headerNames = [NSArray arrayWithObjects:@"航线",@"配船数",@"船名",@"进口航次",@"出口航次",@"预抵时间",@"截关时间", nil];
        qIoPort = @"listArrive";
    }else{
        headerNames = [NSArray arrayWithObjects:@"航线",@"配船数",@"船名",@"进口航次",@"出口航次",@"预离时间",@"截关时间", nil];
        qIoPort = @"listLeave";
    }
    [self loadData];
}

//- (UITableViewCellAccessoryType)tableView:(HDSTableView *)tableView accessoryTypeForNode:(HDSTreeNode *)node atTableIndex:(NSInteger)tableIndex{
//    if(!isSmallView && tableIndex == 1)
//        return  UITableViewCellAccessoryDetailDisclosureButton;
//    return UITableViewCellAccessoryNone;
//}
- (UIControl *)tableView:(HDSTableView *)_tableView accessoryViewForNode:(HDSTreeNode *)node atIndexPath:(NSIndexPath *)indexPath atTableIndex:(NSInteger) tableIndex{
    if(!isSmallView && tableIndex == 1 && node.depth == 1){
        UIButton *btn = [UIButton buttonWithType:[HDSUtil skinType] == HDSSkinBlue ? UIButtonTypeInfoDark : UIButtonTypeInfoLight];
        btn.alpha = 0.8;
        CGRect frame = btn.frame;
        CGSize size = frame.size;
        CGFloat cellHeight = [_tableView tableView:nil heightForRowAtIndexPath:indexPath];
        frame.origin = CGPointMake(250.0-size.width, (cellHeight-size.height)/2.0f);
        btn.frame = frame;
        return btn;
    }
    return nil;
}

- (WEPopoverContainerViewProperties *)improvedContainerViewProperties {
	
	WEPopoverContainerViewProperties *props = [WEPopoverContainerViewProperties alloc];
	NSString *bgImageName = nil;
	CGFloat bgMargin = 0.0;
	CGFloat bgCapSize = 0.0;
	CGFloat contentMargin = 4.0;
	
	bgImageName = @"popoverBg.png";
	
	// These constants are determined by the popoverBg.png image file and are image dependent
	bgMargin = 13; // margin width of 13 pixels on all sides popoverBg.png (62 pixels wide - 36 pixel background) / 2 == 26 / 2 == 13 
	bgCapSize = 31; // ImageSize/2  == 62 / 2 == 31 pixels
	
	props.leftBgMargin = bgMargin;
	props.rightBgMargin = bgMargin;
	props.topBgMargin = bgMargin;
	props.bottomBgMargin = bgMargin;
	props.leftBgCapSize = bgCapSize;
	props.topBgCapSize = bgCapSize;
	props.bgImageName = bgImageName;
	props.leftContentMargin = contentMargin;
	props.rightContentMargin = contentMargin - 1; // Need to shift one pixel for border to look correct
	props.topContentMargin = contentMargin; 
	props.bottomContentMargin = contentMargin;
	
	props.arrowMargin = 4.0;
	
	props.upArrowImageName = @"popoverArrowUp.png";
	props.downArrowImageName = @"popoverArrowDown.png";
	props.leftArrowImageName = @"popoverArrowLeft.png";
	props.rightArrowImageName = @"popoverArrowRight.png";
	return props;	
}

// 显示船舶信息
- (void)tableView:(HDSTableView *)_tableView accessoryView:(UIControl *)accessory tappedForNode:(HDSTreeNode *)node atTableIndex:(NSInteger)tableIndex{
    if(tableIndex == 1){
        // 使用WEPopover提供的可自定义popover controller
        if(shipInfoPopWE == nil){
            shipInfoPopWE = [[WEPopoverController alloc] initWithContentViewController:[[HDS_S_ShipInfo alloc] initWithNibName:@"HDS_S_ShipInfo" bundle:nil]];
            shipInfoPopWE.popoverContentSize = CGSizeMake(365, 205);
            ship = (HDS_S_ShipInfo *)shipInfoPopWE.contentViewController;
            if ([shipInfoPopWE respondsToSelector:@selector(setContainerViewProperties:)]) {
                [shipInfoPopWE setContainerViewProperties:[self improvedContainerViewProperties]];
            }
        }
        NSString *shipCod = [[node properties] objectForKey:@"ship_cod"];
        NSString *corpCod = [[node properties] objectForKey:@"corp_cod"];
        [self getShipInfoByShipCod:shipCod corpCod:corpCod];
        
        CGRect rect = [_tableView convertRect:accessory.frame fromView:[accessory superview]];
        [shipInfoPopWE presentPopoverFromRect: rect inView:_tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
        
		
        // 使用iOS类库提供的popover controller，但是该控件不能修改背景色.
//        if(shipInfoPop == nil){
//            shipInfoPop = [[UIPopoverController alloc] initWithContentViewController:[[HDS_S_ShipInfo alloc] initWithNibName:@"HDS_S_ShipInfo" bundle:nil]];
//            shipInfoPop.popoverContentSize = CGSizeMake(365, 205);
//            ship = (HDS_S_ShipInfo *)shipInfoPop.contentViewController;
//        }
//        NSString *shipCod = [[node properties] objectForKey:@"shipCod"];
//        NSString *corpCod = [[node properties] objectForKey:@"corpCod"];
//        [self getShipInfoByShipCod:shipCod corpCod:corpCod];
//        
//        CGRect rect = [_tableView convertRect:accessory.frame fromView:[accessory superview]];
//        [shipInfoPop presentPopoverFromRect: rect inView:_tableView permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

#pragma mark -
#pragma mark Plot construction methods
-(void)constructPlot{
	// Create graph from theme
	graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
	[graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
	scatterPlotView.hostedGraph = graph;
    
    [HDSUtil setTitle:@"近日到港航班艘次量和箱量" forGraph:graph withFontSize:isSmallView?14.0f:16.0f];
    [HDSUtil setInnerPaddingTop:6.0 right:55.0 bottom:30.0 left:45.0 forGraph:graph];
    [HDSUtil setPadding:0 forGraph:graph withBounds:scatterPlotView.bounds];
    if(!isSmallView){
        graph.plotAreaFrame.paddingBottom = 50.0;
    }
    
	// Setup plot space
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
	plotSpace.xRange    = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.5) length:CPTDecimalFromFloat(8.0)];
    //	plotSpace.yRange	= [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(50.0)];
    
	// Axes
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
	CPTXYAxis *x = axisSet.xAxis;
    [HDSUtil setAxis:x majorIntervalLength:1.0 minorTicksPerInterval:0 title:nil titleOffset:0 titleFontSize:0 labelFontSize:isSmallView?10.0f:12.0f];
    
    // 自定义坐标轴label
	x.labelingPolicy = CPTAxisLabelingPolicyNone;
    NSDate *day = [NSDate date];
	NSMutableArray *customLabels = [NSMutableArray arrayWithCapacity:8];
    CPTAxisLabel *newLabel;
    
	for (int i=1;i<=8;i++ ) {
        newLabel = [[CPTAxisLabel alloc] initWithText:[HDSUtil formatDate:day withFormatter:isSmallView?HDSDateMD:HDSDateYMD] textStyle:x.labelTextStyle];
        newLabel.tickLocation = CPTDecimalFromInt(i);
		newLabel.offset		  = x.labelOffset+5.0f;
        newLabel.rotation     = M_PI/6;
        [customLabels addObject:newLabel];
        day = [NSDate dateWithTimeInterval:60*60*24 sinceDate:day] ;
	}
	x.axisLabels = [NSSet setWithArray:customLabels];
    
	CPTXYAxis *y = axisSet.yAxis;
    [HDSUtil setAxis:y majorIntervalLength:0 minorTicksPerInterval:0 title:@"艘次量" titleOffset:25.0 titleFontSize:isSmallView?12.0f:14.0f labelFontSize:isSmallView?10.0f:12.0f ];
    y.orthogonalCoordinateDecimal = CPTDecimalFromCGFloat(0.5);
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    y.labelFormatter = nf;
    
    // 双y轴
    CPTXYPlotSpace *newPlotSpace = (CPTXYPlotSpace *)[graph newPlotSpace];
    newPlotSpace.xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.5) length:CPTDecimalFromFloat(8.0)];
    // 范围必须加载数据后根据数据计算
    //    newPlotSpace.yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(400.0)];
    [graph addPlotSpace:newPlotSpace];
    
    plotSpace.allowsUserInteraction = NO;
    newPlotSpace.allowsUserInteraction = NO;
    // 使坐标轴固定且图表可以横向拖动
    //    x.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    //    y.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    //    plotSpace.delegate = [HDSUtil getPlotDelegate];
    //    newPlotSpace.delegate = [HDSUtil getPlotDelegate];
    
    CPTXYAxis *y2 = [[CPTXYAxis alloc] init];
    y2.coordinate = CPTCoordinateY;
    [HDSUtil setAxis:y2 majorIntervalLength:0 minorTicksPerInterval:0 title:@"箱量" titleOffset:35.0 titleFontSize:isSmallView?12.0f:14.0f labelFontSize:isSmallView?10.0f:12.0f];
    y2.orthogonalCoordinateDecimal = CPTDecimalFromCGFloat(8.5);
    y2.tickDirection = CPTSignPositive;
    y2.plotSpace = newPlotSpace;
    y2.labelFormatter = nf;
    graph.axisSet.axes = [NSArray arrayWithObjects:x, y, y2, nil];
    
    // 线图
	linePlot = [[CPTScatterPlot alloc] init];
	linePlot.identifier = @"箱量";
    
	CPTMutableLineStyle *lineStyle = [linePlot.dataLineStyle mutableCopy];
	lineStyle.lineWidth				 = 2.0f;
	lineStyle.lineColor				 = [CPTColor colorWithCGColor:[HDSUtil lineChartColorAtIndex:0].CGColor];
	linePlot.dataLineStyle = lineStyle;
    // dataSource引用self为空，为什么？
	linePlot.dataSource = self;
    
	// 线图下方渐变色
    //	CPTColor *areaColor		  = [CPTColor colorWithComponentRed:0.3 green:1.0 blue:0.3 alpha:0.8];
    //	CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:areaColor endingColor:[CPTColor clearColor]];
    //	areaGradient.angle = -90.0f;
    //	CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
    //	linePlot.areaFill		 = areaGradientFill;
    //	linePlot.areaBaseValue = CPTDecimalFromString(@"1.75");
    
    // 线图节点形状
    CPTMutableLineStyle *symbolLineStyle = [CPTMutableLineStyle lineStyle];
    symbolLineStyle.lineColor = [CPTColor blackColor];
    CPTPlotSymbol *plotSymbol = [CPTPlotSymbol ellipsePlotSymbol];
    plotSymbol.fill			 = [CPTFill fillWithColor:[CPTColor colorWithCGColor:[HDSUtil lineChartPointColorAtIndex:0].CGColor]];
    plotSymbol.lineStyle	 = nil;
    CGFloat symbolSize = isSmallView?5.0f:8.0f;
    plotSymbol.size	= CGSizeMake(symbolSize, symbolSize);
    linePlot.plotSymbol = plotSymbol;
    
	// 柱状图
    barPlot= [CPTBarPlot tubularBarPlotWithColor:[CPTColor clearColor] horizontalBars:NO];
    //    CPTGradient *fillGradient = [CPTGradient gradientWithBeginningColor:
    //        [CPTColor colorWithComponentRed:28.0/255.0 green:145.0/255.0 blue:252.0/255.0 alpha:1.0]endingColor:
    //        [CPTColor colorWithComponentRed:17.0/255.0 green:95.0/255.0 blue:166.0/255.0 alpha:1.0]];
	barPlot.fill	   = [CPTFill fillWithGradient:[HDSUtil barChartGradientAtIndex:0]];
    barPlot.lineStyle  = nil;   //[HDSUtil plotBorderStyle];
	barPlot.baseValue  = CPTDecimalFromString(@"0");
	barPlot.dataSource = self;
    barPlot.barWidth   = CPTDecimalFromFloat(0.5);
	barPlot.identifier = @"艘次";
    barPlot.barCornerRadius = 0.0f;
    
    [graph addPlot:barPlot toPlotSpace:plotSpace];
    [graph addPlot:linePlot toPlotSpace:newPlotSpace];
    
    // 增加图例,legend必须在plot添加到graph之后调用
	theLegend = [CPTLegend legendWithGraph:graph];
    theLegend.fill = [CPTFill fillWithColor:[CPTColor clearColor]];
    if(isSmallView){
        legendSwitch = [UIButton buttonWithType:UIButtonTypeCustom];
        [legendSwitch setImage:[HDSUtil loadImageSkin:[HDSUtil skinType] imageName:@"tile_legend.png"] forState:UIControlStateNormal];
        legendSwitch.frame = CGRectMake(scatterPlotView.bounds.size.width-29-5, 5, 29, 29);
        // 图表内y坐标系相反，需要旋转图例图标
        legendSwitch.layer.transform =CATransform3DRotate(CATransform3DRotate(CATransform3DIdentity, M_PI, 0, 0, 1.0),M_PI, 0, 1.0, 0);
        [legendSwitch addTarget:self action:@selector(showLegend:) forControlEvents:UIControlEventTouchUpInside];
        [scatterPlotView addSubview:legendSwitch];
        [HDSUtil setLegend:theLegend withCorner:5.0 swatch:10.0 font:12.0 rowMargin:5.0 numberOfRows:2 padding:3.0];
        graph.legendAnchor		 = CPTRectAnchorBottomRight;
        graph.legendDisplacement = CGPointMake(-5.0, 3.0);
        theLegend.opacity = 0;
    }else{
        [HDSUtil setLegend:theLegend withCorner:5.0 swatch:12.0 font:14.0 rowMargin:5.0 numberOfRows:1 padding:5.0];
        graph.legendAnchor		 = CPTRectAnchorTopRight;
        graph.legendDisplacement = CGPointMake(-10.0, 0.0);
    }
	graph.legend = theLegend;
}

- (void)showLegend:(UIButton *)btn{
    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
    anim.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:0.0],nil ];
    anim.keyTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.2],[NSNumber numberWithFloat:0.8],[NSNumber numberWithInt:1.0],nil ];
    anim.duration = 5.0f;
    anim.removedOnCompletion = YES;
    anim.delegate			 = self;
    [theLegend addAnimation:anim forKey:@"legendAnimation"];
}

- (void)animationDidStart:(CAAnimation *)anim{
    if(anim == [theLegend animationForKey:@"legendAnimation"]){
        legendSwitch.hidden = YES;
    }
}
-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    //    if(anim == [theLegend animationForKey:@"legendAnimation"]){
    legendSwitch.hidden = NO;
    //    }
}

#pragma mark -
#pragma mark CPTBarPlot delegate method

-(void)barPlot:(CPTBarPlot *)plot barWasSelectedAtRecordIndex:(NSUInteger)index
{
	NSLog(@"barWasSelectedAtRecordIndex %d", index);
}

#pragma mark -
#pragma mark Plot Data Source Methods
//-(NSString *)legendTitleForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index{
//    return [NSString stringWithFormat:@"Bar %lu", (unsigned long)(index + 1)];
//}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
    return dataForPlot.count;
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
	double num = 0;
    if ( [plot isKindOfClass:[CPTBarPlot class]] ) {
        NSString *key = (fieldEnum == CPTBarPlotFieldBarLocation ? @"x" : @"y2");
        num = [(NSNumber *)[[dataForPlot objectAtIndex:index] objectForKey:key] doubleValue];
    }else {
        NSString *key = (fieldEnum == CPTScatterPlotFieldX ? @"x" : @"y1");
        num = [(NSNumber *)[[dataForPlot objectAtIndex:index] objectForKey:key] doubleValue];
    }
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
    //    if ( [plot isKindOfClass:[CPTScatterPlot class]] ) {
    //		newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.2f", 
    //            [self doubleForPlot:plot field:CPTScatterPlotFieldY recordIndex:index]] style:whiteText];
    //	}else {
    //        newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.0f", 
    //            [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index]]style:whiteText];
    //    }
    
	return newLayer;
}

#pragma mark - 数据读取相关
- (void)loadData {
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    adapter2 = [[SBJsonStreamParserAdapter alloc] init];
    adapter2.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
    parser2 = [[SBJsonStreamParser alloc] init];
    parser2.delegate = adapter2;
	
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ShipIOPortPlanGrid" withExtension:@"json"]]];
        [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ShipIOPortPlanChart" withExtension:@"json"]]];
    }else{
        // 表格数据
        NSString *url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CShipPlanWork/%@.json?corps=%@",qIoPort,qCompany];
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        
        // 图表数据
        NSString *url2 = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CShipPlanWork/%@Chart.json?corps=%@",qIoPort,qCompany];
        NSURLRequest *theRequest2=[NSURLRequest requestWithURL:[NSURL URLWithString:url2] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest2 delegate:self];
    }
}

-(void) getShipInfoByShipCod:(NSString *)shipCod corpCod:(NSString *)corpCod{
    adapter3 = [[SBJsonStreamParserAdapter alloc] init];
    adapter3.delegate = self;
    parser3 = [[SBJsonStreamParser alloc] init];
    parser3.delegate = adapter3;
    
    if([HDSUtil isOffline]){    // 离线数据
        [parser3 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ShipIOPortPlan_ship" withExtension:@"json"]]];
    }else{
        NSString *url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CShipPlanWork/getShipData.json?shipCod=%@&corpCod=%@",shipCod,corpCod];
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn3 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
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
    }else if(parser == parser2){
        [dataForPlot removeAllObjects];
        // 测试数据的开始时间,有8个小时的时区问题,还应该截断到00:00
        float maxY1 = 0.0f, maxY2 = 0.0f;
        for(int i=0; i<array.count; i++){
            data = [array objectAtIndex:i];
            NSNumber *x = [NSNumber numberWithFloat:i+1];
            NSNumber *y1 = [data objectForKey:@"cntrNum"];
            NSNumber *y2 = [data objectForKey:@"times"];
            maxY1 =MAX(maxY1, [y1 floatValue]);
            maxY2 =MAX(maxY2, [y2 floatValue]);
            [dataForPlot addObject:[NSMutableDictionary dictionaryWithObjectsAndKeys:x, @"x", y1, @"y1", y2, @"y2", nil]];
        }
        ((CPTXYPlotSpace *)[graph plotSpaceAtIndex:0]).yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(maxY2*1.2)];
        ((CPTXYPlotSpace *)[graph plotSpaceAtIndex:1]).yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(maxY1*1.2)];
        [scatterPlotView.hostedGraph reloadData];
        [HDSUtil setAnimation:@"opacity" toLayer:linePlot fromValue:0.1 toValue:1 forKey:@"lineOpacity"];
        [HDSUtil setAnimation:@"transform.scale.y" toLayer:barPlot fromValue:0.1 toValue:1 forKey:@"barScaleY"];
    }
    
}

- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {
    if(parser == parser3){
        ship.eShipName.text = [HDSUtil convertDataToString:[dict objectForKey:@"e_ship_nam"]];
        ship.cShipName.text = [HDSUtil convertDataToString:[dict objectForKey:@"ship_nam"]];
        ship.nation.text = [HDSUtil convertDataToString:[dict objectForKey:@"country_nam"]];
        ship.shipCompany.text = [HDSUtil convertDataToString:[dict objectForKey:@"ship_corp_nam"]];
        ship.shipOwner.text = [HDSUtil convertDataToString:[dict objectForKey:@"ship_owner_nam"]];
        ship.shipType.text = [HDSUtil convertDataToString:[dict objectForKey:@"ship_type"]];
        ship.shipLength.text = [HDSUtil convertDataToString:[dict objectForKey:@"ship_long_num"]];
        ship.shipWidth.text = [HDSUtil convertDataToString:[dict objectForKey:@"ship_wide_num"]];
        ship.shipHeight.text =[HDSUtil convertDataToString:[dict objectForKey:@"ship_height_num"]];
        ship.shipSpeed.text = [HDSUtil convertDataToString:[dict objectForKey:@"ship_speed_num"]];
        ship.totalWeight.text = [HDSUtil convertDataToString:[dict objectForKey:@"total_wgt"]];
        ship.grossWeight.text = [HDSUtil convertDataToString:[dict objectForKey:@"net_wgt"]];
    }
}

#pragma mark- NSURLConnectionDelegate methods
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //	NSLog(@"Connection didReceiveData of length: %u", data.length);
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"船舶进出港动态");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"船舶进出港动态");
	} else{

    }
}

@end
