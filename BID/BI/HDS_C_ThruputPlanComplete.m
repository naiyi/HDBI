//
//  HDS_C_ThruputPlanComplete.m
//  HDBI
//
//  Created by 毅 张 on 12-8-15.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_C_ThruputPlanComplete.h"
#import "UIView+AddLine.h"
#import "HDSGradientView.h"

#define COL0_WIDTH 110.0f
#define OTHER_COL_WIDTH 100.0f
#define COL_HEIGHT 20.0f
#define SMALL_COL0_WIDTH 100.0f
#define SMALL_OTHER_COL_WIDTH 80.0f
#define SMALL_COL_HEIGHT 15.0f

@implementation HDS_C_ThruputPlanComplete{
    
    CPTGraphHostingView *plotView1;
    CPTGraphHostingView *plotView2;
    CPTGraphHostingView *pieView1;
    CPTGraphHostingView *pieView2;
    
    UIPopoverController *yearPopover;
    UIPopoverController *beginMonthPopover;
    CPTLegend *theLegend;
    UIButton *legendSwitch;
    
    NSURLConnection *conn0; // 统计数据
    NSURLConnection *conn1; // 表格数据
    NSURLConnection *conn2; // 环比图表
    NSURLConnection *conn3; // 同比图表
    NSURLConnection *conn4; // 年度图表
    SBJsonStreamParser *parser0;
    SBJsonStreamParser *parser1; 
    SBJsonStreamParser *parser2;
    SBJsonStreamParser *parser3;
    SBJsonStreamParser *parser4;
    SBJsonStreamParserAdapter *adapter0;
    SBJsonStreamParserAdapter *adapter1;
    SBJsonStreamParserAdapter *adapter2;
    SBJsonStreamParserAdapter *adapter3;
    SBJsonStreamParserAdapter *adapter4;
    
    NSString *qYear;
    NSString *qBeginDate;
    
}
@synthesize line1Title;
@synthesize line2Title;
@synthesize plan1;
@synthesize work1;
@synthesize rate1;
@synthesize iNum1;
@synthesize eNum1;
@synthesize plan2;
@synthesize work2;
@synthesize rate2;
@synthesize iNum2;
@synthesize eNum2;

@synthesize barContainer1,barContainer2,pieContainer1,pieContainer2;
@synthesize dataForPlot1,dataForPlot2;
@synthesize dataForPie;
@synthesize beginDateBtn;
@synthesize yearMonthSegment;
@synthesize yearBtn;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification];
    HDSSkinType skinType = [HDSUtil skinType];
    
    [HDSUtil changeSegment:yearMonthSegment textAttributeBySkin:skinType];
    [beginDateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal_110.png"] forState:UIControlStateNormal];
    [beginDateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight_110.png"] forState:UIControlStateHighlighted];
    [yearBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal.png"] forState:UIControlStateNormal];
    [yearBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight.png"] forState:UIControlStateHighlighted];
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    [beginDateBtn setTitleColor:color forState:UIControlStateNormal];
    [yearBtn setTitleColor:color forState:UIControlStateNormal];
    
    [self refreshPlotTheme:plotView1];
    [self refreshPlotTheme:plotView2];
    [self refreshPlotTheme:pieView1];
    [self refreshPlotTheme:pieView2];
}

- (void)fillConditionView:(UIView *)view{
    // segment月度/年度
    yearMonthSegment = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"月度",@"年度", nil]];
    yearMonthSegment.segmentedControlStyle = UISegmentedControlStylePlain;
    yearMonthSegment.frame = CGRectMake(20, 10, 103, 31);
    yearMonthSegment.selectedSegmentIndex = 0;
    [yearMonthSegment addTarget:self action:@selector(changeSegmentTaped:) forControlEvents:UIControlEventValueChanged];
    [view addSubview:yearMonthSegment];
    // 年度
    yearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    yearBtn.frame = CGRectMake(131,10,100,31);
    yearBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    yearBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    yearBtn.hidden = true;  //默认显示月度
    [yearBtn addTarget:self action:@selector(changeMonthTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:yearBtn];
    // 月度
    beginDateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    beginDateBtn.frame = CGRectMake(131,10,119,31);
    beginDateBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    beginDateBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [beginDateBtn addTarget:self action:@selector(changeMonthTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:beginDateBtn];
    [super fillConditionView:view];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,barContainer1,barContainer2,pieContainer1,pieContainer2, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"吞吐量计划完成情况";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    [HDSUtil changeUIControlFont:yearMonthSegment toSize:isSmallView?HDSFontSizeNormal:HDSFontSizeBig];
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    tableView.dataMaxDepth = 3;
    tableView.treeInOneCell = YES;
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView1 toContainer:barContainer1 title:@"月度吞吐量环比" xTitle:nil yTitle:nil plotNum:2 identifier:[NSArray arrayWithObjects:@"计划",@"实际",nil] useLegend:YES useLegendIcon:NO];
    plotView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView2 toContainer:barContainer2 title:@"月度吞吐量同比" xTitle:nil yTitle:nil plotNum:2 identifier:[NSArray arrayWithObjects:@"计划",@"实际",nil] useLegend:YES useLegendIcon:NO];
    pieView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addPiePlotView:pieView1 toContainer:pieContainer1 title:@"进出口比例" useLegend:YES useLegendIcon:NO];
    pieView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addPiePlotView:pieView2 toContainer:pieContainer2 title:@"内外贸比例" useLegend:YES useLegendIcon:NO];
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot1 = [[NSMutableArray alloc] init];
    self.dataForPlot2 = [[NSMutableArray alloc] init];
    
    // 初始化默认月份
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:[NSDate date]];
    [self refreshByDates:dates fromPopupBtn:yearBtn];
    [self refreshByDates:dates fromPopupBtn:beginDateBtn];
    // 初始化默认公司
    [self refreshByComps:[HDSCompanyViewController companys]];
//    [self loadData];
    [self changeSegmentTaped:yearMonthSegment];
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
    pieView1.frame = pieContainer1.bounds;
    pieView2.frame = pieContainer2.bounds;
}

- (void)viewDidUnload{
    [self setBarContainer1:nil];
    [self setBeginDateBtn:nil];
    [self setYearMonthSegment:nil];
    [self setYearBtn:nil];
    [self setBarContainer2:nil];
    [self setPieContainer1:nil];
    [self setPieContainer2:nil];
    [self setLine1Title:nil];
    [self setLine2Title:nil];
    [self setPlan1:nil];
    [self setWork1:nil];
    [self setRate1:nil];
    [self setINum1:nil];
    [self setENum1:nil];
    [self setPlan2:nil];
    [self setWork2:nil];
    [self setRate2:nil];
    [self setINum2:nil];
    [self setENum2:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 23;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
//    return 1;
//}
// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
//        if(column==0)   return SMALL_COL0_WIDTH;
        return SMALL_OTHER_COL_WIDTH;
    }
//    if(column == 0)     return COL0_WIDTH;
    return OTHER_COL_WIDTH;
}

- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"trade";
        case 1: return @"cntrNum";
        case 2: return @"teuNum";
        case 3: return @"ie20";
        case 4: return @"ie40";
        case 5: return @"ie45";
        case 6: return @"ieother";
        case 7: return @"if20";
        case 8: return @"if40";
        case 9: return @"if45";
        case 10: return @"ifother";
        case 11: return @"iCntrNum";
        case 12: return @"iTeuNum";
        case 13: return @"ee20";
        case 14: return @"ee40";
        case 15: return @"ee45";
        case 16: return @"eeother";
        case 17: return @"ef20";
        case 18: return @"ef40";
        case 19: return @"ef45";
        case 20: return @"efother";
        case 21: return @"eCntrNum";
        case 22: return @"eTeuNum";
        default:return @"";
    }
}

- (CGFloat)heightForHeaderCellOfTableView:(HDSTableView *)tableView{
    if(isSmallView){
        return SMALL_COL_HEIGHT*3;
    }
    return COL_HEIGHT*3;
}

// 复合表头
- (UIView *)tableView:(HDSTableView *)_tableView multiRowHeaderInTableViewIndex:(NSInteger)tableViewIndex{
    float col0Width = (isSmallView?SMALL_COL0_WIDTH:COL0_WIDTH)+1; 
    float otherColWidth = (isSmallView?SMALL_OTHER_COL_WIDTH:OTHER_COL_WIDTH)+1;
    float colHeight = isSmallView?SMALL_COL_HEIGHT:COL_HEIGHT;
    HDSGradientView *header = [HDSUtil getTableViewMultiHeaderBackgroundView];
    
    CGRect rects[30] = {  
        CGRectMake(1, 0, otherColWidth, colHeight*3),//合计重量
        
        CGRectMake(1+otherColWidth, 0, otherColWidth*2, colHeight),//合计箱量
        CGRectMake(1+otherColWidth, colHeight, otherColWidth, colHeight*2),//自然箱
        CGRectMake(1+otherColWidth*2, colHeight, otherColWidth, colHeight*2),//标准箱
        
        CGRectMake(1+otherColWidth*3, 0, otherColWidth*10, colHeight),//进口
        CGRectMake(1+otherColWidth*3, colHeight, otherColWidth*4, colHeight),//空箱
        CGRectMake(1+otherColWidth*7,colHeight, otherColWidth*4, colHeight),//重箱
        CGRectMake(1+otherColWidth*11,colHeight, otherColWidth, colHeight*2),//合计重量
        CGRectMake(1+otherColWidth*12,colHeight, otherColWidth, colHeight*2),//合计TEU
        CGRectMake(1+otherColWidth*3, colHeight*2, otherColWidth, colHeight),//20
        CGRectMake(1+otherColWidth*4, colHeight*2, otherColWidth, colHeight),//40
        CGRectMake(1+otherColWidth*5, colHeight*2, otherColWidth, colHeight),//45
        CGRectMake(1+otherColWidth*6, colHeight*2, otherColWidth, colHeight),//其他
        CGRectMake(1+otherColWidth*7, colHeight*2, otherColWidth, colHeight),//20
        CGRectMake(1+otherColWidth*8, colHeight*2, otherColWidth, colHeight),//40
        CGRectMake(1+otherColWidth*9, colHeight*2, otherColWidth, colHeight),//45
        CGRectMake(1+otherColWidth*10, colHeight*2, otherColWidth, colHeight),//其他
        
        CGRectMake(1+otherColWidth*13, 0, otherColWidth*10, colHeight),//出口
        CGRectMake(1+otherColWidth*13, colHeight, otherColWidth*4, colHeight),//空箱
        CGRectMake(1+otherColWidth*17,colHeight, otherColWidth*4, colHeight),//重箱
        CGRectMake(1+otherColWidth*21,colHeight, otherColWidth, colHeight*2),//合计重量
        CGRectMake(1+otherColWidth*22,colHeight, otherColWidth, colHeight*2),//合计TEU
        CGRectMake(1+otherColWidth*13, colHeight*2, otherColWidth, colHeight),//20
        CGRectMake(1+otherColWidth*14, colHeight*2, otherColWidth, colHeight),//40
        CGRectMake(1+otherColWidth*15, colHeight*2, otherColWidth, colHeight),//45
        CGRectMake(1+otherColWidth*16, colHeight*2, otherColWidth, colHeight),//其他
        CGRectMake(1+otherColWidth*17, colHeight*2, otherColWidth, colHeight),//20
        CGRectMake(1+otherColWidth*18, colHeight*2, otherColWidth, colHeight),//40
        CGRectMake(1+otherColWidth*19, colHeight*2, otherColWidth, colHeight),//45
        CGRectMake(1+otherColWidth*20, colHeight*2, otherColWidth, colHeight),//其他
    };
    NSArray *titles = [NSArray arrayWithObjects:
                       @"内外贸",@"合计箱量",@"自然箱",@"标准箱",@"进口",@"空箱",@"重箱",@"合计\n箱量",@"合计\nTEU",@"20",
                       @"40",@"45",@"其他",@"20",@"40",@"45",@"其他",@"出口",@"空箱",@"重箱",@"合计\n箱量",@"合计\nTEU",@"20",
                       @"40",@"45",@"其他",@"20",@"40",@"45",@"其他",nil];
    UILabel *cell;
    
    for (int i=0; i<30; i++) {
        cell = [[UILabel alloc] initWithFrame:rects[i]];
        cell.numberOfLines = 2;
        cell.lineBreakMode = UILineBreakModeWordWrap;
        cell.text = [titles objectAtIndex:i];
        cell.textAlignment = UITextAlignmentCenter;
        cell.textColor = [UIColor whiteColor];
        cell.font = _tableView.titleFont;;
        cell.backgroundColor = [UIColor clearColor];
//        if([HDSUtil skinType] == HDSSkinBlue){
        [cell addVerticalLineWithWidth:1 color:[UIColor blackColor] atX:rects[i].size.width-1];
        [cell addBottomLineWithWidth:1 color:[UIColor blackColor]];   
//        }
        [header addSubview:cell];
    }
    if([HDSUtil skinType] == HDSSkinBlue){
        [header addVerticalLineWithWidth:1 color:[UIColor blackColor] atX:0];
    }else{
        if (tableViewIndex == 0) {// 固定列与可拖动区域在黑色主题下增加分割线
            [header addVerticalLineWithWidth:1 color:[HDSUtil plotBorderColor] atX:col0Width];
        }
    }
    return header;
}



//- (NSInteger)tableView:(HDSTableView *)tableView canBeExpandedColumnIndexAtNode:(HDSTreeNode *)node{
//    if(isSmallView)
//        return 0;
//    return [node depth];
//}

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


- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    if(popupBtn == nil){    // smallView 时初始化没有按钮
        qBeginDate = [NSString stringWithFormat:@"%d%02d",[_dates year],[_dates month]];
        return;
    }
    
    if(popupBtn == yearBtn){
        [yearBtn setTitle:[NSString stringWithFormat:@"     %d年",[_dates year]] forState:UIControlStateNormal];
        qYear = [NSString stringWithFormat:@"%d",[_dates year]];
    }else if(popupBtn == beginDateBtn){
        [beginDateBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year],[_dates month]] forState:UIControlStateNormal];
        qBeginDate = [NSString stringWithFormat:@"%d%02d",[_dates year],[_dates month]];
    }
}

#pragma mark -
#pragma mark Plot Data Source Methods

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
    if ( plot == [plotView1.hostedGraph plotAtIndex:0] || plot == [plotView1.hostedGraph plotAtIndex:1]) {
		return [dataForPlot1 count];
	}else if ( plot == [plotView2.hostedGraph plotAtIndex:0] || plot == [plotView2.hostedGraph plotAtIndex:1]) {
		return [dataForPlot2 count];
	}else if ( plot == [pieView1.hostedGraph plotAtIndex:0] || plot == [pieView2.hostedGraph plotAtIndex:0]) {
        if(dataForPie != nil){
            return 2;
        }else {
            return 0;
        }
	}else {
		return 0;
	}
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    if ( [plot isKindOfClass:[CPTPieChart class]] ) {
		if ( fieldEnum == CPTPieChartFieldSliceWidth ) {
			if(plot == [pieView1.hostedGraph plotAtIndex:0]){   // 进出口
                if(index == 0){
                    return [(NSNumber *)[dataForPie objectForKey:@"import"] doubleValue];
                }else{
                    return [(NSNumber *)[dataForPie objectForKey:@"export"] doubleValue];
                }
            }else if(plot == [pieView2.hostedGraph plotAtIndex:0]){ //内外贸
                if(index == 0){
                    return [(NSNumber *)[dataForPie objectForKey:@"nTrade"] doubleValue];
                }else{
                    return [(NSNumber *)[dataForPie objectForKey:@"wTrade"] doubleValue];
                }
            }
		}else {
			return index;
		}
	}else if ( [plot isKindOfClass:[CPTBarPlot class]]){
        if ( [(NSString *)plot.identifier isEqualToString:@"计划"] ) {
            if(fieldEnum == CPTBarPlotFieldBarLocation ){
                return index+1;
            }else{  //CPTBarPlotFieldBarTip
                NSDictionary *dict;
                if(plot == [plotView1.hostedGraph plotAtIndex:0]){      //柱状图1
                    dict = [dataForPlot1 objectAtIndex:index];
                }else if(plot == [plotView2.hostedGraph plotAtIndex:0]){    //柱状图2
                    dict = [dataForPlot2 objectAtIndex:index];
                }
                return [(NSNumber *)[dict objectForKey:@"plan"] doubleValue];
            }
        }else if( [(NSString *)plot.identifier isEqualToString:@"实际"] ){
            if(fieldEnum == CPTBarPlotFieldBarLocation ){
                return index+1;
            }else{  //CPTBarPlotFieldBarTip
                NSDictionary *dict;
                if(plot == [plotView1.hostedGraph plotAtIndex:1]){      //线图1
                    dict = [dataForPlot1 objectAtIndex:index];
                }else if(plot == [plotView2.hostedGraph plotAtIndex:1]){    //线图2
                    dict = [dataForPlot2 objectAtIndex:index];
                }
                return [(NSNumber *)[dict objectForKey:@"work"] doubleValue];
            }
        }
    }
    return 0;
    
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView && ![plot isKindOfClass:[CPTPieChart class]] )
        return nil;
    
	CPTTextStyle *whiteText = [HDSUtil plotTextStyle:10];
    
	CPTTextLayer *newLayer = nil;
    if ( [plot isKindOfClass:[CPTPieChart class]] ) {
        if(plot == [pieView1.hostedGraph plotAtIndex:0]){
            if (index == 0) {
                newLayer = [[CPTTextLayer alloc] initWithText:@"进口" style:whiteText];
//                newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%@:%.0f", @"进口",[self doubleForPlot:plot field:CPTPieChartFieldSliceWidth recordIndex:index]] style:whiteText];
            }else{
                newLayer = [[CPTTextLayer alloc] initWithText:@"出口" style:whiteText];
//                newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%@:%.0f", @"出口",[self doubleForPlot:plot field:CPTPieChartFieldSliceWidth recordIndex:index]] style:whiteText];
            }
            
        }else if(plot == [pieView2.hostedGraph plotAtIndex:0]){
            if (index == 0) {
                newLayer = [[CPTTextLayer alloc] initWithText:@"内贸" style:whiteText];
//                newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%@:%.0f", @"内贸",[self doubleForPlot:plot field:CPTPieChartFieldSliceWidth recordIndex:index]] style:whiteText];
            }else{
                newLayer = [[CPTTextLayer alloc] initWithText:@"外贸" style:whiteText];
//                newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%@:%.0f", @"外贸",[self doubleForPlot:plot field:CPTPieChartFieldSliceWidth recordIndex:index]] style:whiteText];
            }
        }
		
	}else{
        double num = [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
        if(num > 0){
            newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.0f", 
                                                          num ] style:whiteText];
        }
        
    }
    
	return newLayer;
}

-(CPTFill *)sliceFillForPieChart:(CPTPieChart *)pieChart recordIndex:(NSUInteger)index{
    CPTGradient *newInstance = [HDSUtil pieChartGradientAtIndex:index];
    newInstance.angle = 270.0f;
	return [CPTFill fillWithGradient:newInstance];
}

//-(NSString *)legendTitleForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index{
//    HDSTreeNode *node = [dataForPlot objectAtIndex:index];
//	return [node.properties objectForKey:[NSString stringWithFormat:@"name%i",node.depth+1]];
//}

#pragma mark - 数据读取相关
- (void)loadData {
    adapter0 = [[SBJsonStreamParserAdapter alloc] init];
    adapter0.delegate = self;
    parser0 = [[SBJsonStreamParser alloc] init];
    parser0.delegate = adapter0;
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
    
    NSURLRequest *theRequest;
    if([HDSUtil isOffline]){    // 离线数据
        [parser0 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ThruputPlanCompleteGrid" withExtension:@"json"]]];
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ThruputPlanCompleteGrid2" withExtension:@"json"]]];
    }else{
        // 表格数据
        NSString *url0,*url1;
        if(yearMonthSegment.selectedSegmentIndex == 0){
            url0 = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CThruputComplete/getLTMonth.json?yearMonth=%@&corps=%@",qBeginDate,qCompany];
            url1 = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CThruputComplete/listMonth.json?yearMonth=%@&corps=%@",qBeginDate,qCompany];
        }else{
            url0 = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CThruputComplete/getLTYear.json?year=%@&corps=%@",qYear,qCompany];
            url1 = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CThruputComplete/listYear.json?year=%@&corps=%@",qYear,qCompany];
        }
        theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url0] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn0 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url1] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }
    
    NSString *urlHB,*urlTB;
    if(yearMonthSegment.selectedSegmentIndex == 0){
        adapter2 = [[SBJsonStreamParserAdapter alloc] init];
        adapter2.delegate = self;
        adapter3 = [[SBJsonStreamParserAdapter alloc] init];
        adapter3.delegate = self;
        parser2 = [[SBJsonStreamParser alloc] init];
        parser2.delegate = adapter2;
        parser3 = [[SBJsonStreamParser alloc] init];
        parser3.delegate = adapter3;
        
        if([HDSUtil isOffline]){    // 离线数据
            [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ThruputPlanCompleteChart1" withExtension:@"json"]]];
            [parser3 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ThruputPlanCompleteChart2" withExtension:@"json"]]];
        }else{
            urlHB = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CThruputComplete/listMonthhbChart.json?beginYM=%@&endYM=%@&corps=%@",qBeginDate,qBeginDate,qCompany];
            urlTB = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CThruputComplete/listMonthtbChart.json?beginYM=%@&endYM=%@&corps=%@",qBeginDate,qBeginDate,qCompany];
            theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:urlHB] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
            conn2 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
            theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:urlTB] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
            conn3 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        }
        plotView1.hostedGraph.title = [NSString stringWithFormat:@"集装箱月度吞吐量环比(万TEU)"];
        plotView2.hostedGraph.title = [NSString stringWithFormat:@"集装箱月度吞吐量同比(万TEU)"];
        
    }else{
        adapter4 = [[SBJsonStreamParserAdapter alloc] init];
        adapter4.delegate = self;
        parser4 = [[SBJsonStreamParser alloc] init];
        parser4.delegate = adapter4;
        
        if([HDSUtil isOffline]){    // 离线数据
            [parser4 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ThruputPlanCompleteChart3" withExtension:@"json"]]];
        }else{
            urlHB = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CThruputComplete/listYeartbChart.json?year=%@&corps=%@",qYear,qCompany];
            theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:urlHB] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
            conn4 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        }
        
        plotView1.hostedGraph.title = [NSString stringWithFormat:@"集装箱年度吞吐量"];
    }

}

#pragma mark SBJsonStreamParserAdapterDelegate methods
- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
    NSDictionary *data;
    if(parser == parser0){
        assert(array.count == 2);
        NSDictionary *line1 = [array objectAtIndex:0];
        NSDictionary *line2 = [array objectAtIndex:1];
        if(yearMonthSegment.selectedSegmentIndex == 0){ //月度
            line1Title.text = @"上月吞吐量：";
            line2Title.text = @"本月吞吐量：";
        }else{
            line1Title.text = @"去年吞吐量：";
            line2Title.text = @"今年吞吐量：";
        }
        plan1.text=[HDSUtil convertDataToString:[line1 objectForKey:@"plan"]];
        plan2.text=[HDSUtil convertDataToString:[line2 objectForKey:@"plan"]];
        work1.text=[HDSUtil convertDataToString:[line1 objectForKey:@"work"]];
        work2.text=[HDSUtil convertDataToString:[line2 objectForKey:@"work"]];
        rate1.text=[HDSUtil convertDataToString:[line1 objectForKey:@"rate"]];
        rate2.text=[HDSUtil convertDataToString:[line2 objectForKey:@"rate"]];
        iNum1.text=[HDSUtil convertDataToString:[line1 objectForKey:@"iNum"]];
        iNum2.text=[HDSUtil convertDataToString:[line2 objectForKey:@"iNum"]];
        eNum1.text=[HDSUtil convertDataToString:[line1 objectForKey:@"eNum"]];
        eNum2.text=[HDSUtil convertDataToString:[line2 objectForKey:@"eNum"]];
        
    }else if(parser == parser1){
        HDSTreeNode *node;
        [self.rootArray removeAllObjects];
        for(int i=0; i<array.count; i++){
            data = [array objectAtIndex:i];
            node = [[HDSTreeNode alloc] initWithProperties:[data objectForKey:@"properties"] parent:nil expanded:YES];
            [self.rootArray addObject:node];
            [self loadChildren:node withData:data];
        }
        [tableView reloadData];
        if(!isSmallView){
            [self changeChartPosition];
        }
        // 查询完数据默认选中第一行
//        [tableView doSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        // 表格加载完成即可更新饼图数据
        if(yearMonthSegment.selectedSegmentIndex == 0){
            pieView1.hostedGraph.title= [NSString stringWithFormat:@"进出口比例(%@)",qBeginDate];
            pieView2.hostedGraph.title= [NSString stringWithFormat:@"内外贸比例(%@)",qBeginDate];
        }else{
            pieView1.hostedGraph.title= [NSString stringWithFormat:@"进出口比例(%@年)",qYear];
            pieView2.hostedGraph.title= [NSString stringWithFormat:@"内外贸比例(%@年)",qYear];
        }
        if(array.count == 3){
            NSDictionary *wTrade = [[array objectAtIndex:0] objectForKey:@"properties"];
            NSDictionary *nTrade = [[array objectAtIndex:1] objectForKey:@"properties"];
            double iNum =[(NSNumber *)[wTrade objectForKey:@"iTeuNum"] doubleValue] 
                        +[(NSNumber *)[wTrade objectForKey:@"iTeuNum"] doubleValue] ;
            double eNum =[(NSNumber *)[wTrade objectForKey:@"eTeuNum"] doubleValue] 
                        +[(NSNumber *)[wTrade objectForKey:@"eTeuNum"] doubleValue] ;
            dataForPie = [NSDictionary dictionaryWithObjectsAndKeys:
                          [wTrade objectForKey:@"teuNum"], @"wTrade",
                          [nTrade objectForKey:@"teuNum"], @"nTrade",
                          [NSNumber numberWithDouble:iNum],@"import",
                          [NSNumber numberWithDouble:eNum],@"export",
                          nil];
        }else{
            dataForPie = nil;
        }
        [pieView1.hostedGraph reloadData];
        [pieView2.hostedGraph reloadData];
        
        CABasicAnimation *rotation1 = [HDSUtil setAnimation:@"transform.rotation" toLayer:[pieView1.hostedGraph plotAtIndex:0] fromValue:M_PI * 3 toValue:0 forKey:@"pieRotation1"];
        CABasicAnimation *rotation2 = [HDSUtil setAnimation:@"transform.rotation" toLayer:[pieView2.hostedGraph plotAtIndex:0] fromValue:M_PI * 3 toValue:0 forKey:@"pieRotation2"];
        rotation1.delegate = self;
        rotation2.delegate = self;
        
    }else if(parser == parser2){
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:array dataIsTreeNode:false  xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"plan",@"work",nil] yTitleWidth:0 plotNum:2];
        
    }else if(parser == parser3){
        [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot2 data:array dataIsTreeNode:false  xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"plan",@"work",nil] yTitleWidth:0 plotNum:2];
        
    }else if(parser == parser4){    //年度使用plotView1
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:array dataIsTreeNode:false  xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"plan",@"work",nil] yTitleWidth:0 plotNum:2];
    }  
}

- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //    NSLog(@"Connection didReceiveData of length: %u", data.length);
    SBJsonStreamParser *parser ; 
    if(connection == conn0){
        parser = parser0;
    }else if(connection == conn1){
        parser = parser1;
    }else if(connection == conn2){
        parser = parser2;
    }else if(connection == conn3){
        parser = parser3;
    }else if(connection == conn4){
        parser = parser4;
    }
    SBJsonStreamParserStatus status = [parser parse:data];
	if (status == SBJsonStreamParserError) {
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"集装箱吞吐量完成情况");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"集装箱吞吐量完成情况");
	} else{

    }
}

- (IBAction)changeMonthTaped:(UIButton *)sender {
    if(sender == yearBtn){
        if(yearPopover == nil){
            HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearPickerFormat popupBtn:yearBtn];
            picker.delegate = self;
            yearPopover= [[UIPopoverController alloc] initWithContentViewController:picker];
            yearPopover.popoverContentSize = picker.view.frame.size;
            yearPopover.delegate = picker;
        }
        [yearPopover presentPopoverFromRect:yearBtn.frame inView:[yearBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }else if(sender == beginDateBtn){
        if(beginMonthPopover == nil){
            HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearMonthPickerFormat popupBtn:beginDateBtn];
            picker.delegate = self;
            beginMonthPopover= [[UIPopoverController alloc] initWithContentViewController:picker];
            beginMonthPopover.popoverContentSize = picker.view.frame.size;
            beginMonthPopover.delegate = picker;
        }
        [beginMonthPopover presentPopoverFromRect:beginDateBtn.frame inView:[beginDateBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
    }
}

- (void)createDatePopovers{
    
}

- (IBAction)changeSegmentTaped:(UISegmentedControl *)sender {
    if(yearMonthSegment.selectedSegmentIndex == 0){ //月度
        beginDateBtn.hidden = false;
        yearBtn.hidden = true;
        if(!isSmallView){
            CGRect frame = chooseCompBtn.frame;
            frame.origin.x = 258;
            chooseCompBtn.frame = frame;
            frame = companyLabel.frame;
            frame.origin.x = 366;
            frame.size.width = 317;
            companyLabel.frame = frame;
        }
    }else{
        beginDateBtn.hidden = true;
        yearBtn.hidden = false;
        if(!isSmallView){
            CGRect frame = chooseCompBtn.frame;
            frame.origin.x = 239;
            chooseCompBtn.frame = frame;
            frame = companyLabel.frame;
            frame.origin.x = 347;
            frame.size.width = 336;
            companyLabel.frame = frame;
        }
    }
    [self loadData];
    if(isSmallView){
        if(sender.selectedSegmentIndex == 0){
            pageViews = [NSArray arrayWithObjects:tableContainer,barContainer1,barContainer2,pieContainer1,pieContainer2, nil];
            
        }else if(sender.selectedSegmentIndex == 1){
            pageViews = [NSArray arrayWithObjects:tableContainer,barContainer1,pieContainer1,pieContainer2, nil];
        }
        currentViewIndex = 0;
//        [self smallViewChangeToIndex:currentViewIndex];
    }
}

// 根据选中行刷新图表
- (void)changeChartPosition{
    if(yearMonthSegment.selectedSegmentIndex == 0){
        //        plotView1.backgroundColor = [UIColor lightGrayColor];
        //        plotView1.hostedGraph.hidden = true;
        // frame根据朝向的自动变化会延迟，在此强制设置
        if(UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) || [self isInHomePage]){
            self.view.bounds = CGRectMake(0, 0, 703, 748);
        }else{
            self.view.bounds = CGRectMake(0, 0, 748, 1004);
        }
        [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
            if(UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) || [self isInHomePage]){
                self.view.bounds = CGRectMake(0, 0, 703, 748);
                barContainer1.frame = CGRectMake(20, 353, 487, 183);
                barContainer2.alpha = 1;
                pieContainer1.frame = CGRectMake(515,353, 168, 183);
                pieContainer2.frame = CGRectMake(515,545, 168, 183);
            }else{
                self.view.bounds = CGRectMake(0, 0, 748, 1004);
                barContainer1.frame = CGRectMake(20, 609, 485, 183);
                CGRect f = barContainer2.frame;
                f.size.width = 485;
                barContainer2.frame = f;
                barContainer2.alpha = 1;
                pieContainer1.frame = CGRectMake(513,609, 215, 183);
                pieContainer2.frame = CGRectMake(513,801, 215, 183);
            }
            
        } completion:^(BOOL finished){
            //            plotView1.hostedGraph.hidden = false;
        }];
        barContainer1.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth;
        pieContainer1.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth;
        pieContainer2.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth;
        
    }else{
        //        plotView1.backgroundColor = [UIColor lightGrayColor];
        //        plotView1.hostedGraph.hidden = true;
        [UIView animateWithDuration:1 delay:0 options:UIViewAnimationOptionLayoutSubviews animations:^{
            if(UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation]) || [self isInHomePage]){
                barContainer1.frame = CGRectMake(20, 353, 663, 183);
                barContainer2.alpha = 0;
                pieContainer1.frame = CGRectMake(20 ,545, 328, 183);
                pieContainer2.frame = CGRectMake(356,545, 328, 183);
            }else{
                barContainer1.frame = CGRectMake(20, 609, 728, 183);
                barContainer2.alpha = 0;
                pieContainer1.frame = CGRectMake(20, 801, 360, 183);
                pieContainer2.frame = CGRectMake(388,801, 360, 183);
            }
        } completion:^(BOOL finished){
            //            plotView1.hostedGraph.hidden = false;
        }];
        
        barContainer1.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleWidth;
        pieContainer1.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleRightMargin|UIViewAutoresizingFlexibleWidth;
        pieContainer2.autoresizingMask = UIViewAutoresizingFlexibleTopMargin|UIViewAutoresizingFlexibleLeftMargin|UIViewAutoresizingFlexibleWidth;
        
    }
}

//-(NSString *)transformXLabel:(NSString *)xLabel{
//    if(xLabel.length == 6){
//        return [xLabel substringWithRange:NSMakeRange(2, 4)];
//    }
//    return xLabel;
//}
@end
