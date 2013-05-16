//
//  HDS_C_DeviceStatus.m
//  HDBI
//
//  Created by 毅 张 on 12-9-4.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_C_DeviceStatus.h"

@implementation HDS_C_DeviceStatus{
    CPTGraphHostingView *plotView1;
    
    NSURLConnection *conn1; // 表格数据
    SBJsonStreamParser *parser1;
    SBJsonStreamParserAdapter *adapter1;
    NSURLConnection *conn2; // 图表数据
    SBJsonStreamParser *parser2;
    SBJsonStreamParserAdapter *adapter2;
    
}

@synthesize plotContainer1;
@synthesize dataForPlot1;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification];
    [self refreshPlotTheme:plotView1];
}

- (void)fillConditionView:(UIView *)view{
    [super fillConditionView:view corpLine:0];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,plotContainer1, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"设备状态监控";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    headerNames = [NSArray arrayWithObjects:@"公司",@"设备类别1",@"设备类别2",@"状态",@"数量",nil];
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    tableView.treeInOneCell = false;
    tableView.dataMaxDepth = 4;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addPiePlotView:plotView1 toContainer:plotContainer1 title:@"设备状态分布" useLegend:YES useLegendIcon:YES];
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot1 = [[NSMutableArray alloc] init];
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
    CPTLegend *theLegend = plotView1.hostedGraph.legend;
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
    plotView1.frame = plotContainer1.bounds;
}

- (void)viewDidUnload{
    [self setPlotContainer1:nil];
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
        if(column == 0) return 50.0f;
        if(column == 1) return 95.0f;
        if(column == 2) return 80.0f;
        if(column == 3) return 40.0f;
        return 40.0f;
    }
    if(column == 0) return 100.0f;
    if(column == 1) return 170.0f;
    if(column == 2) return 170.0f;
    if(column == 3) return 100.0f;
    return 117.0f;
}

- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"corp";
        case 1: return @"kind1";
        case 2: return @"kind2";
        case 3: return @"status";
        case 4: return @"num";
        default:return @"";
    }
}

- (NSInteger)tableView:(HDSTableView *)tableView canBeExpandedColumnIndexAtNode:(HDSTreeNode *)node{
    if(node == nil)
        return 0;
    if(node.depth == 3)
        return -1;
    return node.depth;
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
        return [(NSNumber *)[[dataForPlot1 objectAtIndex:index] objectForKey:@"num"] doubleValue];
    }else {
        return index;
    }
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView)
        return nil;
    
	CPTTextLayer *newLayer = nil;
    if ( [plot isKindOfClass:[CPTPieChart class]] ) {
        if([self doubleForPlot:plot field:CPTPieChartFieldSliceWidth recordIndex:index] >0){
            newLayer = [[CPTTextLayer alloc] initWithText:[[dataForPlot1 objectAtIndex:index] objectForKey:@"status"] style:[HDSUtil plotTextStyle:10]];
        }
	}
	return newLayer;
}

//-(void)pieChart:(CPTPieChart *)plot sliceWasSelectedAtRecordIndex:(NSUInteger)index{
//    
//}

-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index{
    CPTGradient *newInstance = [HDSUtil pieChartGradientAtIndex:index];
    newInstance.angle = 270.0f;
	return [CPTFill fillWithGradient:newInstance];
}

-(NSString *)legendTitleForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index{
    return [[dataForPlot1 objectAtIndex:index] objectForKey:@"status"];
}

#pragma mark - 数据读取相关
- (void)loadData {
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
	
    // 表格数据
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_DeviceStatusGrid" withExtension:@"json"]]];
    }else{
        NSString *url;
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CDeviceStatus/list.json?corps=%@",qCompany];
        
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }
    
}

#pragma mark SBJsonStreamParserAdapterDelegate methods
- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
    NSDictionary *data;
    NSMutableDictionary *prop;
    if(parser == parser1){
        HDSTreeNode *node;
        [self.rootArray removeAllObjects];
        for(int i=0; i<array.count; i++){
            data = [array objectAtIndex:i];
            prop = [data objectForKey:@"properties"] ;
            node = [[HDSTreeNode alloc] initWithProperties:prop parent:nil expanded:YES];
            [self.rootArray addObject:node];
            [self loadChildren:node withData:data];
        }
        [tableView reloadData];
        [tableView doSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
    }else if(parser == parser2){
        dataForPlot1 = [array copy];
        [plotView1.hostedGraph reloadData];
        CABasicAnimation *rotation1 = [HDSUtil setAnimation:@"transform.rotation" toLayer:[plotView1.hostedGraph plotAtIndex:0] fromValue:M_PI * 3 toValue:0 forKey:@"pieRotation1"];
        rotation1.delegate = self;
    }
}

-(void)tableView:(HDSTableView *)tableView didSelectRowAtNode:(HDSTreeNode *)node{
    if(node.depth>=3)   return;
    NSString *corpCod,*kindCod1,*kindCod2;
    NSString *corp,*kind1,*kind2;
    if(node.depth == 0){
        corpCod = [node.properties objectForKey:@"corpCod"];
        corp = [node.properties objectForKey:@"corp"];
    }else if(node.depth == 1){
        corpCod = [node.parent.properties objectForKey:@"corpCod"];
        kindCod1= [node.properties objectForKey:@"kindCod1"];
        corp = [node.parent.properties objectForKey:@"corp"];
        kind1= [node.properties objectForKey:@"kind1"];
    }else if(node.depth == 2){
        corpCod = [node.parent.parent.properties objectForKey:@"corpCod"];
        kindCod1= [node.parent.properties objectForKey:@"kindCod1"];
        kindCod2= [node.properties objectForKey:@"kindCod2"];
        corp = [node.parent.parent.properties objectForKey:@"corp"];
        kind1= [node.parent.properties objectForKey:@"kind1"];
        kind2= [node.properties objectForKey:@"kind2"];
    }
    
    NSString *url;
    NSURLRequest *theRequest;
    adapter2 = [[SBJsonStreamParserAdapter alloc] init];
    adapter2.delegate = self;
    parser2 = [[SBJsonStreamParser alloc] init];
    parser2.delegate = adapter2;
    
    if([HDSUtil isOffline]){    // 离线数据
        [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_DeviceStatusChart" withExtension:@"json"]]];
    }else{
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CDeviceStatus/listChart.json?corpCod=%@",corpCod];
        if(kindCod1){
            url = [url stringByAppendingFormat:@"&kindCod1=%@",kindCod1];
        }
        if(kindCod2){
            url = [url stringByAppendingFormat:@"&kindCod2=%@",kindCod2];
        }
        theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }
    NSMutableString *title = [NSMutableString stringWithString:corp];
    if(kind1){
        [title appendString:@"/"];  [title appendString:kind1];
    }
    if(kind2){
        [title appendString:@"/"];  [title appendString:kind2];
    }
    [title appendString:@"设备状态分布"];
    plotView1.hostedGraph.title = title;
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"设备状态监控");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"设备状态监控");
	} else{

    }
}

@end
