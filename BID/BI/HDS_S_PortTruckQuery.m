//
//  HDS_S_PortTruckQuery.m
//  在港车辆查询
//
//  Created by 毅 张 on 12-6-27.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_S_PortTruckQuery.h"

@implementation HDS_S_PortTruckQuery{
    
    CPTGraphHostingView *pieView1;
    CPTGraphHostingView *pieView2;
    
    NSURLConnection *conn1; // 表格数据
    NSURLConnection *conn2; // 图表
    NSURLConnection *conn3; // 图表
    SBJsonStreamParser *parser1;
    SBJsonStreamParser *parser2;
    SBJsonStreamParser *parser3;
    SBJsonStreamParserAdapter *adapter1;
    SBJsonStreamParserAdapter *adapter2;
    SBJsonStreamParserAdapter *adapter3;
}

@synthesize pieContainer1,pieContainer2;
@synthesize pieView;
@synthesize dataForPlot1,dataForPlot2;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification]; 
    
    [self refreshPlotTheme:pieView1];
    [self refreshPlotTheme:pieView2];
}

- (void)fillConditionView:(UIView *)view{
    [super fillConditionView:view corpLine:0];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    if(isSmallView){
        pageViews=[NSArray arrayWithObjects:tableContainer,pieView, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"在港车辆查询";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    headerNames = [NSArray arrayWithObjects:@"货主",@"车号",@"进港时间",@"货名",@"集/疏",@"停时", nil];
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;

    pieView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addPiePlotView:pieView1 toContainer:pieContainer1 title:@"集疏运车数比例" useLegend:YES useLegendIcon:YES];
    pieView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addPiePlotView:pieView2 toContainer:pieContainer2 title:@"不同停时段车数比例" useLegend:YES useLegendIcon:YES];
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot1 = [[NSMutableArray alloc] init];
    self.dataForPlot2 = [[NSMutableArray alloc] init];
    
    // 初始化默认公司
    [self refreshByComps:[HDSCompanyViewController companys]];
    [self loadData];
}


-(void)viewDidLayoutSubviews{
    if(isSmallView)
        return;
    [tableView adjustRightTableViewWidth];
    [tableView positionVerticalScrollBar];
//    pieView1.frame = CGRectInset(pieContainer1.bounds,5.0f,5.0f);
//    pieView2.frame = CGRectInset(pieContainer2.bounds,5.0f,5.0f);
    pieView1.frame = pieContainer1.bounds;
    pieView2.frame = pieContainer2.bounds;
}

- (void)viewDidUnload{
    [self setPieContainer1:nil];
    [self setPieContainer2:nil];
    [self setPieView:nil];
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
        if(column == 0) return 150.0f;
        if(column == 1) return 80.0f;
        if(column == 2) return 110.0f;
        if(column == 4) return 35.0f;
        if(column == 5) return 40.0f;
        return 100.0f;
    }
    if(column == 0) return 200.0f;
    if(column == 1) return 100.0f;
    if(column == 2) return 150.0f;
    if(column == 4) return 50.0f;
    if(column == 5) return 56.0f;
    return 100.0f;
}


- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"client";
        case 1: return @"truck";
        case 2: return @"time";
        case 3: return @"cargo";
        case 4: return @"inOut";
        case 5: return @"stopHours";
        default:return @"";
            
    }
}

#pragma mark -
#pragma mark Plot construction methods

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
    if(anim == [pieView1.hostedGraph.legend animationForKey:@"legendAnimation"]){
        [pieView1 viewWithTag:Legend_Switch_Tag].hidden = NO;
    }else if(anim == [pieView2.hostedGraph.legend animationForKey:@"legendAnimation"]){
        [pieView2 viewWithTag:Legend_Switch_Tag].hidden = NO;
    }
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
    if ( plot == [pieView1.hostedGraph plotAtIndex:0] ) {
		return [dataForPlot1 count];
	}else if ( plot == [pieView2.hostedGraph plotAtIndex:0] ) {
		return [dataForPlot2 count];
	}else {
		return 0;
	}
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    if ( fieldEnum == CPTPieChartFieldSliceWidth ) {
        if(plot == [pieView1.hostedGraph plotAtIndex:0]){   // 进出口
            return [(NSNumber *)[[dataForPlot1 objectAtIndex:index] objectForKey:@"count"] doubleValue];
        }else if(plot == [pieView2.hostedGraph plotAtIndex:0]){ //内外贸
            return [(NSNumber *)[[dataForPlot2 objectAtIndex:index] objectForKey:@"count"] doubleValue];
        }else {
            return 0;
        }
    }else {
        return index;
    }
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView)
        return nil;
    
	CPTTextLayer *newLayer = nil;
    if ( [plot isKindOfClass:[CPTPieChart class]] ) {
        if(plot == [pieView1.hostedGraph plotAtIndex:0]){
            newLayer = [[CPTTextLayer alloc] initWithText:[[dataForPlot1 objectAtIndex:index] objectForKey:@"inOut"] style:[HDSUtil plotTextStyle:10]];
        }else if(plot == [pieView2.hostedGraph plotAtIndex:0]){
            newLayer = [[CPTTextLayer alloc] initWithText:[[dataForPlot2 objectAtIndex:index] objectForKey:@"range"] style:[HDSUtil plotTextStyle:10]];
        }
	}
	return newLayer;
}

//-(void)pieChart:(CPTPieChart *)plot sliceWasSelectedAtRecordIndex:(NSUInteger)index{
//    
//}

-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index{
//    CPTGradient *newInstance = [[CPTGradient alloc] init];
//    newInstance = [newInstance addColorStop:[CPTColor colorWithCGColor:[UIColor whiteColor].CGColor] atPosition:0.0];
//    if(index == 0){
//        newInstance = [newInstance addColorStop:[CPTColor colorWithComponentRed:0 green:0 blue:0.7 alpha:1] atPosition:0.5];
//        newInstance = [newInstance addColorStop:[CPTColor colorWithComponentRed:0 green:0 blue:0.3 alpha:1] atPosition:1.0];
//    }
//    
//    else {
//        newInstance = [newInstance addColorStop:[CPTColor colorWithComponentRed:0 green:0.7 blue:0 alpha:1] atPosition:0.5];
//        newInstance = [newInstance addColorStop:[CPTColor colorWithComponentRed:0 green:0.3 blue:0 alpha:1] atPosition:1.0];
//    }
    CPTGradient *newInstance = [HDSUtil pieChartGradientAtIndex:index];
    newInstance.angle = 270.0f;
	return [CPTFill fillWithGradient:newInstance];
}

-(NSString *)legendTitleForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index{
    if(pieChart == [pieView1.hostedGraph plotAtIndex:0]){
        return [[dataForPlot1 objectAtIndex:index] objectForKey:@"inOut"];
    }else if(pieChart == [pieView2.hostedGraph plotAtIndex:0]){
        return [[dataForPlot2 objectAtIndex:index] objectForKey:@"range"];
    }
    return @"";
}

#pragma mark - 数据读取相关
- (void)loadData {
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
    adapter2 = [[SBJsonStreamParserAdapter alloc] init];
    adapter2.delegate = self;
    adapter3 = [[SBJsonStreamParserAdapter alloc] init];
    adapter3.delegate = self;
    parser2 = [[SBJsonStreamParser alloc] init];
    parser2.delegate = adapter2;
    parser3 = [[SBJsonStreamParser alloc] init];
    parser3.delegate = adapter3;
    
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_PortTruckQuery_list" withExtension:@"json"]]];
        [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_PortTruckQuery_chart1" withExtension:@"json"]]];
        [parser3 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_PortTruckQuery_chart2" withExtension:@"json"]]];
    }else{
        NSString *url,*url2,*url3;
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SPortTruck/list.json?corps=%@",qCompany];
        url2 = [[[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SPortTruck/listIoChart.json?corps=%@",qCompany] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        url3 = [[[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SPortTruck/listTimeChart.json?corps=%@",qCompany] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:url2] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:url3] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
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
        dataForPlot1 = [array copy];
        [pieView1.hostedGraph reloadData];
        CABasicAnimation *rotation1 = [HDSUtil setAnimation:@"transform.rotation" toLayer:[pieView1.hostedGraph plotAtIndex:0] fromValue:M_PI * 3 toValue:0 forKey:@"pieRotation1"];
        rotation1.delegate = self;
    }else if(parser == parser3){
        dataForPlot2 = [array copy];
        [pieView2.hostedGraph reloadData];
        CABasicAnimation *rotation2 = [HDSUtil setAnimation:@"transform.rotation" toLayer:[pieView2.hostedGraph plotAtIndex:0] fromValue:M_PI * 3 toValue:0 forKey:@"pieRotation2"];    
        rotation2.delegate = self;
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"在港车辆查询");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"在港车辆查询");
	} else{
        //        NSLog(@"Parser over.");
    }
}

@end

