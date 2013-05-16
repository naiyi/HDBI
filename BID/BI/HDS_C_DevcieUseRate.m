//
//  HDS_C_DevcieUseRate.m
//  HDBI
//
//  Created by 毅 张 on 12-9-10.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_C_DevcieUseRate.h"

@implementation HDS_C_DevcieUseRate{
    
    CPTGraphHostingView *plotView1;
    CPTGraphHostingView *plotView2;
    
    UIPopoverController *monthPopover;
    
    NSURLConnection *conn1; // 表格数据
    NSURLConnection *conn2; // 环比图表
    SBJsonStreamParser *parser1;
    SBJsonStreamParser *parser2;
    SBJsonStreamParserAdapter *adapter1;
    SBJsonStreamParserAdapter *adapter2;
    
    NSString *qMonth;
}

@synthesize barContainer1,barContainer2;
@synthesize dataForPlot1,dataForPlot2;
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
}

- (void)fillConditionView:(UIView *)view{
    // 月度
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
        pageViews = [NSArray arrayWithObjects:tableContainer,barContainer1,barContainer2, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"设备利用率";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    headerNames = [NSArray arrayWithObjects:@"设备名称",@"本月",@"上月",@"环比(%)",@"去年同期",@"同比(%)", nil];
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView1 toContainer:barContainer1 title:@"设备利用率(％)对比" xTitle:nil yTitle:nil plotNum:3 identifier:[NSArray arrayWithObjects:@"本月",@"上月",@"去年同期",nil] useLegend:YES useLegendIcon:YES];
    plotView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addLinePlotView:plotView2 toContainer:barContainer2 title:@"利用率变化趋势" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"同比",nil] useLegend:NO useLegendIcon:NO];
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot1 = [[NSMutableArray alloc] init];
    self.dataForPlot2 = [[NSMutableArray alloc] init];
    
    // 初始化默认月份
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:[NSDate date]];
    [self refreshByDates:dates fromPopupBtn:monthBtn];
    // 初始化默认公司
    [self refreshByComps:[HDSCompanyViewController companys]];
    
    [self loadData];
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

-(NSInteger)xAxisMaxCount:(NSInteger)plotNum plotView:(CPTGraphHostingView *)_plotView{
    if(_plotView == plotView2)
        return 12;
    return [super xAxisMaxCount:plotNum plotView:_plotView] ;
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
    [self setMonthBtn:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 6;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
//    return 1;
//}

// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column==0)   return 60.0f;
        return 55.0f;
    }
    if(column==0)   return 106.0f;
    return 110.0f;
}

- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"dev";
        case 1: return @"rate";
        case 2: return @"rateLm";
        case 3: return @"rateHb";
        case 4: return @"rateLy";
        case 5: return @"rateTb";
        default:return @"";
    }
}

//-(NSInteger)tableView:(HDSTableView *)tableView canBeExpandedColumnIndexAtNode:(HDSTreeNode *)node{
//    return 0;
//}

-(void)tableView:(HDSTableView *)tableView didSelectRowAtNode:(HDSTreeNode *)node{
    NSString *devNam=[node.properties objectForKey:@"dev"];
    NSString *devCod=[node.properties objectForKey:@"devCod"];
    
    NSString *urlHB;
    NSURLRequest *theRequest;
    adapter2 = [[SBJsonStreamParserAdapter alloc] init];
    adapter2.delegate = self;
    parser2 = [[SBJsonStreamParser alloc] init];
    parser2.delegate = adapter2;
    
    if([HDSUtil isOffline]){    // 离线数据
        [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_DevcieUseRateChart" withExtension:@"json"]]];
    }else{
        urlHB = [[[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CDeviceRate/listHbChart.json?v=3&beginYM=%@&endYM=%@&devCod=%@",qMonth,qMonth,devCod] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:urlHB] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }
    plotView2.hostedGraph.title = [NSString stringWithFormat:@"%@利用率变化趋势",devNam];
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    [monthBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year] ,[_dates month]] forState:UIControlStateNormal];
    qMonth = [NSString stringWithFormat:@"%d%02d",[_dates year] ,[_dates month]];
}

- (IBAction)changeMonthTaped:(UIButton *)sender {
    if(monthPopover == nil){
        HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearMonthPickerFormat popupBtn:sender];
        picker.delegate = self;
        monthPopover= [[UIPopoverController alloc] initWithContentViewController:picker];
        monthPopover.popoverContentSize = picker.view.frame.size;
        monthPopover.delegate = picker;
    }
    [monthPopover presentPopoverFromRect:monthBtn.frame inView:[monthBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
    if ( plot == [plotView1.hostedGraph plotAtIndex:0] || plot == [plotView1.hostedGraph plotAtIndex:1] || plot == [plotView1.hostedGraph plotAtIndex:2] ) {
		return [dataForPlot1 count];
	}else if ( plot == [plotView2.hostedGraph plotAtIndex:0] ) {
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
            NSDictionary *dict = [dataForPlot2 objectAtIndex:index];
            return [(NSNumber *)[dict objectForKey:@"rate"] doubleValue];
        }
    }else if( [plot isKindOfClass:[CPTBarPlot class]] ){
        if(fieldEnum == CPTBarPlotFieldBarLocation){
            return index+1;
        }else{  //CPTBarPlotFieldBarTip
            NSDictionary *dict = [dataForPlot1 objectAtIndex:index];
            if(plot == [plotView1.hostedGraph plotAtIndex:0]){
                return [(NSNumber *)[dict objectForKey:@"thisMonth"] doubleValue];
            }else if(plot == [plotView1.hostedGraph plotAtIndex:1]){
                return [(NSNumber *)[dict objectForKey:@"lastMonth"] doubleValue];
            }else if(plot == [plotView1.hostedGraph plotAtIndex:2]){
                return [(NSNumber *)[dict objectForKey:@"lastYear"] doubleValue];
            }
        }
    }
    return 0;
    
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView )
        return nil;
    
    CPTTextLayer *newLayer;
    double num = [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
    if(num > 0){
        newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.1f", num] style:[HDSUtil plotTextStyle:10]];
    }
	return newLayer;
}

#pragma mark - 数据读取相关
- (void)loadData {
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
    
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_DevcieUseRateGrid" withExtension:@"json"]]];
    }else{
        // 表格数据
        NSString *url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CDeviceRate/list.json?v=3&yearMonth=%@&corps=%@",qMonth,qCompany];
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }
}

#pragma mark SBJsonStreamParserAdapterDelegate methods
- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
    NSDictionary *data;
    NSMutableDictionary *prop;
    HDSTreeNode *node;
    if(parser == parser1){
        [self.rootArray removeAllObjects];
        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
        for(int i=0; i<array.count; i++){
            data = [array objectAtIndex:i];
            prop = [data objectForKey:@"properties"];
            node = [[HDSTreeNode alloc] initWithProperties:prop parent:nil expanded:YES];
            [self.rootArray addObject:node];
            [self loadChildren:node withData:data];
            
            // 图表数据更新
            [tempArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  [prop objectForKey:@"rate"],@"thisMonth",
                                  [prop objectForKey:@"rateLm"],@"lastMonth",
                                  [prop objectForKey:@"rateLy"],@"lastYear",
                                  [prop objectForKey:@"dev"],@"label",
                                  nil]];
        }
        [tableView reloadData];
        
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:tempArray dataIsTreeNode:false xLabelKey:@"label" yLabelKey:[NSArray arrayWithObjects:@"thisMonth",@"lastMonth",@"lastYear",nil] yTitleWidth:0 plotNum:3];
        
        // 查询完数据默认选中第一行
        if(self.rootArray.count>0 ){
            [tableView doSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        }else{
            // 没有查询结果则清空第二个图表的数据
            NSMutableArray *tempArray = [[NSMutableArray alloc] init];
            [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot2 data:tempArray dataIsTreeNode:false xLabelKey:@"date" yLabelKey:[NSArray arrayWithObject:@"rate"] yTitleWidth:0 plotNum:1];
        }
        
    }else if(parser == parser2){
        [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot2 data:array dataIsTreeNode:false xLabelKey:@"date" yLabelKey:[NSArray arrayWithObject:@"rate"] yTitleWidth:0 plotNum:1];
    }
}

- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    SBJsonStreamParser *parser ; 
    if(connection == conn1){
        parser = parser1;
    }else if(connection == conn2){
        parser = parser2;
    }
    SBJsonStreamParserStatus status = [parser parse:data];
	if (status == SBJsonStreamParserError) {
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"设备利用率");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"设备利用率");
	} else{
        
    }
}

@end
