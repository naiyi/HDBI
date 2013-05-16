//
//  HDS_C_GateFlow.m
//  HDBI
//
//  Created by 毅 张 on 12-8-17.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_C_GateFlow.h"

@implementation HDS_C_GateFlow{
    
    CPTGraphHostingView *plotView1,*plotView2;
    
    UIPopoverController *yearPopover;
    
    NSURLConnection *conn1; // 表格数据
    NSURLConnection *conn2; // 表格数据
    SBJsonStreamParser *parser1;
    SBJsonStreamParser *parser2;
    SBJsonStreamParserAdapter *adapter1;
    SBJsonStreamParserAdapter *adapter2;
    
    NSString *qYear;
    
    HDSTableView *tableView2;
    NSArray *headerNames2; 
}

@synthesize plotContainer1,plotContainer2;
@synthesize yearBtn;
@synthesize dataForPlot1,dataForPlot2;
@synthesize tableContainer2;
@synthesize rootArray2;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification];
    HDSSkinType skinType = [HDSUtil skinType];
    
    [yearBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal.png"] forState:UIControlStateNormal];
    [yearBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight.png"] forState:UIControlStateHighlighted];
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    [yearBtn setTitleColor:color forState:UIControlStateNormal];
    
    [tableView2 updateTheme];
    [self refreshPlotTheme:plotView1];
    [self refreshPlotTheme:plotView2];
}

- (void)fillConditionView:(UIView *)view{
    // 年度
    yearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    yearBtn.frame = CGRectMake(20,10,100,31);
    yearBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    yearBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [yearBtn addTarget:self action:@selector(changeMonthTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:yearBtn];
    
    [super fillConditionView:view];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,tableContainer2,plotContainer1,plotContainer2, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"闸口流量统计";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    headerNames = [NSArray arrayWithObjects:@"年份",@"项目名称",@"1月",@"2月",@"3月",@"4月",@"5月",@"6月",@"7月",@"8月",@"9月",@"10月",@"11月",@"12月",@"合计",@"平均", nil];
    headerNames2= [NSArray arrayWithObjects:@"项目名称",@"本月",@"上月",@"+/-%",@"去年同期",@"+/-%",@"本年累计",@"去年累计",@"+/-%",nil];
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    
    tableView2= [HDSUtil addTableViewInContainer:tableContainer2 smallView:isSmallView];
    tableView2.dataSource = self;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView1 toContainer:plotContainer1 title:@"闸口流量月度变化趋势" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"月度",nil] useLegend:NO useLegendIcon:NO];
    plotView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView2 toContainer:plotContainer2 title:@"闸口流量年度变化趋势" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"年度",nil] useLegend:NO useLegendIcon:NO];
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.rootArray2= [[NSMutableArray alloc] init];
    self.dataForPlot1 = [[NSMutableArray alloc] init];
    self.dataForPlot2 = [[NSMutableArray alloc] init];
    
    // 初始化默认月份
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:[NSDate date]];
    [self refreshByDates:dates fromPopupBtn:yearBtn];
    // 默认全部权限的公司
    [self refreshByComps:[HDSCompanyViewController companys]];
    [self loadData];
}

//- (void)showLegend:(UIButton *)legendSwitch{
//    legendSwitch.hidden = YES;
//    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
//    anim.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:0.0],nil ];
//    anim.keyTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.2],[NSNumber numberWithFloat:0.8],[NSNumber numberWithInt:1.0],nil ];
//    anim.duration = 5.0f;
//    anim.removedOnCompletion = NO;
//    anim.delegate			 = self;
//    CPTLegend *theLegend;
//    if([legendSwitch superview] == plotView1){
//        theLegend = plotView1.hostedGraph.legend;
//    }else if([legendSwitch superview] == plotView2){
//        theLegend = plotView2.hostedGraph.legend;
//    }
//    [theLegend addAnimation:anim forKey:@"legendAnimation"];
//}

//-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
//    if(anim == [plotView1.hostedGraph.legend animationForKey:@"legendAnimation"]){
//        [plotView1 viewWithTag:Legend_Switch_Tag].hidden = NO;
//    }else if(anim == [plotView2.hostedGraph.legend animationForKey:@"legendAnimation"]){
//        [plotView2 viewWithTag:Legend_Switch_Tag].hidden = NO;
//    }
//}

-(void)viewDidLayoutSubviews{
    if(isSmallView)
        return;
    [tableView adjustRightTableViewWidth];
    [tableView positionVerticalScrollBar];
    [tableView2 adjustRightTableViewWidth];
    [tableView2 positionVerticalScrollBar];
    plotView1.frame = plotContainer1.bounds;
    plotView2.frame = plotContainer2.bounds;
}

- (void)viewDidUnload{
    [self setPlotContainer1:nil];
    [self setPlotContainer2:nil];
    [self setYearBtn:nil];
    [super viewDidUnload];
}


#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)_tableView{
    if(_tableView == tableView) return 14;
    return 9;
}

- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)_tableView{
    if(_tableView == tableView) return 2;
    return 0;
}

- (NSMutableArray *)rootArrayForTableView:(HDSTableView *)_tableView {
    if(_tableView == tableView) return self.rootArray;
    return self.rootArray2;
}

//- (CGFloat)heightForHeaderCellOfTableView:(HDSTableView *)tableView{
//    if(isSmallView){
//        return Table_Header_Height_Small;
//    }
//    return Table_Header_Height;
//}

- (NSString *)tableView:(HDSTableView *)_tableView propertyHeaderForColumn:(NSInteger)col{
    if(_tableView  == tableView)    return [headerNames objectAtIndex:col];
    return [headerNames2 objectAtIndex:col];
}

// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)_tableView widthForColumn:(NSInteger)column{
    if(_tableView == tableView){
        if(isSmallView){
            if(column==0)   return 50.0f;
            if(column==1)   return 70.0f;
            return 50.0f;
        }
        if(column==0)   return 65.0f;
        if(column==1)   return 90.0f;
        return 70.0f;
    }else{
        if(isSmallView){
            if(column==0)   return 70.0f;
            if(column==1)   return 60.0f;
            return 60.0f;
        }
        if(column==0)   return 90.0f;
        if(column==1)   return 73.0f;
        return 70.0f;
    }
}

- (NSString *)tableView:(HDSTableView *)_tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    if(_tableView == tableView){
        switch (col) {
            case 0: return @"year";
            case 1: return @"item";
            case 2: return @"month1";
            case 3: return @"month2";
            case 4: return @"month3";
            case 5: return @"month4";
            case 6: return @"month5";
            case 7: return @"month6";
            case 8: return @"month7";
            case 9: return @"month8";
            case 10: return @"month9";
            case 11: return @"month10";
            case 12: return @"month11";
            case 13: return @"month12";
            case 14: return @"monthTotal";
            case 15: return @"monthAvg";
            default:return @"";
        }
    }else{
        switch (col) {
            case 0: return @"item";
            case 1: return @"thisMonth";
            case 2: return @"lastMonth";
            case 3: return @"rate1";
            case 4: return @"lastYearThisMonth";
            case 5: return @"rate2";
            case 6: return @"thisYearTotal";
            case 7: return @"lastYearTotal";
            case 8: return @"rate3";
            default:return @"";
        }
    }
    
}

- (IBAction)changeMonthTaped:(UIButton *)sender {
    if(yearPopover == nil){
        HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearPickerFormat popupBtn:yearBtn];
        picker.delegate = self;
        yearPopover= [[UIPopoverController alloc] initWithContentViewController:picker];
        yearPopover.popoverContentSize = picker.view.frame.size;
        yearPopover.delegate = picker;
    }
    [yearPopover presentPopoverFromRect:yearBtn.frame inView:[yearBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    [yearBtn setTitle:[NSString stringWithFormat:@"     %d年",[_dates year]] forState:UIControlStateNormal];
    qYear = [NSString stringWithFormat:@"%d",[_dates year]];    
}

#pragma mark -
#pragma mark Plot Data Source Methods
//-(NSString *)legendTitleForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index{
//    return [NSString stringWithFormat:@"Bar %lu", (unsigned long)(index + 1)];
//}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
    if (plot == [plotView1.hostedGraph plotAtIndex:0]) {
		return [dataForPlot1 count];    //12
	}else if ( plot == [plotView2.hostedGraph plotAtIndex:0]) {
		return [dataForPlot2 count];    //2;
    }else{
        return 0;
    }
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    if ( plot == [plotView1.hostedGraph plotAtIndex:0] ) {
        if(fieldEnum == CPTBarPlotFieldBarLocation ){
            return index+1;
        }else{  //CPTBarPlotFieldBarTip
            NSDictionary *dict = [dataForPlot1 objectAtIndex:index];
            return [(NSNumber *)[dict objectForKey:@"teu"] doubleValue];
        }
    }else if( plot == [plotView2.hostedGraph plotAtIndex:0] ){
        if(fieldEnum == CPTBarPlotFieldBarLocation ){
            return index+1;
        }else{  //CPTBarPlotFieldBarTip
            NSDictionary *dict = [dataForPlot2 objectAtIndex:index];
            return [(NSNumber *)[dict objectForKey:@"teu"] doubleValue];
        }
    }else{
        return 0;
    }
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView)
        return nil;
    
	CPTTextLayer *newLayer = nil;
    double num = [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
    if(num > 0){
        newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.0f", 
                num] style:[HDSUtil plotTextStyle:10]];
    }
	return newLayer;
}

//-(CPTFill *)barFillForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index{
//	CPTGradient *fillGradient = [CPTGradient gradientWithBeginningColor:[CPTColor colorWithCGColor:[HDSUtil barChartBeginColorAtIndex:index].CGColor] endingColor:[CPTColor colorWithCGColor:[HDSUtil barChartEndColorAtIndex:index].CGColor]];
//	return [CPTFill fillWithGradient:fillGradient];
//}

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
	
    // 表格数据
	NSString *url,*url2;
    NSString *titleDate;
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_GateFlowGrid" withExtension:@"json"]]];
        [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_GateFlowChart" withExtension:@"json"]]];
        titleDate = [yearBtn titleForState:UIControlStateNormal];
        if(titleDate == nil) titleDate = qYear;
    }else{
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CGateFlow/list.json?year=%@&corps=%@",qYear,qCompany];
        url2 = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CGateFlow/list2.json?corps=%@",qCompany];
        titleDate = [yearBtn titleForState:UIControlStateNormal];
//        if(titleDate == nil) titleDate = qYear;
        
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        // 图表数据
        NSURLRequest *theRequest2=[NSURLRequest requestWithURL:[NSURL URLWithString:url2] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest2 delegate:self];
    }
    
//    plotView1.hostedGraph.title = [NSString stringWithFormat:@"%@公司计划完成情况(万吨)",titleDate];
//    plotView2.hostedGraph.title = [NSString stringWithFormat:@"%@货类计划完成情况(万吨)",titleDate];
}

#pragma mark SBJsonStreamParserAdapterDelegate methods
- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
    NSDictionary *data;
    NSMutableDictionary *prop;
    HDSTreeNode *node;
    if(parser == parser1){
        [self.rootArray removeAllObjects];
        for(int i=0; i<array.count; i++){
            data = [array objectAtIndex:i];
            prop = [data objectForKey:@"properties"];
            if(i == 0){
                [prop setObject:[NSString stringWithFormat:@"%i年",[[qYear substringToIndex:4] intValue]-1]  forKey:@"year"];
            }else if( i == 5){
                [prop setObject:[NSString stringWithFormat:@"%@年",qYear] forKey:@"year"];
            }
            NSString *item;
            switch (i) {
                case 0: 
                case 5: item=@"进出闸总量";break;
                case 1: 
                case 6: item=@"进闸";break;
                case 2: 
                case 7: item=@"出闸";break;
                case 3: 
                case 8: item=@"内贸";break;
                case 4: 
                case 9: item=@"外贸";break;
            }
            [prop setObject:item forKey:@"item"];
            node = [[HDSTreeNode alloc] initWithProperties:prop parent:nil expanded:YES];
            [self.rootArray addObject:node];
        }
        [tableView reloadData];
        
        // 刷新图表
        [tableView doSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        
        NSString *lastYear = [NSString stringWithFormat:@"%i年",[[qYear substringToIndex:4] intValue]-1];
        NSString *thisYear = [NSString stringWithFormat:@"%@年",qYear];
        NSNumber *lastTotal=[[[array objectAtIndex:0] objectForKey:@"properties"] objectForKey:@"monthTotal"];
        NSNumber *thisTotal=[[[array objectAtIndex:5] objectForKey:@"properties"] objectForKey:@"monthTotal"];
        NSArray *tempArray = [NSArray arrayWithObjects:
            [NSDictionary dictionaryWithObjectsAndKeys:lastYear,@"year",lastTotal, @"teu",nil],
            [NSDictionary dictionaryWithObjectsAndKeys:thisYear,@"year",thisTotal, @"teu",nil],
                              nil];
        [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot2 data:tempArray dataIsTreeNode:false xLabelKey:@"year" yLabelKey:[NSArray arrayWithObject:@"teu"] yTitleWidth:0 plotNum:1];
        
    }else if(parser == parser2){
        [self.rootArray2 removeAllObjects];
        for(int i=0; i<array.count; i++){
            data = [array objectAtIndex:i];
            prop = [data objectForKey:@"properties"];
            NSString *item;
            switch (i) {
                case 0: item=@"进出闸总量";break;
                case 1: item=@"进闸";break;
                case 2: item=@"出闸";break;
                case 3: item=@"内贸";break;
                case 4: item=@"外贸";break;
            }
            [prop setObject:item forKey:@"item"];
            node = [[HDSTreeNode alloc] initWithProperties:prop parent:nil expanded:YES];
            [self.rootArray2 addObject:node];
        }
        [tableView2 reloadData];
    }
    
}

-(NSInteger)xAxisMaxCount:(NSInteger)plotNum plotView:(CPTGraphHostingView *)_plotView{
    if(_plotView == plotView1)  return 12;
    return 4;
}

-(void)tableView:(HDSTableView *)_tableView didSelectRowAtNode:(HDSTreeNode *)node{
    if(_tableView != tableView) return;
    
    NSDictionary *data = [node properties];
    
    [dataForPlot1 removeAllObjects];
    NSMutableArray *customLabels = [[NSMutableArray alloc] init];
    CPTAxisLabel *newLabel;
    float maxY = 0.0f;
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)plotView1.hostedGraph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    
    for(int i=1;i<=12;i++){
        [dataForPlot1 addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                [data objectForKey:[NSString stringWithFormat:@"month%d",i]],@"teu",nil]];
        newLabel = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%d月",i] textStyle:x.labelTextStyle];
        newLabel.tickLocation = CPTDecimalFromInt(i);
        newLabel.offset		  = x.labelOffset+5.0f;
        [customLabels addObject:newLabel];
        
        NSNumber *y1 = [data objectForKey:[NSString stringWithFormat:@"month%d",i]];
        maxY =MAX(maxY, [y1 floatValue]);
    }
    x.axisLabels = [NSSet setWithArray:customLabels];
    // y轴label宽度根据数字长度调节
    CGSize yLabelSize = [[NSString stringWithFormat:@"%.0f",maxY*1.2] sizeWithFont:[UIFont fontWithName:axisSet.yAxis.labelTextStyle.fontName size:axisSet.yAxis.labelTextStyle.fontSize] constrainedToSize:CGSizeMake(MAXFLOAT, 30) lineBreakMode:UILineBreakModeWordWrap];
    axisSet.yAxis.titleOffset = yLabelSize.width +5.0f/*tick宽度*/+10;
    plotView1.hostedGraph.plotAreaFrame.paddingLeft = axisSet.yAxis.titleOffset;
    
    ((CPTXYPlotSpace *)[plotView1.hostedGraph plotSpaceAtIndex:0]).xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.5) length:CPTDecimalFromInteger(12) ];
    ((CPTXYPlotSpace *)[plotView1.hostedGraph plotSpaceAtIndex:0]).yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(maxY*1.2)];
    
    [plotView1.hostedGraph reloadData];
    [HDSUtil setAnimation:@"transform.scale.y" toLayer:[plotView1.hostedGraph plotAtIndex:0] fromValue:0.1 toValue:1 forKey:@"barScaleY"];
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"闸口流量统计");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"闸口流量统计");
	} else{

    }
}

@end
