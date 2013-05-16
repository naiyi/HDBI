//
//  HDS_C_YardIoContainer.m
//  HDBI
//
//  Created by 毅 张 on 12-9-5.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_C_YardIoContainer.h"
#import "UIView+AddLine.h"
#import "HDSGradientView.h"

#define FIRST_COL_WIDTH 60.0f
#define OTHER_COL_WIDTH 90.0f
#define COL_HEIGHT 20.0f
#define SMALL_FIRST_COL_WIDTH 50.0f
#define SMALL_OTHER_COL_WIDTH 65.0f
#define SMALL_COL_HEIGHT 15.0f

@implementation HDS_C_YardIoContainer{
    
    CPTGraphHostingView *plotView1;
    CPTGraphHostingView *plotView2;
    
    UIPopoverController *datePopover;
    
    NSURLConnection *conn1; // 表格数据
    SBJsonStreamParser *parser1;
    SBJsonStreamParserAdapter *adapter1;
    
    NSString *qDate;
}

@synthesize plotContainer1;
@synthesize plotContainer2;
@synthesize dateBtn;
@synthesize dataForPlot1;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification]; 
    
    HDSSkinType skinType = [HDSUtil skinType];
    [dateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal_110.png"] forState:UIControlStateNormal];
    [dateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight_110.png"] forState:UIControlStateHighlighted];
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    [dateBtn setTitleColor:color forState:UIControlStateNormal];
    
    [self refreshPlotTheme:plotView1];
}

- (void)fillConditionView:(UIView *)view{
    // 月度
    dateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    dateBtn.frame = CGRectMake(20,10,119,31);
    dateBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    dateBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [dateBtn addTarget:self action:@selector(changeDateTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:dateBtn];
    
    [super fillConditionView:view];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,plotContainer1,plotContainer2,nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"堆场进出箱统计";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addLinePlotView:plotView1 toContainer:plotContainer1 title:@"堆场进出箱统计" xTitle:nil yTitle:nil plotNum:2 identifier:[NSArray arrayWithObjects:@"本日进场",@"本日出场",nil] useLegend:YES useLegendIcon:NO];
    plotView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addLinePlotView:plotView2 toContainer:plotContainer2 title:@"结存统计" xTitle:nil yTitle:nil plotNum:3 identifier:[NSArray arrayWithObjects:@"内贸结存",@"外贸结存",@"合计",nil] useLegend:YES useLegendIcon:NO];
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot1 = [[NSMutableArray alloc] init];
    
    // 初始化默认月份
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    [self refreshByDates:dates fromPopupBtn:dateBtn];
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
    CPTLegend *theLegend = ((CPTGraphHostingView *)[legendSwitch superview]).hostedGraph.legend;
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
    [self setDateBtn:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource
- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 12;
}

- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
    return 1;
}
// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column==0)  return SMALL_FIRST_COL_WIDTH;
        return SMALL_OTHER_COL_WIDTH;
    }
    if(column==0)  return FIRST_COL_WIDTH;
    return OTHER_COL_WIDTH;
}

- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"date";
        case 1: return @"nLast";
        case 2: return @"nIn";
        case 3: return @"nOut";
        case 4: return @"nThis";
        case 5: return @"wLast";
        case 6: return @"wIn";
        case 7: return @"wOut";
        case 8: return @"wThis";
        case 9: return @"totalLast";
        case 10: return @"totalIn";
        case 11: return @"totalOut";
        case 12: return @"totalThis";
        default:return @"";
    }
}

- (CGFloat)heightForHeaderCellOfTableView:(HDSTableView *)tableView{
    if(isSmallView){
        return SMALL_COL_HEIGHT*2;
    }
    return COL_HEIGHT*2;
}

// 复合表头
- (UIView *)tableView:(HDSTableView *)_tableView multiRowHeaderInTableViewIndex:(NSInteger)tableViewIndex{
    float col0Width = isSmallView?SMALL_FIRST_COL_WIDTH:FIRST_COL_WIDTH; 
    float otherColWidth = isSmallView?SMALL_OTHER_COL_WIDTH:OTHER_COL_WIDTH;
    float colHeight = isSmallView?SMALL_COL_HEIGHT:COL_HEIGHT;
    HDSGradientView *header = [HDSUtil getTableViewMultiHeaderBackgroundView];

    if(tableViewIndex == 0){ // fixedTableView
        UILabel *cell=[[UILabel alloc] initWithFrame:CGRectMake(0, 0, col0Width+1, colHeight*2)];
        cell.text = @"日期";
        cell.textAlignment = UITextAlignmentCenter;
        cell.textColor = [UIColor whiteColor];
        cell.font = _tableView.titleFont;
        cell.backgroundColor = [UIColor clearColor];
        if([HDSUtil skinType] == HDSSkinBlue){
            [header addVerticalLineWithWidth:1 color:[UIColor blackColor] atX:col0Width+1];
            [cell addBottomLineWithWidth:1 color:[UIColor blackColor]]; 
        }else{
            [header addVerticalLineWithWidth:1 color:[HDSUtil plotBorderColor] atX:col0Width+1];
        }
        [header addSubview:cell];
        
    }else{  // rightTableView
        CGRect rects[15] = {  
            CGRectMake(1, 0, otherColWidth*4+4, colHeight),     //内贸
            CGRectMake(1+otherColWidth*4+4,0, otherColWidth*4+4, colHeight), //外贸
            CGRectMake(1+otherColWidth*8+8,0, otherColWidth*4+4, colHeight), //合计
            CGRectMake(1,                   colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth+1,   colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*2+2, colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*3+3, colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*4+4, colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*5+5, colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*6+6, colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*7+7, colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*8+8, colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*9+9, colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*10+10, colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*11+11, colHeight, otherColWidth+1, colHeight)
        };
        NSArray *titles = [NSArray arrayWithObjects:
                           @"内贸",@"外贸",@"合计",
                           @"上日结存",@"本日进场",@"本日出场",@"本日结存",
                           @"上日结存",@"本日进场",@"本日出场",@"本日结存",
                           @"上日结存",@"本日进场",@"本日出场",@"本日结存",
                           nil];
        UILabel *cell;
        for (int i=0; i<15; i++) {
            cell = [[UILabel alloc] initWithFrame:rects[i]];
            cell.text = [titles objectAtIndex:i];
            cell.textAlignment = UITextAlignmentCenter;
            cell.textColor = [UIColor whiteColor];
            cell.font = _tableView.titleFont;;
            cell.backgroundColor = [UIColor clearColor];
            if([HDSUtil skinType] == HDSSkinBlue){
                [cell addVerticalLineWithWidth:1 color:[UIColor blackColor] atX:rects[i].size.width-1];
                [cell addBottomLineWithWidth:1 color:[UIColor blackColor]];   
            }
            [header addSubview:cell];
        }
        if([HDSUtil skinType] == HDSSkinBlue){
            [header addVerticalLineWithWidth:1 color:[UIColor blackColor] atX:0];
        }
        
    }
    return header;
}

- (IBAction)changeDateTaped:(UIButton *)sender {
    if(sender == dateBtn){
        if(datePopover == nil){
            HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearMonthPickerFormat popupBtn:dateBtn];
            picker.delegate = self;
            datePopover= [[UIPopoverController alloc] initWithContentViewController:picker];
            datePopover.popoverContentSize = picker.view.frame.size;
            datePopover.delegate = picker;
        }
        [datePopover presentPopoverFromRect:dateBtn.frame inView:[dateBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    if(popupBtn == dateBtn){
        [dateBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year],[_dates month]] forState:UIControlStateNormal];
        qDate = [NSString stringWithFormat:@"%d%02d",[_dates year] ,[_dates month]];
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
    return pointCount;
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    if(fieldEnum == CPTScatterPlotFieldX ){
        return index+1;
    }
    NSDictionary *dict = [dataForPlot1 objectAtIndex:index];
    
    if ( [(NSString *)plot.identifier isEqualToString:@"本日进场"] ) {
        return [(NSNumber *)[dict objectForKey:@"in"] doubleValue];
    }else if( [(NSString *)plot.identifier isEqualToString:@"本日出场"] ){
        return [(NSNumber *)[dict objectForKey:@"out"] doubleValue];
    }else if( [(NSString *)plot.identifier isEqualToString:@"内贸结存"] ){
        return [(NSNumber *)[dict objectForKey:@"n"] doubleValue];
    }else if( [(NSString *)plot.identifier isEqualToString:@"外贸结存"] ){
        return [(NSNumber *)[dict objectForKey:@"w"] doubleValue];
    }else if( [(NSString *)plot.identifier isEqualToString:@"合计"] ){
        return [(NSNumber *)[dict objectForKey:@"total"] doubleValue];
    }
    return 0;
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView)
        return nil;
    
	CPTTextLayer *newLayer = nil;
    //    double num = [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
    //    if(num > 0.1){
    //        newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.0f", 
    //                [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index]] style:[HDSUtil plotTextStyle:10]];
    //    }
    
	return newLayer;
}

#pragma mark - 数据读取相关
- (void)loadData {
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
	
    // 表格数据
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_YardIoContainer" withExtension:@"json"]]];
    }else{
        NSString *url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CYardIoContainer/list.json?yearMonth=%@&corps=%@",qDate,qCompany];
        
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }
}

#pragma mark SBJsonStreamParserAdapterDelegate methods
- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
    NSDictionary *data;
    if(parser == parser1){
        HDSTreeNode *node;
        NSMutableDictionary *prop;
        [self.rootArray removeAllObjects];
        NSMutableArray *temp = [[NSMutableArray alloc] init];
        
        for(int i=0; i<array.count; i++){
            data = [array objectAtIndex:i];
            prop = [data objectForKey:@"properties"];
            node = [[HDSTreeNode alloc] initWithProperties:prop parent:nil expanded:YES];
            [self.rootArray addObject:node];
            // 填充图表数据
            NSDictionary *plot1Data = [NSDictionary dictionaryWithObjectsAndKeys:
                                       [prop objectForKey:@"totalIn"],@"in",
                                       [prop objectForKey:@"totalOut"],@"out",
                                       [prop objectForKey:@"totalThis"],@"total",
                                       [prop objectForKey:@"nThis"],@"n",
                                       [prop objectForKey:@"wThis"],@"w",
                                       [prop objectForKey:@"date"],@"date",
                                       nil ];
            [temp addObject:plot1Data];
        }
        [tableView reloadData];
        
        pointCount = 0;
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:temp dataIsTreeNode:false xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"in",@"out",nil] yTitleWidth:0 plotNum:2];
        [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot1 data:temp dataIsTreeNode:false xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"n",@"w",@"total",nil] yTitleWidth:0 plotNum:3];
        
        if([self respondsToSelector:@selector(newData:)]){
            if([dataTimer isValid]){
                [dataTimer invalidate];
            }
            dataTimer = [NSTimer timerWithTimeInterval:1.0 / fps target:self selector:@selector(newData:) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:dataTimer forMode:NSDefaultRunLoopMode];
        }
    }
}

//-(NSString *)transformXLabel:(NSString *)xLabel{
//    if(isSmallView){    // 去掉年度
//        return [xLabel substringWithRange:NSMakeRange(5, 5)];
//    }
//    return xLabel;
//}

-(NSInteger)xLabelInterval{
    return 4;
}

-(NSInteger)xAxisMaxCount:(NSInteger)plotNum plotView:(CPTGraphHostingView *)_plotView{
    return [dataForPlot1 count];
}

-(void)newData:(NSTimer *)theTimer{
    if(pointCount < dataForPlot1.count){
        pointCount++;
        [[plotView1.hostedGraph plotAtIndex:0] insertDataAtIndex:pointCount-1 numberOfRecords:1];
        [[plotView1.hostedGraph plotAtIndex:1] insertDataAtIndex:pointCount-1 numberOfRecords:1];
        [[plotView2.hostedGraph plotAtIndex:0] insertDataAtIndex:pointCount-1 numberOfRecords:1];
        [[plotView2.hostedGraph plotAtIndex:1] insertDataAtIndex:pointCount-1 numberOfRecords:1];
        [[plotView2.hostedGraph plotAtIndex:2] insertDataAtIndex:pointCount-1 numberOfRecords:1];
    }else{
        [theTimer invalidate];
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"堆场进出箱统计");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"堆场进出箱统计");
	} else{

    }
}


@end
