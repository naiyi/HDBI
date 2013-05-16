//
//  HDS_S_CargoIncomeCost.m
//  HDBI
//
//  Created by 毅 张 on 12-8-6.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_S_CargoIncomeCost.h"
#import "UIView+AddLine.h"
#import "HDSGradientView.h"

#define COL0_WIDTH 110.0f
#define OTHER_COL_WIDTH 100.0f
#define COL_HEIGHT 20.0f
#define SMALL_COL0_WIDTH 95.0f
#define SMALL_OTHER_COL_WIDTH 90.0f
#define SMALL_COL_HEIGHT 15.0f

@implementation HDS_S_CargoIncomeCost{
    
    CPTGraphHostingView *plotView1;
    CPTGraphHostingView *plotView2;
    
    UIPopoverController *beginMonthPopover;
    UIPopoverController *endMonthPopover;
    
    NSURLConnection *conn1; // 表格数据
    NSURLConnection *conn2; // 环比图表
    NSURLConnection *conn3; // 同比图表
    SBJsonStreamParser *parser1;
    SBJsonStreamParser *parser2;
    SBJsonStreamParser *parser3;
    SBJsonStreamParserAdapter *adapter1;
    SBJsonStreamParserAdapter *adapter2;
    SBJsonStreamParserAdapter *adapter3;
    
    NSString *qBeginDate;
    NSString *qEndDate;
}

@synthesize barContainer1,barContainer2;
@synthesize dataForPlot1,dataForPlot2;
@synthesize beginDateBtn;
@synthesize endDateBtn;
@synthesize toLabel;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification];
    HDSSkinType skinType = [HDSUtil skinType];
    
    [beginDateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal_110.png"] forState:UIControlStateNormal];
    [beginDateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight_110.png"] forState:UIControlStateHighlighted];
    [endDateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal_110.png"] forState:UIControlStateNormal];
    [endDateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight_110.png"] forState:UIControlStateHighlighted];
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    [beginDateBtn setTitleColor:color forState:UIControlStateNormal];
    [endDateBtn setTitleColor:color forState:UIControlStateNormal];
    
    [self refreshPlotTheme:plotView1];
    [self refreshPlotTheme:plotView2];
}

- (void)fillConditionView:(UIView *)view{
    // 开始日期
    beginDateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    beginDateBtn.frame = CGRectMake(20,10,119,31);
    beginDateBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    beginDateBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [beginDateBtn addTarget:self action:@selector(changeMonthTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:beginDateBtn];
    // 结束日期
    endDateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    endDateBtn.frame = CGRectMake(147,10,119,31);
    endDateBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    endDateBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [endDateBtn addTarget:self action:@selector(changeMonthTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:endDateBtn];
    
    [super fillConditionView:view];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,barContainer1,barContainer2, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"单货种收入成本分析";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addLinePlotView:plotView1 toContainer:barContainer1 title:@"单吨装卸成本环比变化趋势(元/吨)" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"装卸成本环比",nil] useLegend:NO useLegendIcon:NO];
    plotView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addLinePlotView:plotView2 toContainer:barContainer2 title:@"单吨装卸成本同比变化趋势(元/吨)" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"装卸成本同比",nil] useLegend:NO useLegendIcon:NO];
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot1 = [[NSMutableArray alloc] init];
    self.dataForPlot2 = [[NSMutableArray alloc] init];
    
    // 初始化默认月份
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:[NSDate date]];
    [self refreshByDates:dates fromPopupBtn:beginDateBtn];
    [self refreshByDates:dates fromPopupBtn:endDateBtn];
    // 初始化默认公司
    [self refreshByComps:[HDSCompanyViewController companys]];
    
    [self loadData];
}

-(NSInteger)xAxisMaxCount:(NSInteger)plotNum plotView:(CPTGraphHostingView *)_plotView{
    return 12;
}

-(void)viewDidLayoutSubviews{
    if(isSmallView)
        return;
    [tableView adjustRightTableViewWidth];
    [tableView positionVerticalScrollBar];
    plotView1.frame = barContainer1.bounds;
    plotView2.frame = barContainer2.bounds;
}


- (void)viewDidUnload{
    [self setBarContainer1:nil];
    [self setBarContainer2:nil];
    [self setBeginDateBtn:nil];
    [self setEndDateBtn:nil];
    [self setToLabel:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 10;
}

- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
    return 1;
}

- (CGFloat)heightForHeaderCellOfTableView:(HDSTableView *)tableView{
    if(isSmallView){
        return SMALL_COL_HEIGHT*2;
    }
    return COL_HEIGHT*2;
}
// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column == 0) return SMALL_COL0_WIDTH;
        return SMALL_OTHER_COL_WIDTH;
    }
    if(column == 0) return COL0_WIDTH;
    return OTHER_COL_WIDTH;
}

// 复合表头
- (UIView *)tableView:(HDSTableView *)_tableView multiRowHeaderInTableViewIndex:(NSInteger)tableViewIndex{
    float col0Width = (isSmallView?SMALL_COL0_WIDTH:COL0_WIDTH)+1; 
    float otherColWidth = (isSmallView?SMALL_OTHER_COL_WIDTH:OTHER_COL_WIDTH)+1;
    float colHeight = isSmallView?SMALL_COL_HEIGHT:COL_HEIGHT;
    HDSGradientView *header = [HDSUtil getTableViewMultiHeaderBackgroundView];
    
    CGRect rects[13] = {  
        CGRectMake(1, 0, col0Width, colHeight*2),// 货类名称
        CGRectMake(1,0, otherColWidth*3, colHeight),//收入
        CGRectMake(1,colHeight, otherColWidth, colHeight),//装卸收入
        CGRectMake(1+otherColWidth,colHeight, otherColWidth, colHeight),//堆存收入
        CGRectMake(1+otherColWidth*2,colHeight, otherColWidth, colHeight),//港务管理收入
        CGRectMake(1+otherColWidth*3,0, otherColWidth*3, colHeight),//成本
        CGRectMake(1+otherColWidth*3,colHeight, otherColWidth, colHeight),//装卸成本
        CGRectMake(1+otherColWidth*4,colHeight, otherColWidth, colHeight),//堆存成本
        CGRectMake(1+otherColWidth*5,colHeight, otherColWidth, colHeight),//港务管理成本
        CGRectMake(1+otherColWidth*6,0, otherColWidth, colHeight*2),//装卸吨
        CGRectMake(1+otherColWidth*7,0, otherColWidth, colHeight*2),//单吨收入
        CGRectMake(1+otherColWidth*8,0, otherColWidth, colHeight*2),//单吨成本
        CGRectMake(1+otherColWidth*9,0, otherColWidth, colHeight*2) //单吨利润
    };
    NSArray *titles = [NSArray arrayWithObjects:
                       @"货类名称",@"收入",@"装卸收入",@"堆存收入",@"港务管理收入",@"成本",@"装卸成本",
                       @"堆存成本",@"港务管理成本",@"装卸吨",@"单吨收入",@"单吨成本",@"单吨利润",nil];
    UILabel *cell;
    int beginIndex,endIndex;
    if(tableViewIndex == 0){
        beginIndex = 0;
        endIndex = 1;
    }else{
        beginIndex = 1;
        endIndex = 13;
    }
    for (int i=beginIndex; i<endIndex; i++) {
        cell = [[UILabel alloc] initWithFrame:rects[i]];
        cell.lineBreakMode = UILineBreakModeWordWrap;
        cell.text = [titles objectAtIndex:i];
        cell.textAlignment = UITextAlignmentCenter;
        cell.textColor = [UIColor whiteColor];
        cell.font = _tableView.titleFont;;
        cell.backgroundColor = [UIColor clearColor];
        if([HDSUtil skinType] == HDSSkinBlue){
            [cell addVerticalLineWithWidth:1 color:[UIColor blackColor] atX:rects[i].size.width-1];
            [cell addBottomLineWithWidth:1 color:[UIColor blackColor]];   
        }else{
            if(beginIndex == 0){
                [header addVerticalLineWithWidth:1 color:[HDSUtil plotBorderColor] atX:col0Width];
            }
        }
        
        [header addSubview:cell];
    }
    if([HDSUtil skinType] == HDSSkinBlue){
        [header addVerticalLineWithWidth:1 color:[UIColor blackColor] atX:0];
    }
    return header;
}

// @"货类名称",@"装卸收入",@"堆存收入",@"港务管理收入",@"装卸成本",@"堆存成本",@"港务管理成本",@"装卸吨",@"单吨收入",@"单吨成本",@"单吨利润"
- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"cargo";
        case 1: return @"unloadIncome";
        case 2: return @"stockIncome";
        case 3: return @"manageIncom3";
        case 4: return @"unloadCost";
        case 5: return @"stockCost";
        case 6: return @"manageCost";
        case 7: return @"cargoWgt";
        case 8: return @"unitIncome";
        case 9: return @"unitCost";
        case 10:return @"unitProfit";
        default:return @""; 
    }
}

-(void)tableView:(HDSTableView *)tableView didSelectRowAtNode:(HDSTreeNode *)node{
    NSString *cargo=[node.properties objectForKey:@"cargo"];
    
    NSString *urlHB,*urlTB;
    NSURLRequest *theRequest;
    adapter2 = [[SBJsonStreamParserAdapter alloc] init];
    adapter2.delegate = self;
    adapter3 = [[SBJsonStreamParserAdapter alloc] init];
    adapter3.delegate = self;
    parser2 = [[SBJsonStreamParser alloc] init];
    parser2.delegate = adapter2;
    parser3 = [[SBJsonStreamParser alloc] init];
    parser3.delegate = adapter3;
    
    if([HDSUtil isOffline]){    // 离线数据
        [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_CargoIncomeCost_chart1" withExtension:@"json"]]];
        [parser3 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_CargoIncomeCost_chart2" withExtension:@"json"]]];
    }else{
        urlHB = [[[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SCargoIncomeCost/listHbChart.json?beginYM=%@&endYM=%@&corps=%@&cargoKind=%@",qBeginDate,qEndDate,qCompany,cargo] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        urlTB = [[[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SCargoIncomeCost/listTbChart.json?beginYM=%@&endYM=%@&corps=%@&cargoKind=%@",qBeginDate,qEndDate,qCompany,cargo] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:urlHB] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:urlTB] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn3 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }
    plotView1.hostedGraph.title = [NSString stringWithFormat:@"%@单吨装卸成本环比变化趋势(元/吨)",cargo];
    plotView2.hostedGraph.title = [NSString stringWithFormat:@"%@单吨装卸成本同比变化趋势(元/吨)",cargo];
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    if(popupBtn == nil){    // smallView 时初始化没有按钮
        qBeginDate = [NSString stringWithFormat:@"%d%02d",[_dates year],[_dates month]];
        qEndDate = [NSString stringWithFormat:@"%d%02d",[_dates year],[_dates month]];
        return;
    }
    
    if(popupBtn == beginDateBtn){
        [beginDateBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year],[_dates month]] forState:UIControlStateNormal];
        qBeginDate = [NSString stringWithFormat:@"%d%02d",[_dates year],[_dates month]];
        currentBeginDate = _dates;
        // 若结束月份小于开始月份，则自动更新为开始月份
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *bDate = [calendar dateFromComponents:currentBeginDate];
        NSDate *eDate = [calendar dateFromComponents:currentEndDate];
        if([bDate timeIntervalSinceDate:eDate]>0){
            [endDateBtn setTitle:[beginDateBtn titleForState:UIControlStateNormal] forState:UIControlStateNormal];
            qEndDate = qBeginDate;
            currentEndDate = [currentBeginDate copy];
            // 回写pickView的选中行
            ((HDSYearMonthPicker *)endMonthPopover.contentViewController).scrollToDate = currentEndDate;
        }
    }else if(popupBtn == endDateBtn){
        [endDateBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year],[_dates month]] forState:UIControlStateNormal];
        qEndDate = [NSString stringWithFormat:@"%d%02d",[_dates year],[_dates month]];
        currentEndDate = _dates;
        // 若开始月份大于结束月份，则自动更新为结束月份
        NSCalendar *calendar = [NSCalendar currentCalendar];
        NSDate *bDate = [calendar dateFromComponents:currentBeginDate];
        NSDate *eDate = [calendar dateFromComponents:currentEndDate];
        if([bDate timeIntervalSinceDate:eDate]>0){
            [beginDateBtn setTitle:[endDateBtn titleForState:UIControlStateNormal] forState:UIControlStateNormal];
            qBeginDate = qEndDate;
            currentBeginDate = [currentEndDate copy];
            ((HDSYearMonthPicker *)beginMonthPopover.contentViewController).scrollToDate = currentBeginDate;
        }
    } 
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
    if ( plot == [plotView1.hostedGraph plotAtIndex:0]) {
		return [dataForPlot1 count];
	}else if ( plot == [plotView2.hostedGraph plotAtIndex:0] ) {
		return [dataForPlot2 count];
	}else {
		return 0;
	}
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    if ( [plot isKindOfClass:[CPTScatterPlot class]]){
        if(fieldEnum == CPTBarPlotFieldBarLocation ){
            return index+1;
        }else{  //CPTBarPlotFieldBarTip
            NSDictionary *dict;
            if(plot == [plotView1.hostedGraph plotAtIndex:0]){
                dict = [dataForPlot1 objectAtIndex:index];
            }else if(plot == [plotView2.hostedGraph plotAtIndex:0]){
                dict = [dataForPlot2 objectAtIndex:index];
            }
            return [(NSNumber *)[dict objectForKey:@"unitCost"] doubleValue];
        }
    }
    return 0;
    
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView && ![plot isKindOfClass:[CPTPieChart class]] )
        return nil;
    
    CPTTextLayer *newLayer;
    double num = [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
    if(num > 0){
        newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.2f", num] style:[HDSUtil plotTextStyle:10]];
    }
	return newLayer;
}

//-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index{
//    CPTGradient *newInstance = [HDSUtil pieChartGradientAtIndex:index];
//    newInstance.angle = 270.0f;
//	return [CPTFill fillWithGradient:newInstance];
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
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_CargoIncomeCost" withExtension:@"json"]]];
    }else{
        // 表格数据
        NSString *url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SCargoIncomeCost/list.json?beginYM=%@&endYM=%@&corps=%@",qBeginDate,qEndDate,qCompany];
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
            node = [[HDSTreeNode alloc] initWithProperties:prop parent:nil expanded:YES];
            [self.rootArray addObject:node];
            [self loadChildren:node withData:data];
        }
        [tableView reloadData];
        // 查询完数据默认选中第一行
        [tableView doSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        
    }else if(parser == parser2){
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:array dataIsTreeNode:false  xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"unitCost",nil] yTitleWidth:0 plotNum:1];
        
    }else if(parser == parser3){
        [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot2 data:array dataIsTreeNode:false  xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"unitCost",nil] yTitleWidth:0 plotNum:1];
    } 
}

//-(void)newData:(NSTimer *)theTimer{
//    if(pointCount < dataForPlot1.count){
//        pointCount++;
//        [[plotView1.hostedGraph plotAtIndex:0] insertDataAtIndex:pointCount-1 numberOfRecords:1];
//        [[plotView2.hostedGraph plotAtIndex:0] insertDataAtIndex:pointCount-1 numberOfRecords:1];
//    }else{
//        [theTimer invalidate];
//    }
//}

- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //    NSLog(@"Connection didReceiveData of length: %u", data.length);
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"单货种收入成本");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"单货种收入成本");
	} else{
        //        NSLog(@"Parser over.");
    }
}

- (IBAction)changeMonthTaped:(UIButton *)sender {
    if(sender == beginDateBtn){
        [self createDatePopovers];
        [beginMonthPopover presentPopoverFromRect:beginDateBtn.frame inView:[beginDateBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }else if(sender == endDateBtn){
        [self createDatePopovers];
        [endMonthPopover presentPopoverFromRect:endDateBtn.frame inView:[endDateBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)createDatePopovers{
    if(beginMonthPopover == nil){
        HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearMonthPickerFormat popupBtn:beginDateBtn];
        picker.delegate = self;
        beginMonthPopover= [[UIPopoverController alloc] initWithContentViewController:picker];
        beginMonthPopover.popoverContentSize = picker.view.frame.size;
        beginMonthPopover.delegate = picker;
    }
    if(endMonthPopover == nil){
        HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearMonthPickerFormat popupBtn:endDateBtn];
        picker.delegate = self;
        endMonthPopover= [[UIPopoverController alloc] initWithContentViewController:picker];
        endMonthPopover.popoverContentSize = picker.view.frame.size;
        endMonthPopover.delegate = picker;
    }
}

@end
