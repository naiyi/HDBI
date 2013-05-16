//
//  HDS_C_DeviceWork.m
//  HDBI
//
//  Created by 毅 张 on 12-9-6.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_C_DeviceWork.h"

@implementation HDS_C_DeviceWork{
    
    CPTGraphHostingView *plotView1,*plotView2;
    
    UIPopoverController *monthPopover;
    
    NSURLConnection *conn1; // 表格数据
    NSURLConnection *conn2; // 表格数据
    SBJsonStreamParser *parser1;
    SBJsonStreamParser *parser2;
    SBJsonStreamParserAdapter *adapter1;
    SBJsonStreamParserAdapter *adapter2;
    
    NSString *qMonth;
    
    HDSTableView *tableView2;
    NSArray *headerNames2; 
}

@synthesize plotContainer1,plotContainer2;
@synthesize monthBtn;
@synthesize dataForPlot1,dataForPlot2;
@synthesize tableContainer2;
@synthesize rootArray2;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification];
    HDSSkinType skinType = [HDSUtil skinType];
    
    [monthBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal_110.png"] forState:UIControlStateNormal];
    [monthBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight_110.png"] forState:UIControlStateHighlighted];
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    [monthBtn setTitleColor:color forState:UIControlStateNormal];
    
    [tableView2 updateTheme];
    [self refreshPlotTheme:plotView1];
    [self refreshPlotTheme:plotView2];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,plotContainer2,tableContainer2,plotContainer1, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"设备作业量统计";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    headerNames = [NSArray arrayWithObjects:@"公司",@"设备名称",@"本月",@"上月",@"环比(%)",@"去年同期",@"同比(%)", nil];
    headerNames2= [NSArray arrayWithObjects:@"设备类型1",@"设备类型2",@"设备代码",@"设备名称",@"月份",@"自然箱",@"TEU",nil];
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    tableView.treeInOneCell = false;
    tableView.dataMaxDepth = 2;
    
    tableView2= [HDSUtil addTableViewInContainer:tableContainer2 smallView:isSmallView];
    tableView2.dataSource = self;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView1 toContainer:plotContainer1 title:@"单设备作业量情况" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"作业量",nil] useLegend:NO useLegendIcon:NO];
    plotView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView2 toContainer:plotContainer2 title:@"设备作业量同环比" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"月份",nil] useLegend:NO useLegendIcon:NO];
    
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
    [self refreshByDates:dates fromPopupBtn:monthBtn];
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
    [self setMonthBtn:nil];
    [super viewDidUnload];
}


#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)_tableView{
    if(_tableView == tableView) return 7;
    return 7;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)_tableView{
//    if(_tableView == tableView) return 2;
//    return 0;
//}

- (NSMutableArray *)rootArrayForTableView:(HDSTableView *)_tableView {
    if(_tableView == tableView) return self.rootArray;
    return self.rootArray2;
}

- (NSString *)tableView:(HDSTableView *)_tableView propertyHeaderForColumn:(NSInteger)col{
    if(_tableView  == tableView)    return [headerNames objectAtIndex:col];
    return [headerNames2 objectAtIndex:col];
}

// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)_tableView widthForColumn:(NSInteger)column{
    if(_tableView == tableView){
        if(isSmallView){
            if(column==0)   return 50.0f;
            if(column==1)   return 60.0f;
            return 60.0f;
        }
        if(column==0)   return 60.0f;
        if(column==1)   return 70.0f;
        return 65.0f;
    }else{
        if(isSmallView){
            if(column==0)   return 90.0f;
            if(column==1)   return 70.0f;
            return 60.0f;
        }
        if(column==0)   return 115.0f;
        if(column==1)   return 90.0f;
        return 90.0f;
    }
}

-(NSInteger)tableView:(HDSTableView*)_tableView canBeExpandedColumnIndexAtNode:(HDSTreeNode*)node{
    if(_tableView == tableView)
        return 0;
    return -1;
}

- (NSString *)tableView:(HDSTableView *)_tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    if(_tableView == tableView){
        switch (col) {
            case 0: return @"corp";
            case 1: return @"kind";
            case 2: return @"cntrNum";
            case 3: return @"cntrNumLm";
            case 4: return @"hbRate";
            case 5: return @"cntrNumLy";
            case 6: return @"tbRate";
            default:return @"";
        }
    }else{
        switch (col) {
            case 0: return @"kind1";
            case 1: return @"kind2";
            case 2: return @"devCod";
            case 3: return @"devNam";
            case 4: return @"yearMonth";
            case 5: return @"cntrNum";
            case 6: return @"teuNum";
            default:return @"";
        }
    }
}

- (IBAction)changeMonthTaped:(UIButton *)sender {
    if(sender == monthBtn){
        if(monthPopover == nil){
            HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearMonthPickerFormat popupBtn:monthBtn];
            picker.delegate = self;
            monthPopover= [[UIPopoverController alloc] initWithContentViewController:picker];
            monthPopover.popoverContentSize = picker.view.frame.size;
            monthPopover.delegate = picker;
        }
        [monthPopover presentPopoverFromRect:monthBtn.frame inView:[monthBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    if(popupBtn == monthBtn){
        [monthBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year],[_dates month]] forState:UIControlStateNormal];
        qMonth = [NSString stringWithFormat:@"%d%02d",[_dates year] ,[_dates month]];
    }
}

#pragma mark -
#pragma mark Plot Data Source Methods
//-(NSString *)legendTitleForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index{
//    return [NSString stringWithFormat:@"Bar %lu", (unsigned long)(index + 1)];
//}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
    if (plot == [plotView1.hostedGraph plotAtIndex:0]) {
		return [dataForPlot1 count];    
	}else if ( plot == [plotView2.hostedGraph plotAtIndex:0]) {
		return [dataForPlot2 count];    //1;
    }else{
        return 0;
    }
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    if(fieldEnum == CPTBarPlotFieldBarLocation ){
        return index+1;
    }
    if ( plot == [plotView1.hostedGraph plotAtIndex:0] ) {
        NSDictionary *dict = [dataForPlot1 objectAtIndex:index];
        return [(NSNumber *)[dict objectForKey:@"num"] doubleValue];
    }else if( plot == [plotView2.hostedGraph plotAtIndex:0] ){
        NSDictionary *dict = [dataForPlot2 objectAtIndex:index];
        return [(NSNumber *)[dict objectForKey:@"num"] doubleValue];
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

-(CPTFill *)barFillForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index{
	return [CPTFill fillWithGradient:[HDSUtil barChartGradientAtIndex:index]];
}

#pragma mark - 数据读取相关
- (void)loadData {
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
	
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_DeviceWorkGrid" withExtension:@"json"]]];
    }else{
        NSString *url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CDeviceWork/list.json?yearMonth=%@&corps=%@",qMonth,qCompany];
        
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
        double thisMonth = 0,lastMonth = 0,lastYear = 0;
        for(int i=0; i<array.count; i++){
            data = [array objectAtIndex:i];
            prop = [data objectForKey:@"properties"];
            node = [[HDSTreeNode alloc] initWithProperties:prop parent:nil expanded:YES];
            [self.rootArray addObject:node];
            [self loadChildren:node withData:data];
            
            // 图表数据更新
            lastYear += [(NSNumber *)[prop objectForKey:@"cntrNumLy"] doubleValue];
            lastMonth += [(NSNumber *)[prop objectForKey:@"cntrNumLm"] doubleValue];
            thisMonth += [(NSNumber *)[prop objectForKey:@"cntrNum"] doubleValue];
        }
        [tableView reloadData];
        
        [tempArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:lastYear],@"num",@"去年同期",@"label",nil]];
        [tempArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:lastMonth],@"num",@"上月",@"label",nil]];
        [tempArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithDouble:thisMonth],@"num",@"当月",@"label",nil]];
        
        [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot2 data:tempArray dataIsTreeNode:false xLabelKey:@"label" yLabelKey:[NSArray arrayWithObject:@"num"] yTitleWidth:0 plotNum:1];
        
        // 查询完数据默认选中第二行
        if(self.rootArray.count>0 && [tableView.rightTableView numberOfRowsInSection:0]>1){
            [tableView doSelectRowAtIndexPath:[NSIndexPath indexPathForRow:1 inSection:0]];
        }else{
            // 没有查询结果则清空第二个表格和图表的数据
            [self.rootArray2 removeAllObjects];
            [tableView2 reloadData];
            NSMutableArray *tempArray = [[NSMutableArray alloc] init];
            [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:tempArray dataIsTreeNode:false xLabelKey:@"label" yLabelKey:[NSArray arrayWithObject:@"num"] yTitleWidth:0 plotNum:1];
        }
        
    }else if(parser == parser2){
        [self.rootArray2 removeAllObjects];
        NSMutableArray *tempArray = [[NSMutableArray alloc] init];
        for(int i=0; i<array.count; i++){
            data = [array objectAtIndex:i];
            prop = [data objectForKey:@"properties"];
            node = [[HDSTreeNode alloc] initWithProperties:prop parent:nil expanded:YES];
            [self.rootArray2 addObject:node];
            
            // 图表数据
            [tempArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:[prop objectForKey:@"cntrNum"],@"num",[prop objectForKey:@"devNam"],@"label",nil]];
        }
        [tableView2 reloadData];
        
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:tempArray dataIsTreeNode:false xLabelKey:@"label" yLabelKey:[NSArray arrayWithObject:@"num"] yTitleWidth:0 plotNum:1];
    }
    
}

-(NSInteger)xAxisMaxCount:(NSInteger)plotNum plotView:(CPTGraphHostingView *)_plotView{
    if(_plotView == plotView1)  {
        if(isSmallView) return 12;
        return 20;
    }
    return 4;
}

-(void)tableView:(HDSTableView *)_tableView didSelectRowAtNode:(HDSTreeNode *)node{
    if(_tableView != tableView) return;
    if(node.depth != 1) return ;
    
    adapter2 = [[SBJsonStreamParserAdapter alloc] init];
    adapter2.delegate = self;
    parser2 = [[SBJsonStreamParser alloc] init];
    parser2.delegate = adapter2;
    
    if([HDSUtil isOffline]){    // 离线数据
        [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_DeviceWorkChart" withExtension:@"json"]]];
    }else{
        NSString *corpCod = [node.parent.properties objectForKey:@"corpCod"];
        NSString *kindCod = [node.properties objectForKey:@"kindCod"];
        
        NSString *url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CDeviceWork/listDev.json?yearMonth=%@&corpCod=%@&kind=%@",qMonth,corpCod,kindCod];
        
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }
    
//    NSDictionary *data = [node properties];
//    
//    [dataForPlot1 removeAllObjects];
//    NSMutableArray *customLabels = [[NSMutableArray alloc] init];
//    CPTAxisLabel *newLabel;
//    float maxY = 0.0f;
//    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)plotView1.hostedGraph.axisSet;
//    CPTXYAxis *x = axisSet.xAxis;
//    
//    for(int i=1;i<=12;i++){
//        [dataForPlot1 addObject:[NSDictionary dictionaryWithObjectsAndKeys:
//                                 [data objectForKey:[NSString stringWithFormat:@"month%d",i]],@"teu",nil]];
//        newLabel = [[CPTAxisLabel alloc] initWithText:[NSString stringWithFormat:@"%d月",i] textStyle:x.labelTextStyle];
//        newLabel.tickLocation = CPTDecimalFromInt(i);
//        newLabel.offset		  = x.labelOffset+5.0f;
//        [customLabels addObject:newLabel];
//        
//        NSNumber *y1 = [data objectForKey:[NSString stringWithFormat:@"month%d",i]];
//        maxY =MAX(maxY, [y1 floatValue]);
//    }
//    x.axisLabels = [NSSet setWithArray:customLabels];
//    // y轴label宽度根据数字长度调节
//    CGSize yLabelSize = [[NSString stringWithFormat:@"%.0f",maxY*1.2] sizeWithFont:[UIFont fontWithName:axisSet.yAxis.labelTextStyle.fontName size:axisSet.yAxis.labelTextStyle.fontSize] constrainedToSize:CGSizeMake(MAXFLOAT, 30) lineBreakMode:UILineBreakModeWordWrap];
//    axisSet.yAxis.titleOffset = yLabelSize.width +5.0f/*tick宽度*/+10;
//    plotView1.hostedGraph.plotAreaFrame.paddingLeft = axisSet.yAxis.titleOffset;
//    
//    ((CPTXYPlotSpace *)[plotView1.hostedGraph plotSpaceAtIndex:0]).xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.5) length:CPTDecimalFromInteger(12) ];
//    ((CPTXYPlotSpace *)[plotView1.hostedGraph plotSpaceAtIndex:0]).yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(maxY*1.2)];
//    
//    [plotView1.hostedGraph reloadData];
//    [HDSUtil setAnimation:@"transform.scale.y" toLayer:[plotView1.hostedGraph plotAtIndex:0] fromValue:0.1 toValue:1 forKey:@"barScaleY"];
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"设备作业量统计");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"设备作业量统计");
	} else{
        
    }
}

@end
