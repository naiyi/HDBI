//
//  HDS_C_YardStockDensity.m
//  HDBI
//
//  Created by 毅 张 on 12-9-7.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_C_YardStockDensity.h"

@implementation HDS_C_YardStockDensity{
    
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
        self.titleLabel.text = @"堆场堆存密度分析";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    headerNames = [NSArray arrayWithObjects:@"项目",@"进口重箱",@"出口重箱",@"空箱区",@"合计箱量",nil];
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView1 toContainer:plotContainer1 title:@"堆场堆存密度(%)" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"堆存密度",nil] useLegend:NO useLegendIcon:NO];
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot1 = [[NSMutableArray alloc] init];
    
    // 默认全部权限的公司
    [self refreshByComps:[HDSCompanyViewController companys]];
    [self loadData];
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
        if(column == 0)   return 80.0f;
        return 65.0f;
    }
    if(column == 0) return 137.0f;
    return 130.0f;
}

- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"item";
        case 1: return @"if";
        case 2: return @"ef";
        case 3: return @"e";
        case 4: return @"total";
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
    if(fieldEnum == CPTBarPlotFieldBarLocation ){
        return index+1;
    }else{  //CPTBarPlotFieldBarTip
        NSDictionary *dict = [dataForPlot1 objectAtIndex:index];
        return [(NSNumber *)[dict objectForKey:@"num"] doubleValue];
    }
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView)
        return nil;
    
	CPTTextLayer *newLayer = nil;
    double num = [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
    if(num > 0){
        newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.2f", 
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
	
    // 表格数据
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_YardStockDensity" withExtension:@"json"]]];
    }else{
        NSString *url;
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CYardStockDensity/list.json?corps=%@",qCompany];
        
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }
    
}

#pragma mark SBJsonStreamParserAdapterDelegate methods
- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
    NSMutableDictionary *data,*prop;
    NSDictionary *data1,*data2;
    NSDictionary *prop1,*prop2;
    if(parser == parser1){
        HDSTreeNode *node;
        [self.rootArray removeAllObjects];
//        NSAssert(array.count == 2, @"必须有两条数据");
        NSMutableArray *tempArray = [array mutableCopy];
        if(array.count == 2){
            double numIf,numEf,numE,numTotal;
            data1 = [array objectAtIndex:0];
            prop1 = [data1 objectForKey:@"properties"];
            data2 = [array objectAtIndex:1];
            prop2 = [data2 objectForKey:@"properties"];
            numIf = [(NSNumber *)[prop1 objectForKey:@"if"] doubleValue]/[(NSNumber *)[prop2 objectForKey:@"if"] doubleValue]*100;
            numEf = [(NSNumber *)[prop1 objectForKey:@"ef"] doubleValue]/[(NSNumber *)[prop2 objectForKey:@"ef"] doubleValue]*100;
            numE  = [(NSNumber *)[prop1 objectForKey:@"e"] doubleValue]/[(NSNumber *)[prop2 objectForKey:@"e"] doubleValue]*100;
            numTotal = [(NSNumber *)[prop1 objectForKey:@"total"] doubleValue]/[(NSNumber *)[prop2 objectForKey:@"total"] doubleValue]*100;
            NSMutableDictionary *percent = [NSMutableDictionary dictionaryWithObjectsAndKeys:
//                                    [NSString stringWithFormat:@"%.2g%",numIf],@"if",
//                                    [NSString stringWithFormat:@"%.2g%",numEf],@"ef",
//                                    [NSString stringWithFormat:@"%.2g%",numE],@"e",
//                                    [NSString stringWithFormat:@"%.2g%",numTotal],@"total",
                                     [NSNumber numberWithDouble:numIf], @"if", 
                                     [NSNumber numberWithDouble:numEf], @"ef",
                                     [NSNumber numberWithDouble:numE], @"e",
                                     [NSNumber numberWithDouble:numTotal], @"total",
                                     nil];
            [tempArray addObject: [NSDictionary dictionaryWithObject:percent forKey:@"properties"]];
            
            for(int i=0; i<tempArray.count; i++){
                data = [tempArray objectAtIndex:i];
                prop = [data objectForKey:@"properties"];
                switch (i) {
                    case 0: [prop setObject:@"在场箱量" forKey:@"item"];    break;
                    case 1: [prop setObject:@"堆存能力" forKey:@"item"];    break; 
                    case 2: [prop setObject:@"堆存密度(%)" forKey:@"item"];    break; 
                }
                node = [[HDSTreeNode alloc] initWithProperties:prop parent:nil expanded:YES];
                [self.rootArray addObject:node];
            }
            [tableView reloadData];
            
            // 图表
            NSMutableArray *plotArray = [[NSMutableArray alloc] init];
            [plotArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  [percent objectForKey:@"if"] ,@"num",
                                  @"进口重箱",@"label",
                                  nil ] ];
            [plotArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  [percent objectForKey:@"ef"] ,@"num",
                                  @"出口重箱",@"label",
                                  nil ] ];
            [plotArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  [percent objectForKey:@"e"] ,@"num",
                                  @"空箱",@"label",
                                  nil ] ];
            [plotArray addObject:[NSDictionary dictionaryWithObjectsAndKeys:
                                  [percent objectForKey:@"total"] ,@"num",
                                  @"堆存总密度",@"label",
                                  nil ] ];
            [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:plotArray dataIsTreeNode:false  xLabelKey:@"label" yLabelKey:[NSArray arrayWithObjects:@"num",nil] yTitleWidth:0 plotNum:1];
        }
    }
}


- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //	NSLog(@"Connection didReceiveData of length: %u", data.length);
    SBJsonStreamParser *parser ; 
    if(connection == conn1){
        parser = parser1;
    }
    SBJsonStreamParserStatus status = [parser parse:data];
	if (status == SBJsonStreamParserError) {
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"堆场堆存密度");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"堆场堆存密度");
	} else{

    }
}

@end
