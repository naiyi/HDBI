//
//  HDS_S_ThruputPlanComplete.m
//  吞吐量计划完成情况
//
//  Created by 毅 张 on 12-7-4.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_S_ThruputPlanComplete.h"

@implementation HDS_S_ThruputPlanComplete{
    
    CPTGraphHostingView *plotView1,*plotView2;
    
    UIPopoverController *yearPopover;
    UIPopoverController *monthPopover;
    
    NSURLConnection *conn1; // 表格数据
    NSURLConnection *conn2; // 图表数据
    NSURLConnection *conn3; // 
    SBJsonStreamParser *parser1;
    SBJsonStreamParser *parser2;
    SBJsonStreamParser *parser3;
    SBJsonStreamParserAdapter *adapter1;
    SBJsonStreamParserAdapter *adapter2;
    SBJsonStreamParserAdapter *adapter3;
    
    NSString *qYear;
    NSString *qMonth;
}

@synthesize plotContainer1,plotContainer2;
@synthesize yearMonthSegment;
@synthesize yearBtn;
@synthesize monthBtn;
@synthesize dataForPlot1,dataForPlot2;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification];
    HDSSkinType skinType = [HDSUtil skinType];
    [HDSUtil changeSegment:yearMonthSegment textAttributeBySkin:skinType]; 
    
    [monthBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal_110.png"] forState:UIControlStateNormal];
    [monthBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight_110.png"] forState:UIControlStateHighlighted];
    [yearBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal.png"] forState:UIControlStateNormal];
    [yearBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight.png"] forState:UIControlStateHighlighted];
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    [monthBtn setTitleColor:color forState:UIControlStateNormal];
    [yearBtn setTitleColor:color forState:UIControlStateNormal];
    
    [self refreshPlotTheme:plotView1];
    [self refreshPlotTheme:plotView2];
}

- (void)fillConditionView:(UIView *)view{
    // segment月度/年度
    yearMonthSegment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"月度",@"年度", nil]];
    yearMonthSegment.segmentedControlStyle = UISegmentedControlStylePlain;
    yearMonthSegment.frame = CGRectMake(20, 10, 103, 31);
    yearMonthSegment.selectedSegmentIndex = 0;
    [yearMonthSegment addTarget:self action:@selector(changeSegmentTaped:) forControlEvents:UIControlEventValueChanged];
    [view addSubview:yearMonthSegment];
    // 年度
    yearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    yearBtn.frame = CGRectMake(131,10,100,31);
    yearBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    yearBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    yearBtn.hidden = true;  //默认显示月度
    [yearBtn addTarget:self action:@selector(changeMonthTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:yearBtn];
    // 月度
    monthBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    monthBtn.frame = CGRectMake(131,10,119,31);
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
        pageViews = [NSArray arrayWithObjects:tableContainer,plotContainer1,plotContainer2, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"吞吐量计划完成情况";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    [HDSUtil changeUIControlFont:yearMonthSegment toSize:isSmallView?HDSFontSizeNormal:HDSFontSizeBig];
    
    headerNames = [NSArray arrayWithObjects:@"公司",@"货类",@"计划吞吐量",@"完成吞吐量",@"完成％", nil];
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    tableView.dataMaxDepth = 2;
    tableView.treeInOneCell = true;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView1 toContainer:plotContainer1 title:@"公司计划完成情况(万吨)" xTitle:nil yTitle:nil plotNum:2 identifier:[NSArray arrayWithObjects:@"完成",@"计划",nil] useLegend:YES useLegendIcon:NO];
    plotView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView2 toContainer:plotContainer2 title:@"货类计划完成情况(万吨)" xTitle:nil yTitle:nil plotNum:2 identifier:[NSArray arrayWithObjects:@"完成",@"计划",nil] useLegend:YES useLegendIcon:NO];
    
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
    [self refreshByDates:dates fromPopupBtn:yearBtn];
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
    if([legendSwitch superview] == plotView1){
        theLegend = plotView1.hostedGraph.legend;
    }else if([legendSwitch superview] == plotView2){
        theLegend = plotView2.hostedGraph.legend;
    }
    [theLegend addAnimation:anim forKey:@"legendAnimation"];
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
    if(anim == [plotView1.hostedGraph.legend animationForKey:@"legendAnimation"]){
        [plotView1 viewWithTag:Legend_Switch_Tag].hidden = NO;
    }else if(anim == [plotView2.hostedGraph.legend animationForKey:@"legendAnimation"]){
        [plotView2 viewWithTag:Legend_Switch_Tag].hidden = NO;
    }
}

-(void)viewDidLayoutSubviews{
    if(isSmallView)
        return;
    [tableView adjustRightTableViewWidth];
    [tableView positionVerticalScrollBar];
    plotView1.frame = plotContainer1.bounds;
    plotView2.frame = plotContainer2.bounds;
}

- (void)viewDidUnload{
    [self setPlotContainer1:nil];
    [self setPlotContainer2:nil];
    [self setYearBtn:nil];
    [self setMonthBtn:nil];
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
        if(column==0)   return 50.0f;
        if(column==1)   return 130.0f;
        return 80.0f;
    }
    if(column==0)   return 100.0f;
    if(column==1)   return 200.0f;
    return 119.0f;
}

- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"corp";
        case 1: return [NSString stringWithFormat:@"name%i",node.depth+1];
        case 2: return @"plan";
        case 3: return @"complete";
        case 4: return @"ratio";
        default:return @"";
    }
}

- (NSInteger)tableView:(HDSTableView *)tableView canBeExpandedColumnIndexAtNode:(HDSTreeNode *)node{
    return 1;
}

- (IBAction)changeMonthTaped:(UIButton *)sender {
    if(sender == yearBtn){
        if(yearPopover == nil){
            HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearPickerFormat popupBtn:yearBtn];
            picker.delegate = self;
            yearPopover= [[UIPopoverController alloc] initWithContentViewController:picker];
            yearPopover.popoverContentSize = picker.view.frame.size;
            yearPopover.delegate = picker;
        }
        [yearPopover presentPopoverFromRect:yearBtn.frame inView:[yearBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }else if(sender == monthBtn){
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


- (IBAction)changeSegmentTaped:(UISegmentedControl *)sender {
    [self loadData];
    if(yearMonthSegment.selectedSegmentIndex == 0){
        monthBtn.hidden = false;
        yearBtn.hidden = true;
        if(!isSmallView){
            CGRect f = chooseCompBtn.frame; 
            f.origin.x = 258.0f;
            chooseCompBtn.frame = f;
            f = companyLabel.frame; 
            f.origin.x = 366.0f;
            f.size.width = 317.0f;
            companyLabel.frame = f;
        }
    }else{
        monthBtn.hidden = true;
        yearBtn.hidden = false;
        if(!isSmallView){
            CGRect f = chooseCompBtn.frame; 
            f.origin.x = 239.0f;
            chooseCompBtn.frame = f;
            f = companyLabel.frame; 
            f.origin.x = 347.0f;
            f.size.width = 336.0f;
            companyLabel.frame = f;
        }
    }
//    if(isSmallView){
//        currentViewIndex = 0;
//        [self smallViewChangeToIndex:currentViewIndex];
//    }
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    if(popupBtn == monthBtn){
        [monthBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year] ,[_dates month]] forState:UIControlStateNormal];
        qMonth = [NSString stringWithFormat:@"%d%02d",[_dates year] ,[_dates month]];
    }else if(popupBtn == yearBtn){
        [yearBtn setTitle:[NSString stringWithFormat:@"     %d年",[_dates year]] forState:UIControlStateNormal];
        qYear = [NSString stringWithFormat:@"%d",[_dates year]];
    }    
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
    if (plot == [plotView1.hostedGraph plotAtIndex:0]||plot == [plotView1.hostedGraph plotAtIndex:1]) {
		return [dataForPlot1 count];
	}else if ( plot == [plotView2.hostedGraph plotAtIndex:0] ||plot == [plotView2.hostedGraph plotAtIndex:1]) {
		return [dataForPlot2 count];
    }else{
        return 0;
    }
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    if ( [(NSString *)plot.identifier isEqualToString:@"完成"] ) {
        if(fieldEnum == CPTBarPlotFieldBarLocation ){
            return index+1;
        }else{  //CPTBarPlotFieldBarTip
            NSDictionary *dict;
            if(plot == [plotView1.hostedGraph plotAtIndex:0]){      //柱状图1
                dict = [dataForPlot1 objectAtIndex:index];
            }else if(plot == [plotView2.hostedGraph plotAtIndex:0]){    //柱状图2
                dict = [dataForPlot2 objectAtIndex:index];
            }
            return [(NSNumber *)[dict objectForKey:@"complete"] doubleValue];
        }
    }else if( [(NSString *)plot.identifier isEqualToString:@"计划"] ){
        if(fieldEnum == CPTBarPlotFieldBarLocation ){
            return index+1;
        }else{  //CPTBarPlotFieldBarTip
            NSDictionary *dict;
            if(plot == [plotView1.hostedGraph plotAtIndex:1]){      //线图1
                dict = [dataForPlot1 objectAtIndex:index];
            }else if(plot == [plotView2.hostedGraph plotAtIndex:1]){    //线图2
                dict = [dataForPlot2 objectAtIndex:index];
            }
            return [(NSNumber *)[dict objectForKey:@"plan"] doubleValue];
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
    if(num > 0.1){
        newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.1f", 
             [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index]] style:[HDSUtil plotTextStyle:10]];
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
    adapter3 = [[SBJsonStreamParserAdapter alloc] init];
    adapter3.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
    parser2 = [[SBJsonStreamParser alloc] init];
    parser2.delegate = adapter2;
    parser3 = [[SBJsonStreamParser alloc] init];
    parser3.delegate = adapter3;
	
    // 表格数据
	NSString *url,*url2,*url3;
    NSString *titleDate;
    if([HDSUtil isOffline]){    // 离线数据
        if(yearMonthSegment.selectedSegmentIndex == 0){ // 月度
            [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ThruputPlanComplete_list" withExtension:@"json"]]];
            [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ThruputPlanComplete_corpChart" withExtension:@"json"]]];
            [parser3 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ThruputPlanComplete_cargoChart" withExtension:@"json"]]];
            titleDate = [monthBtn titleForState:UIControlStateNormal];
            if(titleDate == nil) titleDate = qMonth;
        }else{
            [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ThruputPlanComplete_listYear" withExtension:@"json"]]];
            [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ThruputPlanComplete_corpChartYear" withExtension:@"json"]]];
            [parser3 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ThruputPlanComplete_cargoChartYear" withExtension:@"json"]]];
            titleDate = [yearBtn titleForState:UIControlStateNormal];
            if(titleDate == nil) titleDate = qYear;
        }
    }else{
        if(yearMonthSegment.selectedSegmentIndex == 0){ // 月度
            url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SThruputComplete/listMonth.json?yearMonth=%@&corps=%@",qMonth,qCompany];
            url2 = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SThruputComplete/listMonthCorpChart.json?yearMonth=%@&corps=%@",qMonth,qCompany];
            url3 = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SThruputComplete/listMonthCargoChart.json?yearMonth=%@&corps=%@",qMonth,qCompany];
            titleDate = [monthBtn titleForState:UIControlStateNormal];
            if(titleDate == nil) titleDate = qMonth;
        }else{
            url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SThruputComplete/listYear.json?year=%@&corps=%@",qYear,qCompany];
            url2 = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SThruputComplete/listYearCorpChart.json?year=%@&corps=%@",qYear,qCompany];
            url3 = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SThruputComplete/listYearCargoChart.json?year=%@&corps=%@",qYear,qCompany];
            titleDate = [yearBtn titleForState:UIControlStateNormal];
            if(titleDate == nil) titleDate = qYear;
        }
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        // 图表数据
        NSURLRequest *theRequest2=[NSURLRequest requestWithURL:[NSURL URLWithString:url2] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest2 delegate:self];
        NSURLRequest *theRequest3=[NSURLRequest requestWithURL:[NSURL URLWithString:url3] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn3 = [[NSURLConnection alloc] initWithRequest:theRequest3 delegate:self];
    }
    
    plotView1.hostedGraph.title = [NSString stringWithFormat:@"%@公司计划完成情况(万吨)",titleDate];
    plotView2.hostedGraph.title = [NSString stringWithFormat:@"%@货类计划完成情况(万吨)",titleDate];
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
            [self loadChildren:node withData:data expand:true];
        }
        [tableView reloadData];
    }else if(parser == parser2){
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:array dataIsTreeNode:false  xLabelKey:@"corp" yLabelKey:[NSArray arrayWithObjects:@"plan",@"complete",nil] yTitleWidth:0 plotNum:2];
    }else if(parser == parser3){
        [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot2 data:array dataIsTreeNode:false   xLabelKey:@"cargo" yLabelKey:[NSArray arrayWithObjects:@"plan",@"complete",nil] yTitleWidth:0 plotNum:2];
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
    }else if(connection == conn3){
        parser = parser3;
    }
    SBJsonStreamParserStatus status = [parser parse:data];
	if (status == SBJsonStreamParserError) {
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"吞吐量计划完成");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"吞吐量计划完成");
	} else{

    }
}


@end
