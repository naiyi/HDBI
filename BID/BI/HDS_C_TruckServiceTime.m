//
//  HDS_C_TruckServiceTime.m
//  HDBI
//
//  Created by 毅 张 on 12-9-3.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_C_TruckServiceTime.h"

@implementation HDS_C_TruckServiceTime{
    
    CPTGraphHostingView *plotView;
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
    [monthBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal.png"] forState:UIControlStateNormal];
    [monthBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight.png"] forState:UIControlStateHighlighted];
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    [monthBtn setTitleColor:color forState:UIControlStateNormal];
    
    [self refreshPlotTheme:plotView];
}

- (void)fillConditionView:(UIView *)view{
    // 年度
    monthBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    monthBtn.frame = CGRectMake(20,10,100,31);
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
        self.titleLabel.text = @"外线拖车服务时间";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    headerNames= [NSArray arrayWithObjects:@"年份",@"项目",@"1月",@"2月",@"3月",@"4月",@"5月",
                  @"6月",@"7月",@"8月",@"9月",@"10月",@"11月",@"12月",@"平均",nil];
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    
    plotView = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView toContainer:plotContainer title:@"平均停时同比分析" xTitle:nil yTitle:nil plotNum:2 identifier:[NSArray arrayWithObjects:@"当年",@"去年",nil] useLegend:YES useLegendIcon:NO];
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot = [[NSMutableArray alloc] init];
    
    // 初始化默认年度
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dates = [calendar components:NSYearCalendarUnit fromDate:[NSDate date]];
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
    plotView.frame = plotContainer.bounds;
}

- (void)viewDidUnload{
    [self setPlotContainer:nil];
    [self setMonthBtn:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 15;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
//    return 1;
//}
// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column==0)   return 50.0f;
        if(column==1)   return 50.0f;
        return 50.0f;
    }
    if(column==0)   return 50.0f;
    if(column==1)   return 50.0f;
    return 60.0f;
}


- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"year";
        case 1: return @"item";
        case 2: return @"month1";
        case 3: return @"month2";
        case 4: return @"month3";
        case 5: return @"month4";
        case 6: return @"month5";
        case 7: return @"month6";
        case 8: return @"month7";
        case 9: return @"month8";
        case 10:return @"month9";
        case 11:return @"month10";
        case 12:return @"month11";
        case 13:return @"month12";
        case 14:return @"monthAvg";
        default:return @"";
    }
}

//- (NSInteger)tableView:(HDSTableView *)tableView canBeExpandedColumnIndexAtNode:(HDSTreeNode *)node{
//    return 0;
//}

-(NSInteger)xAxisMaxCount:(NSInteger)plotNum plotView:(CPTGraphHostingView *)_plotView{
    if(isSmallView){
        return 8/plotNum+2;
    }else{
        return 12;
    }
}

-(void)tableView:(HDSTableView *)tableView didSelectRowAtNode:(HDSTreeNode *)node{
    NSString *item = [node.properties objectForKey:@"item"];
    int index[2];
    if([item isEqualToString:@"收箱"]){
        index[0] = 0;   index[1] = 3;
    }else if([item isEqualToString:@"提箱"] ){
        index[0] = 1;   index[1] = 4;
    }else if([item isEqualToString:@"平均"] ){  //平均
        index[0] = 2;   index[1] = 5;
    }else{
        return;
    }
    plotView.hostedGraph.title = [NSString stringWithFormat:@"%@停时同比分析",item];
    
    HDSTreeNode *first = [self.rootArray objectAtIndex:index[0]];
    HDSTreeNode *second= [self.rootArray objectAtIndex:index[1]];
    NSMutableArray *array = [[NSMutableArray alloc] initWithCapacity:12];
    for(int i=1; i<=12; i++){
        NSMutableDictionary *dict = [[NSMutableDictionary alloc] init];
        NSNumber *n1 =[first.properties objectForKey:[NSString stringWithFormat:@"month%i",i]];
        NSNumber *n2 =[second.properties objectForKey:[NSString stringWithFormat:@"month%i",i]];
        [dict setObject:[NSString stringWithFormat:@"%i月",i] forKey:@"month"];
        [dict setObject:n1 forKey:@"thisYear"];
        [dict setObject:n2 forKey:@"lastYear"];
        [array addObject:dict];
    }
    
    [self refreshBarPlotView:plotView dataForPlot:dataForPlot data:array dataIsTreeNode:false  xLabelKey:@"month" yLabelKey:[NSArray arrayWithObjects:@"thisYear",@"lastYear",nil] yTitleWidth:0 plotNum:2];
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    [monthBtn setTitle:[NSString stringWithFormat:@"     %d年",[_dates year]] forState:UIControlStateNormal];
    qMonth = [NSString stringWithFormat:@"%d",[_dates year]]; 
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
    if ( [(NSString *)plot.identifier isEqualToString:@"当年"] ) {
        if(fieldEnum == CPTBarPlotFieldBarLocation ){
            return index+1;
        }else{  //CPTBarPlotFieldBarTip
            NSDictionary *dict = (NSDictionary *)[dataForPlot objectAtIndex:index];
            return [(NSNumber *)[dict objectForKey:@"thisYear"] doubleValue];
        }
    }else if( [(NSString *)plot.identifier isEqualToString:@"去年"] ){
        if(fieldEnum == CPTBarPlotFieldBarLocation ){
            return index+1;
        }else{  //CPTBarPlotFieldBarTip
            NSDictionary *dict = (NSDictionary *)[dataForPlot objectAtIndex:index];
            return [(NSNumber *)[dict objectForKey:@"lastYear"] doubleValue];
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
    if(num>0){
        newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.0f", 
                            num]style:[HDSUtil plotTextStyle:10]];
    }
    
	return newLayer;
}

//-(CPTFill *)barFillForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index{
//	return [CPTFill fillWithGradient:[HDSUtil barChartGradientAtIndex:index]];
//}

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
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_TruckServiceTime" withExtension:@"json"]]];
    }else{
        // 表格数据
        NSString *url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CTruckServiceTime/list.json?year=%@&corps=%@",qMonth,qCompany];
        
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
            NSMutableDictionary *prop = [data objectForKey:@"properties"];
            switch (i) {
                case 0:
                    [prop setObject:qMonth forKey:@"year"];
                    [prop setObject:@"收箱" forKey:@"item"];
                    break;
                case 1:
                    [prop setObject:@"提箱" forKey:@"item"];
                    break;
                case 2:
                    [prop setObject:@"平均" forKey:@"item"];
                    break;
                case 3:
                    [prop setObject:[NSString stringWithFormat:@"%i",[qMonth intValue]-1] forKey:@"year"];
                    [prop setObject:@"收箱" forKey:@"item"];
                    break;
                case 4:
                    [prop setObject:@"提箱" forKey:@"item"];
                    break;
                case 5:
                    [prop setObject:@"平均" forKey:@"item"];
                    break;
                case 6:
                    [prop setObject:@"同比" forKey:@"year"];
                    [prop setObject:@"平均" forKey:@"item"];
                    break;   
                default:
                    break;
            }
            node = [[HDSTreeNode alloc] initWithProperties:prop parent:nil expanded:YES];
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"外线拖车服务时间");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"外线拖车服务时间");
	} else{

    }
}

- (IBAction)changeMonthTaped:(UIButton *)sender {
    if(datePopover == nil){
        HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearPickerFormat popupBtn:sender];
        picker.delegate = self;
        datePopover= [[UIPopoverController alloc] initWithContentViewController:picker];
        datePopover.popoverContentSize = picker.view.frame.size;
        datePopover.delegate = picker;
    }
    [datePopover presentPopoverFromRect:monthBtn.frame inView:[monthBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}
@end
