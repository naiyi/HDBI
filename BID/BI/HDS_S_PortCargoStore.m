//
//  HDS_S_PortCargoStore.m
//  港存货物查询
//
//  Created by 毅 张 on 12-7-4.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_S_PortCargoStore.h"


#define Legend_Switch_Tag 999

@implementation HDS_S_PortCargoStore{
    
    CPTGraphHostingView *plotView1,*plotView2;
    
    NSURLConnection *conn1; // 表格数据
    NSURLConnection *conn2; // 图表数据
    NSURLConnection *conn3; // 
    SBJsonStreamParser *parser1;
    SBJsonStreamParser *parser2;
    SBJsonStreamParser *parser3;
    SBJsonStreamParserAdapter *adapter1;
    SBJsonStreamParserAdapter *adapter2;
    SBJsonStreamParserAdapter *adapter3;
}

@synthesize plotContainer1,plotContainer2;
@synthesize dataForPlot1,dataForPlot2;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification]; 
    
    [self refreshPlotTheme:plotView1];
    [self refreshPlotTheme:plotView2];
}

- (void)fillConditionView:(UIView *)view{
    [super fillConditionView:view corpLine:0];
    // 货类
    chooseCargoBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    chooseCargoBtn.frame = CGRectMake(20,50,100,31);
    chooseCargoBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    chooseCargoBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [chooseCargoBtn setTitle:@"   选择货类" forState:UIControlStateNormal];
    [chooseCargoBtn addTarget:self action:@selector(chooseCargoTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:chooseCargoBtn];
    // 货类label
    cargoLabel =[[UILabel alloc] initWithFrame:CGRectMake(128, 50, 170, 31)];
    cargoLabel.font = [UIFont fontWithName:@"Heiti SC" size:SmallViewConditionFontSize];
    cargoLabel.lineBreakMode = UILineBreakModeTailTruncation;
    cargoLabel.textAlignment = UITextAlignmentLeft;
    cargoLabel.numberOfLines = 1;
    cargoLabel.backgroundColor = [UIColor clearColor];
    [view addSubview:cargoLabel];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    isLog = true;
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,plotContainer1,plotContainer2, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"港存货物查询";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    headerNames = [NSArray arrayWithObjects:@"库场/区域",@"货类",@"船名",@"货主",@"吨数",@"件数",@"体积", nil];
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView1 toContainer:plotContainer1 title:@"各货主库存吨数对比" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"库存吨数",nil] useLegend:NO useLegendIcon:NO];
    plotView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView2 toContainer:plotContainer2 title:@"各货类库存吨数对比" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"库存吨数",nil] useLegend:NO useLegendIcon:NO];
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot1 = [[NSMutableArray alloc] init];
    self.dataForPlot2 = [[NSMutableArray alloc] init];
    
    // 默认全部权限的公司
    [self refreshByComps:[HDSCompanyViewController companys]];
    // 初始化全部货类
    [self refreshByCargos:[HDSCargoViewController cargos]];
    
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
//    plotView1.frame = CGRectInset(plotContainer1.bounds,5.0f,5.0f);
//    plotView2.frame = CGRectInset(plotContainer2.bounds,5.0f,5.0f);
    plotView1.frame = plotContainer1.bounds;
    plotView2.frame = plotContainer2.bounds;
}

- (void)viewDidUnload{
    [self setPlotContainer1:nil];
    [self setPlotContainer2:nil];
    
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 7;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
//    return 2;
//}
// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column< 3)   return 75.0f;
        if(column==3)   return 160.0f;
        return 60.0f;
    }
    if(column< 3)   return 85.0f;
    if(column==3)   return 200.0f;
    if(column==4)   return 80.0f;
    return 60.0f;
}

- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"yard";
        case 1: return @"cargo";
        case 2: return @"ship";
        case 3: return @"client";
        case 4: return @"wgt";
        case 5: return @"num";
        case 6: return @"vol";
        default:return @"";
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
	}else if ( plot == [plotView2.hostedGraph plotAtIndex:0] ) {
		return [dataForPlot2 count];
    }else{
        return 0;
    }
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    if(fieldEnum == CPTBarPlotFieldBarLocation ){
        return index+1;
    }else{  //CPTBarPlotFieldBarTip
        NSDictionary *dict;
        if(plot == [plotView1.hostedGraph plotAtIndex:0]){      //柱状图1
            dict = [dataForPlot1 objectAtIndex:index];
        }else if(plot == [plotView2.hostedGraph plotAtIndex:0]){    //柱状图2
            dict = [dataForPlot2 objectAtIndex:index];
        }
        return [(NSNumber *)[dict objectForKey:@"wgt"] doubleValue];
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

-(CPTFill *)barFillForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index{
	return [CPTFill fillWithGradient:[HDSUtil barChartGradientAtIndex:index]];
}


-(NSString *)transformXLabel:(NSString *)xLabel{
    if(xLabel.length>8){
        return [[xLabel substringWithRange:NSMakeRange(0, 8)] stringByAppendingString:@"..."];
    }
    return xLabel;
}

-(NSInteger)xAxisMaxCount:(NSInteger)plotNum plotView:(CPTGraphHostingView *)_plotView{
    if(isSmallView){
        return 7;
    }else{
        return 10;
    }
}



#pragma mark - 数据读取相关
- (void)loadData {
    if(isLog){
        logBegin = [NSDate date];
    }
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
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_PortCargoStore_list" withExtension:@"json"]]];
        [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_PortCargoStore_chart1" withExtension:@"json"]]];
        [parser3 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_PortCargoStore_chart2" withExtension:@"json"]]];
    }else{
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SStorageCargo/list.json?cargoKindCod=%@&corps=%@",qCargo,qCompany];
        url2 = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SStorageCargo/listClientChart.json?cargoKindCod=%@&corps=%@",qCargo,qCompany];
        url3 = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SStorageCargo/listCargoKindChart.json?cargoKindCod=%@&corps=%@",qCargo,qCompany];
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        // 图表数据
        NSURLRequest *theRequest2=[NSURLRequest requestWithURL:[NSURL URLWithString:url2] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest2 delegate:self];
        NSURLRequest *theRequest3=[NSURLRequest requestWithURL:[NSURL URLWithString:url3] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn3 = [[NSURLConnection alloc] initWithRequest:theRequest3 delegate:self];
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
        }
        if(isLog){
            logEnd = [NSDate date];
            double interval = [logEnd timeIntervalSinceDate:logBegin];
            NSLog(@"数据解析时间:%f",interval);
            NSLog(@"解析后数据量:%d",array.count);
        }
        [tableView reloadData];
    }else if(parser == parser2){
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:array dataIsTreeNode:false xLabelKey:@"client" yLabelKey:[NSArray arrayWithObjects:@"wgt",nil] yTitleWidth:0 plotNum:1];
    }else if(parser == parser3){
        [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot2 data:array dataIsTreeNode:false xLabelKey:@"cargoKind" yLabelKey:[NSArray arrayWithObjects:@"wgt",nil] yTitleWidth:0 plotNum:1];
    }
}

- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {

}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //	NSLog(@"Connection didReceiveData of length: %u", data.length);
    SBJsonStreamParser *parser ; 
    if(connection == conn1){
        parser = parser1;
        if(isLog){
            logEnd = [NSDate date];
            double interval = [logEnd timeIntervalSinceDate:logBegin];
            NSLog(@"网络接收字节数:%d",data.length);
            NSLog(@"网络传输时间:%f",interval);
            logBegin = [NSDate date];
        }
    }else if(connection == conn2){
        parser = parser2;
    }else if(connection == conn3){
        parser = parser3;
    }
    SBJsonStreamParserStatus status = [parser parse:data];
	if (status == SBJsonStreamParserError) {
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"港存货物查询");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"港存货物查询");
	} else{
        //        NSLog(@"Parser over.");
    }
}


@end
