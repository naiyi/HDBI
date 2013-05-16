//
//  HDS_S_DeviceWorkQuantity.m
//  设备作业量统计
//
//  Created by 毅 张 on 12-6-21.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_S_DeviceWorkQuantity.h"

@implementation HDS_S_DeviceWorkQuantity{

    CPTGraphHostingView *scatterPlotView;
    CPTBarPlot *barPlot;

    UIPopoverController *datePopover;
    CPTLegend *theLegend;
    UIButton *legendSwitch;

    NSURLConnection *conn1; // 表格数据
    SBJsonStreamParser *parser1;
    SBJsonStreamParserAdapter *adapter1;

    NSString *qMonth;
}

@synthesize plotContainer;
@synthesize dataForPlot;
@synthesize monthBtn;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification]; 
    
    HDSSkinType skinType = [HDSUtil skinType];
    [monthBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal_110.png"] forState:UIControlStateNormal];
    [monthBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight_110.png"] forState:UIControlStateHighlighted];
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    [monthBtn setTitleColor:color forState:UIControlStateNormal];
    
    scatterPlotView.layer.borderColor = [HDSUtil plotBorderColor].CGColor;
    CPTGraph *graph = scatterPlotView.hostedGraph;
    NSArray *axes = graph.axisSet.axes;
    [HDSUtil setAxis:[axes objectAtIndex:0] titleFontSize:0 labelFontSize:isSmallView?10.0f:12.0f];
    [HDSUtil setAxis:[axes objectAtIndex:1] titleFontSize:isSmallView?12.0f:14.0f labelFontSize:isSmallView?10.0f:12.0f];
    graph.titleTextStyle = [HDSUtil plotTextStyle:isSmallView?14.0f:16.0f];
    graph.fill = [HDSUtil plotBackgroundFill];
    
    for(CPTPlot *plot in [graph allPlots])  [plot reloadData];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,plotContainer, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"设备作业量统计";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    headerNames= [NSArray arrayWithObjects:@"设备/货类/名称",
                   @"作业吨数",@"作业小时数",@"台时产量",nil];
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataMaxDepth = 3;
    tableView.dataSource = self;
    tableView.treeInOneCell = YES; // 树状结构单列显示
    
    scatterPlotView = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:scatterPlotView toContainer:plotContainer title:@"台时效率对比" xTitle:nil yTitle:@"台时产量(吨)" plotNum:1 identifier:[NSArray arrayWithObjects:@"台时产量",nil] useLegend:NO useLegendIcon:NO];
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot = [[NSMutableArray alloc] init];

    // 初始化默认月份
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:[NSDate date]];
    [self refreshByDates:dates fromPopupBtn:monthBtn];
    // 初始化默认公司
    [self refreshByComps:[HDSCompanyViewController companys]];
    [self loadData];
}

-(void)viewDidLayoutSubviews{
    if(isSmallView)
        return;
    [tableView adjustRightTableViewWidth];
    [tableView positionVerticalScrollBar];
    scatterPlotView.frame = plotContainer.bounds;
}

-(void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}

- (void)viewDidUnload{
    [self setPlotContainer:nil];
    [self setMonthBtn:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 4;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
//    return 1;
//}
// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column==0)   return 160.0f;
        if(column==1)   return 90.0f;
        return 80.0f;
    }
    if(column==0)   return 268.0f;
    return 130.0f;
}


- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: {   
            return [NSString stringWithFormat:@"name%i",node.depth+1];
        }
        case 1: return @"weight";
        case 2: return @"hours";
        case 3: return @"yield";
        default:return @"";
    }
}

- (NSInteger)tableView:(HDSTableView *)tableView canBeExpandedColumnIndexAtNode:(HDSTreeNode *)node{
    return 0;
}

-(void)tableView:(HDSTableView *)tableView didSelectRowAtNode:(HDSTreeNode *)node{
    if(node.depth >= 2 ){
        return;
    }
    [self refreshBarPlotView:scatterPlotView dataForPlot:dataForPlot data:node.children dataIsTreeNode:true  xLabelKey:[NSString stringWithFormat:@"name%i",node.depth+2] yLabelKey:[NSArray arrayWithObjects:@"yield",nil] yTitleWidth:20.0 plotNum:1];
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    [monthBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year] ,[_dates month]] forState:UIControlStateNormal];
    qMonth = [NSString stringWithFormat:@"%d%02d",[_dates year] ,[_dates month]];
}

#pragma mark -
#pragma mark Plot construction methods

//- (void)animationDidStart:(CAAnimation *)anim{
//    if(anim == [theLegend animationForKey:@"legendAnimation"]){
//        legendSwitch.hidden = YES;
//    }
//}
//-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
//    //    if(anim == [theLegend animationForKey:@"legendAnimation"]){
//    legendSwitch.hidden = NO;
//    //    }
//}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
    return dataForPlot.count;
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{

    if(fieldEnum == CPTBarPlotFieldBarLocation ){
        return index+1;
    }else{  //CPTBarPlotFieldBarTip
        HDSTreeNode *node = [dataForPlot objectAtIndex:index];
        return [(NSNumber *)[node.properties objectForKey:@"yield"] doubleValue];
    }
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView)
        return nil;
    
	CPTTextLayer *newLayer = nil;
    newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.0f", 
        [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index]]style:[HDSUtil plotTextStyle:10]];
    
	return newLayer;
}

-(CPTFill *)barFillForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index{
	return [CPTFill fillWithGradient:[HDSUtil barChartGradientAtIndex:index]];
}

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
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_DeviceWorkQuantity_grid" withExtension:@"json"]]];
    }else{
        // 表格数据
        NSString *url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SDeviceWork/list.json?yearMonth=%@&corps=%@",qMonth,qCompany];
        
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"设备作业量");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"设备作业量");
	} else{
        //        NSLog(@"Parser over.");
    }
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
