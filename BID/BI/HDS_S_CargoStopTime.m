//
//  HDS_S_CargoStopTime.m
//  HDBI
//
//  Created by 毅 张 on 12-8-6.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_S_CargoStopTime.h"
#import "UIView+AddLine.h"
#import "HDSGradientView.h"

#define COL0_WIDTH 140.0f
#define COL1_WIDTH 85.0f
#define COL2_WIDTH 85.0f
#define COL3_WIDTH 78.0f
#define COL4_WIDTH 44.0f
#define OTHER_COL_WIDTH 44.0f
#define COL_HEIGHT 20.0f
#define SMALL_COL0_WIDTH 110.0f
#define SMALL_COL1_WIDTH 65.0f
#define SMALL_COL2_WIDTH 60.0f
#define SMALL_COL3_WIDTH 60.0f
#define SMALL_COL4_WIDTH 35.0f
#define SMALL_OTHER_COL_WIDTH 35.0f
#define SMALL_COL_HEIGHT 15.0f

@implementation HDS_S_CargoStopTime{
    
    CPTGraphHostingView *pieView1;
    CPTGraphHostingView *pieView2;
    
    NSURLConnection *conn1; // 表格数据
    SBJsonStreamParser *parser1;
    SBJsonStreamParserAdapter *adapter1;
    
    UIPopoverController *beginMonthPopover;
    UIPopoverController *endMonthPopover;
    
    NSString *qBeginDate;
    NSString *qEndDate;
}

@synthesize pieContainer1,pieContainer2;
@synthesize pieView;
@synthesize beginDateBtn,endDateBtn;
@synthesize dataForPlot1,dataForPlot2;

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
    
    [self refreshPlotTheme:pieView1];
    [self refreshPlotTheme:pieView2];
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

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(isSmallView){
        pageViews=[NSArray arrayWithObjects:tableContainer,pieView, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"单货种千吨货停时分析";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    
    pieView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addPiePlotView:pieView1 toContainer:pieContainer1 title:@"千吨货停时原因比例" useLegend:YES useLegendIcon:YES];
    pieView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addPiePlotView:pieView2 toContainer:pieContainer2 title:@"非生产停时原因比例" useLegend:YES useLegendIcon:YES];
    
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


-(void)viewDidLayoutSubviews{
    if(isSmallView)
        return;
    [tableView adjustRightTableViewWidth];
    [tableView positionVerticalScrollBar];
    pieView1.frame = pieContainer1.bounds;
    pieView2.frame = pieContainer2.bounds;
}

- (void)viewDidUnload{
    [self setPieContainer1:nil];
    [self setPieContainer2:nil];
    [self setPieView:nil];
    [self setBeginDateBtn:nil];
    [self setEndDateBtn:nil];
    [super viewDidUnload];
}



#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 10;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
//    return 1;
//}
// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column == 0) return SMALL_COL0_WIDTH;
        if(column == 1) return SMALL_COL1_WIDTH;
        if(column == 2) return SMALL_COL2_WIDTH;
        if(column == 3) return SMALL_COL3_WIDTH;
        if(column == 4) return SMALL_COL4_WIDTH;
        return SMALL_OTHER_COL_WIDTH;
    }
    if(column == 0) return COL0_WIDTH;
    if(column == 1) return COL1_WIDTH;
    if(column == 2) return COL2_WIDTH;
    if(column == 3) return COL3_WIDTH;
    if(column == 4) return COL4_WIDTH;
    return OTHER_COL_WIDTH;
}

// @"货类名称",@"装卸吨",@"停泊艘时",@"生产停时",@"装卸",@"其他",@"非生产停时",@"港方",@"航方",@"货方",@"其他",@"自然因素"
- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"CARGO_KIND_NAM";
        case 1: return @"wgt";
        case 2: return @"time";
        case 3: return @"workUnloadTim";
        case 4: return @"workOtherTim";
        case 5: return @"noworkPortTim";
        case 6: return @"noworkShipTim";
        case 7: return @"noworkCargoTim";
        case 8: return @"noworkOtherTim";
        case 9: return @"weatherTim";
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
    float col0Width = (isSmallView?SMALL_COL0_WIDTH:COL0_WIDTH)+1; 
    float col1Width = (isSmallView?SMALL_COL1_WIDTH:COL1_WIDTH)+1;
    float col2Width = (isSmallView?SMALL_COL2_WIDTH:COL2_WIDTH)+1; 
    float col3Width = (isSmallView?SMALL_COL3_WIDTH:COL3_WIDTH)+1;
    float col4Width = (isSmallView?SMALL_COL4_WIDTH:COL4_WIDTH)+1;
    float otherColWidth = (isSmallView?SMALL_OTHER_COL_WIDTH:OTHER_COL_WIDTH)+1;
    float colHeight = isSmallView?SMALL_COL_HEIGHT:COL_HEIGHT;
    HDSGradientView *header = [HDSUtil getTableViewMultiHeaderBackgroundView];
    
    CGRect rects[12] = {  
        CGRectMake(1, 0, col0Width, colHeight*2),// 货类名称
        CGRectMake(1+col0Width,0, col1Width, colHeight*2),//载重吨
        CGRectMake(1+col0Width+col1Width,0, col2Width, colHeight*2),//停泊艘时
        CGRectMake(1+col0Width+col1Width+col2Width,0, col3Width+col4Width, colHeight),//生产性停时
        CGRectMake(1+col0Width+col1Width+col2Width,colHeight, col3Width, colHeight),//装卸
        CGRectMake(1+col0Width+col1Width+col2Width+col3Width,colHeight, col4Width, colHeight),//其他
        CGRectMake(1+col0Width+col1Width+col2Width+col3Width+col4Width,0, otherColWidth*4, colHeight),//非生产性停时
        CGRectMake(1+col0Width+col1Width+col2Width+col3Width+col4Width,colHeight, otherColWidth, colHeight),//港方
        CGRectMake(1+col0Width+col1Width+col2Width+col3Width+col4Width+otherColWidth*1,colHeight, otherColWidth, colHeight),//航方
        CGRectMake(1+col0Width+col1Width+col2Width+col3Width+col4Width+otherColWidth*2,colHeight, otherColWidth, colHeight),//货方
        CGRectMake(1+col0Width+col1Width+col2Width+col3Width+col4Width+otherColWidth*3,colHeight, otherColWidth, colHeight),//其他
        CGRectMake(1+col0Width+col1Width+col2Width+col3Width+col4Width+otherColWidth*4,0, otherColWidth, colHeight*2)//自然因素
    };
    NSArray *titles = [NSArray arrayWithObjects:
                       @"货类名称",@"装卸吨",@"停泊艘时",@"生产停时",@"装卸",
                       @"其他",@"非生产停时",@"港方",@"航方",@"货方",@"其他",@"自然因素",nil];
    
    UILabel *cell;
    for (int i=0; i<12; i++) {
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
        }  
        [header addSubview:cell];
    }
    if([HDSUtil skinType] == HDSSkinBlue){
        [header addVerticalLineWithWidth:1 color:[UIColor blackColor] atX:0];
    }
    return header;
}

-(void)tableView:(HDSTableView *)tableView didSelectRowAtNode:(HDSTreeNode *)node{
    NSDictionary *prop = node.properties;
    [dataForPlot1 removeAllObjects];
    float p1Time1 = [(NSNumber *)[prop objectForKey:@"workUnloadTim"] floatValue]
    +[(NSNumber *)[prop objectForKey:@"workOtherTim"] floatValue];
    float p1Time2 = [(NSNumber *)[prop objectForKey:@"noworkPortTim"] floatValue]
    +[(NSNumber *)[prop objectForKey:@"noworkShipTim"] floatValue]
    +[(NSNumber *)[prop objectForKey:@"noworkCargoTim"] floatValue]
    +[(NSNumber *)[prop objectForKey:@"noworkOtherTim"] floatValue];
    float p1Time3 = [(NSNumber *)[prop objectForKey:@"weatherTim"] floatValue];
    [dataForPlot1 addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:p1Time1],@"time",@"生产停时",@"name",nil]];
    [dataForPlot1 addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:p1Time2],@"time",@"非生产停时",@"name",nil]];
    [dataForPlot1 addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:p1Time3],@"time",@"自然因素",@"name",nil]];
    [pieView1.hostedGraph reloadData]; 
    CABasicAnimation *rotation1 = [HDSUtil setAnimation:@"transform.rotation" toLayer:[pieView1.hostedGraph plotAtIndex:0] fromValue:M_PI * 3 toValue:0 forKey:@"pieRotation1"];
    rotation1.delegate = self;
    
    [dataForPlot2 removeAllObjects];
    float p2Time1 = [(NSNumber *)[prop objectForKey:@"noworkPortTim"] floatValue];
    float p2Time2 = [(NSNumber *)[prop objectForKey:@"noworkShipTim"] floatValue];
    float p2Time3 = [(NSNumber *)[prop objectForKey:@"noworkCargoTim"] floatValue];
    float p2Time4 = [(NSNumber *)[prop objectForKey:@"noworkOtherTim"] floatValue];
    
    [dataForPlot2 addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:p2Time1],@"time",@"港方原因",@"name",nil]];
    [dataForPlot2 addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:p2Time2],@"time",@"船方原因",@"name",nil]];
    [dataForPlot2 addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:p2Time3],@"time",@"货方原因",@"name",nil]];
    [dataForPlot2 addObject:[NSDictionary dictionaryWithObjectsAndKeys:[NSNumber numberWithFloat:p2Time4],@"time",@"其他原因",@"name",nil]];
    [pieView2.hostedGraph reloadData];
    CABasicAnimation *rotation2 = [HDSUtil setAnimation:@"transform.rotation" toLayer:[pieView2.hostedGraph plotAtIndex:0] fromValue:M_PI * 3 toValue:0 forKey:@"pieRotation2"];    
    rotation2.delegate = self;
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
        if(plot == [pieView1.hostedGraph plotAtIndex:0]){   
            return [(NSNumber *)[[dataForPlot1 objectAtIndex:index] objectForKey:@"time"] doubleValue];
        }else if(plot == [pieView2.hostedGraph plotAtIndex:0]){ 
            return [(NSNumber *)[[dataForPlot2 objectAtIndex:index] objectForKey:@"time"] doubleValue];
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
    
	CPTTextStyle *whiteText = [HDSUtil plotTextStyle:10];
    
	CPTTextLayer *newLayer = nil;
    if ( [plot isKindOfClass:[CPTPieChart class]] ) {
        if(plot == [pieView1.hostedGraph plotAtIndex:0]){
            if([(NSNumber *)[[dataForPlot1 objectAtIndex:index] objectForKey:@"time"] floatValue]>0)
                newLayer = [[CPTTextLayer alloc] initWithText:[[dataForPlot1 objectAtIndex:index] objectForKey:@"name"] style:whiteText];
        }else if(plot == [pieView2.hostedGraph plotAtIndex:0]){
            if([(NSNumber *)[[dataForPlot2 objectAtIndex:index] objectForKey:@"time"] floatValue]>0)
                newLayer = [[CPTTextLayer alloc] initWithText:[[dataForPlot2 objectAtIndex:index] objectForKey:@"name"] style:whiteText];
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
    if(pieChart == [pieView1.hostedGraph plotAtIndex:0]){
        return [[dataForPlot1 objectAtIndex:index] objectForKey:@"name"];
    }else if(pieChart == [pieView2.hostedGraph plotAtIndex:0]){
        return [[dataForPlot2 objectAtIndex:index] objectForKey:@"name"];
    }
    return @"";
}

#pragma mark - 数据读取相关
- (void)loadData {
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
    
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_CargoStopTime" withExtension:@"json"]]];
    }else{
        NSString *url;
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SCargoTonStopTime/list.json?beginYM=%@&endYM=%@&corps=%@",qBeginDate, qEndDate, qCompany];
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
        // 查询完数据默认选中第一行
        [tableView doSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"单货种千吨货停时分析");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"单货种千吨货停时分析");
	} else{
        //        NSLog(@"Parser over.");
    }
}
@end
