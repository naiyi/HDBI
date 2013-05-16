//
//  HDS_S_DayIoPortFlow.m
//  每日集疏运流量统计
//
//  Created by 毅 张 on 12-7-23.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_S_DayIoPortFlow.h"
#import "UIView+AddLine.h"
#import "HDSGradientView.h"

#define FIRST_COL_WIDTH 100.0f
#define SECOND_COL_WIDTH 130.0f
#define OTHER_COL_WIDTH 90.0f
#define COL_HEIGHT 20.0f
#define SMALL_FIRST_COL_WIDTH 75.0f
#define SMALL_SECOND_COL_WIDTH 90.0f
#define SMALL_OTHER_COL_WIDTH 70.0f
#define SMALL_COL_HEIGHT 15.0f

@implementation HDS_S_DayIoPortFlow{
    
    CPTGraphHostingView *plotView1;
    
    UIPopoverController *datePopover;
    
    NSURLConnection *conn1; // 表格数据
    NSURLConnection *conn2;
    SBJsonStreamParser *parser1;
    SBJsonStreamParser *parser2;
    SBJsonStreamParserAdapter *adapter1;
    SBJsonStreamParserAdapter *adapter2;

    NSString *qDate;
}

@synthesize plotContainer1;
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
        pageViews = [NSArray arrayWithObjects:tableContainer,plotContainer1, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"每日集疏运流量统计";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addLinePlotView:plotView1 toContainer:plotContainer1 title:@"每日集疏运变化曲线" xTitle:nil yTitle:nil plotNum:2 identifier:[NSArray arrayWithObjects:@"进港",@"出港",nil] useLegend:YES useLegendIcon:NO];
    
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
//    plotView1.frame = CGRectInset(plotContainer1.bounds,5.0f,5.0f);
    plotView1.frame = plotContainer1.bounds;
}

- (void)viewDidUnload{
    [self setPlotContainer1:nil];
    [self setDateBtn:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource
- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 8;
}

- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
    return 2;
}
// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column==0)  return SMALL_FIRST_COL_WIDTH;
        if(column==1)  return SMALL_SECOND_COL_WIDTH;
        return SMALL_OTHER_COL_WIDTH;
    }
    if(column==0)  return FIRST_COL_WIDTH;
    if(column==1)  return SECOND_COL_WIDTH;
    return OTHER_COL_WIDTH;
}


- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"date";
        case 1: return @"cargoKind";
        case 2: return @"inHighway";
        case 3: return @"inRailway";
        case 4: return @"inWaterway";
        case 5: return @"inTotal";
        case 6: return @"outHighway";
        case 7: return @"outRailway";
        case 8: return @"outWaterway";
        case 9: return @"outTotal";
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
    float firstColWidth = isSmallView?SMALL_FIRST_COL_WIDTH:FIRST_COL_WIDTH;
    float secondColWidth = isSmallView?SMALL_SECOND_COL_WIDTH:SECOND_COL_WIDTH; 
    float otherColWidth = isSmallView?SMALL_OTHER_COL_WIDTH:OTHER_COL_WIDTH;
    float colHeight = isSmallView?SMALL_COL_HEIGHT:COL_HEIGHT;
    HDSGradientView *header = [HDSUtil getTableViewMultiHeaderBackgroundView];
    //    header.backgroundColor = [UIColor blueColor];
    if(tableViewIndex == 0){ // fixedTableView
        UILabel *cell=[[UILabel alloc] initWithFrame:CGRectMake(0, 0, firstColWidth+1, colHeight*2)];
        cell.text = @"日期";
        cell.textAlignment = UITextAlignmentCenter;
        cell.textColor = [UIColor whiteColor];
        cell.font = _tableView.titleFont;
        cell.backgroundColor = [UIColor clearColor];
        if([HDSUtil skinType] == HDSSkinBlue){
            [header addVerticalLineWithWidth:1 color:[UIColor blackColor] atX:firstColWidth+1];
            [cell addBottomLineWithWidth:1 color:[UIColor blackColor]]; 
        }
        [header addSubview:cell];
        
        cell=[[UILabel alloc] initWithFrame:CGRectMake(firstColWidth+1, 0, secondColWidth+1, colHeight*2)];
        cell.text = @"货类";
        cell.textAlignment = UITextAlignmentCenter;
        cell.textColor = [UIColor whiteColor];
        cell.font = _tableView.titleFont;
        cell.backgroundColor = [UIColor clearColor];
        if([HDSUtil skinType] == HDSSkinBlue){
            [header addVerticalLineWithWidth:1 color:[UIColor blackColor] atX:firstColWidth+1+secondColWidth+1];
            [cell addBottomLineWithWidth:1 color:[UIColor blackColor]];   
        }else{
            [header addVerticalLineWithWidth:1 color:[HDSUtil plotBorderColor] atX:firstColWidth+1+secondColWidth+1];
        }
        [header addSubview:cell];
    }else{  // rightTableView
        CGRect rects[10] = {  
            CGRectMake(1, 0, otherColWidth*4+4, colHeight), 
            CGRectMake(1+otherColWidth*4+4,0, otherColWidth*4+4, colHeight), 
            CGRectMake(1,colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth+1,colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*2+2,colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*3+3,colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*4+4,colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*5+5,colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*6+6,colHeight, otherColWidth+1, colHeight),
            CGRectMake(1+otherColWidth*7+7,colHeight, otherColWidth+1, colHeight)
        };
        NSArray *titles = [NSArray arrayWithObjects:
                           @"进港",@"出港",@"公路",@"水路",
                           @"铁路",@"合计",@"公路",@"水路",
                           @"铁路",@"合计",nil];
        
        UILabel *cell;
        for (int i=0; i<10; i++) {
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
//    return [dataForPlot1 count];
    return pointCount;
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    if ( [(NSString *)plot.identifier isEqualToString:@"进港"] ) {
        if(fieldEnum == CPTScatterPlotFieldX ){
            return index+1;
        }else{  //CPTBarPlotFieldBarTip
            NSDictionary *dict = [dataForPlot1 objectAtIndex:index];
            return [(NSNumber *)[dict objectForKey:@"inTotal"] doubleValue];
        }
    }else if( [(NSString *)plot.identifier isEqualToString:@"出港"] ){
        if(fieldEnum == CPTScatterPlotFieldX ){
            return index+1;
        }else{  //CPTBarPlotFieldBarTip
            NSDictionary *dict = [dataForPlot1 objectAtIndex:index];
            return [(NSNumber *)[dict objectForKey:@"outTotal"] doubleValue];
        }
    }else{
        return 0;
    }
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
    adapter2 = [[SBJsonStreamParserAdapter alloc] init];
    adapter2.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
    parser2 = [[SBJsonStreamParser alloc] init];
    parser2.delegate = adapter2;
	
    // 表格数据
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_DayIoPortFlow_list" withExtension:@"json"]]];
        [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_DayIoPortFlow_chart" withExtension:@"json"]]];
    }else{
        NSString *url,*url2;
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SDayIoPortFlow/list.json?yearMonth=%@&corps=%@",qDate,qCompany];
        url2= [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SDayIoPortFlow/listChart.json?yearMonth=%@&corps=%@",qDate,qCompany];
        
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        NSURLRequest *theRequest2=[NSURLRequest requestWithURL:[NSURL URLWithString:url2] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest2 delegate:self];
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
    }else if(parser == parser2){
        pointCount = 0; 
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:array dataIsTreeNode:false xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"inTotal",@"outTotal",nil] yTitleWidth:0 plotNum:2];
        // 速度:默认每秒20帧
        if([self respondsToSelector:@selector(newData:)]){
            if([dataTimer isValid]){
                [dataTimer invalidate];
            }
            dataTimer = [NSTimer timerWithTimeInterval:1.0 / fps target:self selector:@selector(newData:) userInfo:nil repeats:YES];
            [[NSRunLoop mainRunLoop] addTimer:dataTimer forMode:NSDefaultRunLoopMode];
        }
    }
}

-(NSString *)transformXLabel:(NSString *)xLabel{
    if(isSmallView){    // 去掉年度
        return [xLabel substringWithRange:NSMakeRange(5, 5)];
    }
    return xLabel;
}

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
    }else if(connection == conn2){
        parser = parser2;
    }
    SBJsonStreamParserStatus status = [parser parse:data];
	if (status == SBJsonStreamParserError) {
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"每日集疏运流量统计");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"每日集疏运流量统计");
	} else{
        //        NSLog(@"Parser over.");
    }
}


@end
