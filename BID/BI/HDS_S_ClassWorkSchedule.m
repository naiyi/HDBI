//
//  HDS_S_ClassWorkSchedule.m
//  班次作业进度
//
//  Created by 毅 张 on 12-7-4.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_S_ClassWorkSchedule.h"

#define Legend_Switch_Tag 999

@implementation HDS_S_ClassWorkSchedule{
    
    CPTGraphHostingView *plotView1;
    
    UIPopoverController *datePopover;
    
    NSURLConnection *conn1; // 表格数据
    SBJsonStreamParser *parser1;
    SBJsonStreamParserAdapter *adapter1;

    NSString *qDate;
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
        self.titleLabel.text = @"班次作业进度查询";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    headerNames = [NSArray arrayWithObjects:@"作业线",@"船名",@"货名",@"装卸",@"配载吨数",@"完成吨数",@"剩余吨数",@"作业开始时间",@"作业小时数",@"作业效率(吨/小时)",@"预计剩余小时数",nil];
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    tableView.forceCalHeight = true;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView1 toContainer:plotContainer1 title:@"各作业线完成情况对比" xTitle:nil yTitle:nil plotNum:2 identifier:[NSArray arrayWithObjects:@"完成",@"计划",nil] useLegend:YES useLegendIcon:NO];
    
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
    return 10;
}

- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
    return 1;
}
// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column==0)   return 140.0f;
        if(column==3)   return 30.0f;
        if(column==7)   return 110.0f;
        if(column==9 || column==10)   return 115.0f;
        return 75.0f;
    }
    if(column==0)   return 200.0f;
    if(column==3)   return 40.0f;
    if(column==7)   return 140.0f;
    if(column==9 || column==10)   return 150.0f;
    return 97.0f;
}

- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"line";
        case 1: return @"shipNam";
        case 2: return @"cargoNam";
        case 3: return @"unload";
        case 4: return @"planWgt";
        case 5: return @"workWgt";
        case 6: return @"remainWgt";
        case 7: return @"beginTim";
        case 8: return @"workHour";
        case 9: return @"efficiency";
        case 10: return @"remainHour";
        default:return @"";
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
    return [dataForPlot1 count];
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    if ( [(NSString *)plot.identifier isEqualToString:@"完成"] ) {
        if(fieldEnum == CPTBarPlotFieldBarLocation ){
            return index+1;
        }else{  //CPTBarPlotFieldBarTip
            NSDictionary *dict;
            dict = [(HDSTreeNode *)[dataForPlot1 objectAtIndex:index] properties] ;
            return [(NSNumber *)[dict objectForKey:@"workWgt"] doubleValue];
        }
    }else if( [(NSString *)plot.identifier isEqualToString:@"计划"] ){
        if(fieldEnum == CPTBarPlotFieldBarLocation ){
            return index+1;
        }else{  //CPTBarPlotFieldBarTip
            NSDictionary *dict;
            dict = [(HDSTreeNode *)[dataForPlot1 objectAtIndex:index] properties];
            return [(NSNumber *)[dict objectForKey:@"planWgt"] doubleValue];
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
        newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.0f", 
            [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index]] style:[HDSUtil plotTextStyle:10]];
    }
    
	return newLayer;
}

-(NSString *)transformXLabel:(NSString *)xLabel{
    if(xLabel.length>10){
        return [[xLabel substringWithRange:NSMakeRange(0, 10)] stringByAppendingString:@"..."];
    }
    return xLabel;
}

#pragma mark - 数据读取相关
- (void)loadData {
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
	
    // 表格数据
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ClassWorkSchedule" withExtension:@"json"]]];
    }else{
        NSString *url;
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SClassWorkSchedule/list.json?corps=%@",qCompany];
        
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
        }
        [tableView reloadData];
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:self.rootArray dataIsTreeNode:true xLabelKey:@"line" yLabelKey:[NSArray arrayWithObjects:@"planWgt",@"workWgt",nil] yTitleWidth:0 plotNum:2];
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"班次作业进度");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"班次作业进度");
	} else{
        //        NSLog(@"Parser over.");
    }
}

@end