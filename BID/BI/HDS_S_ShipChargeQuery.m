//
//  HDS_S_ShipChargeQuery.m
//  船舶计费情况查询
//
//  Created by 毅 张 on 12-7-24.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_S_ShipChargeQuery.h"

@implementation HDS_S_ShipChargeQuery{
    
    CPTGraphHostingView *plotView1;
    
    UIPopoverController *monthPopover;
    
    NSURLConnection *conn1; // 表格数据
    NSURLConnection *conn2; // 图表数据
    SBJsonStreamParser *parser1;
    SBJsonStreamParser *parser2;
    SBJsonStreamParserAdapter *adapter1;
    SBJsonStreamParserAdapter *adapter2;
    
    NSString *qYear;
    NSString *qMonth;
    
    UIViewController *pieController;
}

@synthesize plotContainer1;
@synthesize monthBtn;
@synthesize dataForPlot1;
@synthesize piePop;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification]; 
    
    HDSSkinType skinType = [HDSUtil skinType];
    [monthBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal_110.png"] forState:UIControlStateNormal];
    [monthBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight_110.png"] forState:UIControlStateHighlighted];
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    [monthBtn setTitleColor:color forState:UIControlStateNormal];
    
    [self refreshPlotTheme:plotView1];
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
        pageViews = [NSArray arrayWithObjects:tableContainer,plotContainer1, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"船舶计费情况查询";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    headerNames = [NSArray arrayWithObjects:@"船名",@"货名",@"进出口",@"内外贸",@"付款单位/日期/费目",@"吨数",@"计费金额",@"优惠金额",@"加收金额",@"合计金额", nil];
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    tableView.dataMaxDepth = 3;
    tableView.treeInOneCell = true;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    if(!isSmallView){
        plotContainer1 = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 150, 170)];
    }
    [self addPiePlotView:plotView1 toContainer:plotContainer1 title:@"计费科目比例" useLegend:YES useLegendIcon:YES];
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot1 = [[NSMutableArray alloc] init];
    
    // 初始化默认月份
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:[NSDate date]];
    [self refreshByDates:dates fromPopupBtn:monthBtn];
    // 默认全部权限的公司
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
    CPTLegend *theLegend;
    theLegend = plotView1.hostedGraph.legend;
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
//    plotView1.frame = plotContainer1.bounds;
}

- (void)viewDidUnload{
    [self setPlotContainer1:nil];
    [self setMonthBtn:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource
- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 10;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
//    return 2;
//}
// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column==0)   return 80.0f;
        if(column==1)   return 55.0f;
        if(column<=3)   return 45.0f;
        if(column==4)   return 155.0f;
        if(column==5)   return 70.0f;
        if(column==6)   return 75.0f;
        if(column<=8)   return 65.0f;
        if(column==9)   return 75.0f;
        return 80.0f;
    }
    if(column==0)   return 110.0f;
    if(column==1)   return 70.0f;
    if(column<=3)   return 50.0f;
    if(column==4)   return 200.0f;
    if(column==5)   return 80.0f;
    if(column==6)   return 100.0f;
    if(column<=8)   return 70.0f;
    if(column==9)   return 100.0f;
    return 119.0f;
}

- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"ship";
        case 1: return @"cargo";
        case 2: return @"ie";
        case 3: return @"trade";
        case 4: return @"payer";
        case 5: return @"wgt";
        case 6: return @"fee";
        case 7: return @"min";
        case 8: return @"add";
        case 9: return @"total";
        default:return @"";
    }
}

- (UIControl *)tableView:(HDSTableView *)_tableView accessoryViewForNode:(HDSTreeNode *)node atIndexPath:(NSIndexPath *)indexPath atTableIndex:(NSInteger) tableIndex{
    if(!isSmallView && tableIndex == 1 && node.depth == 0){
        UIButton *btn = [UIButton buttonWithType:[HDSUtil skinType] == HDSSkinBlue ? UIButtonTypeInfoDark : UIButtonTypeInfoLight];
        CGRect frame = btn.frame;
        CGSize size = frame.size;
        CGFloat cellHeight = [_tableView tableView:nil heightForRowAtIndexPath:indexPath];
        frame.origin = CGPointMake(110.0-HDSTable_TextIndent-size.width, (cellHeight-size.height)/2.0f);
        btn.frame = frame;
        return btn;
    }
    return nil;
}

// 显示饼图
- (void)tableView:(HDSTableView *)_tableView accessoryView:(UIControl *)accessory tappedForNode:(HDSTreeNode *)node atTableIndex:(NSInteger)tableIndex{
    if(tableIndex == 1){
        if(piePop == nil){
            piePop = [[UIPopoverController alloc] initWithContentViewController:[[UIViewController alloc] init]];
            piePop.popoverContentSize = CGSizeMake(150, 170);
            pieController = piePop.contentViewController;
            pieController.view = plotContainer1;
        }
        NSDictionary *prop = [node properties];
        [self getPieByShip:[prop objectForKey:@"ship"] cargoCod:[prop objectForKey:@"cargoCod"] tradeId:[prop objectForKey:@"tradeId"] ieId:[prop objectForKey:@"ieId"] payerCod:[prop objectForKey:@"payerCod"]];
        
        CGRect rect = [_tableView convertRect:accessory.frame fromView:[accessory superview]];
        [piePop presentPopoverFromRect: rect inView:_tableView permittedArrowDirections:UIPopoverArrowDirectionLeft animated:YES];
    }
}

-(void)tableView:(HDSTableView *)tableView didSelectRowAtNode:(HDSTreeNode *)node{
    if(node.depth != 0 ){
        return;
    }
    NSDictionary *prop = [node properties];
    [self getPieByShip:[prop objectForKey:@"ship"] cargoCod:[prop objectForKey:@"cargoCod"] tradeId:[prop objectForKey:@"tradeId"] ieId:[prop objectForKey:@"ieId"] payerCod:[prop objectForKey:@"payerCod"]];
}

-(void) getPieByShip:(NSString *)ship cargoCod:(NSString *)cargoCod tradeId:(NSString *)tradeId ieId:(NSString *)ieId payerCod:(NSString *)payerCod {
    adapter2 = [[SBJsonStreamParserAdapter alloc] init];
    adapter2.delegate = self;
    parser2 = [[SBJsonStreamParser alloc] init];
    parser2.delegate = adapter2;
    
    if([HDSUtil isOffline]){    // 离线数据
        [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ShipChargeQuery_chart" withExtension:@"json"]]];
    }else{
        NSString *url = [[[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SShipCharge/listChart.json?yearMonth=%@&ship=%@&cargoCod=%@&tradeId=%@&ieId=%@&payerCod=%@",qMonth,ship,cargoCod,tradeId,ieId,payerCod] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }
}

- (NSInteger)tableView:(HDSTableView *)tableView canBeExpandedColumnIndexAtNode:(HDSTreeNode *)node{
    return 4;
}

- (IBAction)changeMonthTaped:(UIButton *)sender {
    if(monthPopover == nil){
        HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearMonthPickerFormat popupBtn:monthBtn];
        picker.delegate = self;
        monthPopover= [[UIPopoverController alloc] initWithContentViewController:picker];
        monthPopover.popoverContentSize = picker.view.frame.size;
        monthPopover.delegate = picker;
    }
    [monthPopover presentPopoverFromRect:monthBtn.frame inView:[monthBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    [monthBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year] ,[_dates month]] forState:UIControlStateNormal];
    qMonth = [NSString stringWithFormat:@"%d%02d",[_dates year] ,[_dates month]];
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
    if ( fieldEnum == CPTPieChartFieldSliceWidth ) {
        return [(NSNumber *)[[dataForPlot1 objectAtIndex:index] objectForKey:@"SUM(TOTAL_MNY)"] doubleValue];
    }else {
        return index;
    }
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView)
        return nil;
    
	CPTTextLayer *newLayer = nil;
    newLayer = [[CPTTextLayer alloc] initWithText:[[dataForPlot1 objectAtIndex:index] objectForKey:@"FEE_NAM"] style:[HDSUtil plotTextStyle:10]];
	return newLayer;
}

-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index{
    CPTGradient *newInstance = [HDSUtil pieChartGradientAtIndex:index];
    newInstance.angle = 270.0f;
	return [CPTFill fillWithGradient:newInstance];
}

-(NSString *)legendTitleForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index{
    return [[dataForPlot1 objectAtIndex:index] objectForKey:@"FEE_NAM"];
}

#pragma mark - 数据读取相关
- (void)loadData {
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
	
    // 表格数据
	NSString *url;
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ShipChargeQuery_list" withExtension:@"json"]]];
    }else{
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SShipCharge/list.json?yearMonth=%@&corps=%@",qMonth,qCompany];
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
            node = [[HDSTreeNode alloc] initWithProperties:[data objectForKey:@"properties"] parent:nil expanded:false];
            [self.rootArray addObject:node];
            [self loadChildren:node withData:data];
        }
        [tableView reloadData];
        if(isSmallView){    // 查询完数据默认选中第一行
            [tableView doSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        }
    }else if(parser == parser2){
        dataForPlot1 = [array copy];
        [plotView1.hostedGraph reloadData];
        CABasicAnimation *rotation1 = [HDSUtil setAnimation:@"transform.rotation" toLayer:[plotView1.hostedGraph plotAtIndex:0] fromValue:M_PI * 3 toValue:0 forKey:@"pieRotation1"];
        rotation1.delegate = self;
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"船舶计费情况查询");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"船舶计费情况查询");
	} else{
        //        NSLog(@"Parser over.");
    }
}

@end

