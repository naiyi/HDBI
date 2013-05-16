//
//  HDS_S_ThruputAnalysis.m
//  散杂货吞吐量分析
//
//  Created by 毅 张 on 12-6-27.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_S_ThruputAnalysis.h"
#import "UIView+AddLine.h"
#import "HDSGradientView.h"

#define FIRST_COL_WIDTH 160.0f
#define OTHER_COL_WIDTH 110.0f
#define COL_HEIGHT 20.0f
#define SMALL_FIRST_COL_WIDTH 120.0f
#define SMALL_OTHER_COL_WIDTH 80.0f
#define SMALL_COL_HEIGHT 15.0f

@implementation HDS_S_ThruputAnalysis{
    
    CPTGraphHostingView *plotView1;
    CPTGraphHostingView *plotView2;
    CPTGraphHostingView *pieView1;
    CPTGraphHostingView *pieView2;
    
    UIPopoverController *yearPopover;
    UIPopoverController *beginMonthPopover;
    UIPopoverController *endMonthPopover;
    CPTLegend *theLegend;
    UIButton *legendSwitch;
    
    NSURLConnection *conn1; // 表格数据
    NSURLConnection *conn2; // 环比图表
    NSURLConnection *conn3; // 同比图表
    NSURLConnection *conn4; // 年度图表
    SBJsonStreamParser *parser1;
    SBJsonStreamParser *parser2;
    SBJsonStreamParser *parser3;
    SBJsonStreamParser *parser4;
    SBJsonStreamParserAdapter *adapter1;
    SBJsonStreamParserAdapter *adapter2;
    SBJsonStreamParserAdapter *adapter3;
    SBJsonStreamParserAdapter *adapter4;
    
    NSString *qYear;
    NSString *qBeginDate;
    NSString *qEndDate;

}

@synthesize barContainer1,barContainer2,pieContainer1,pieContainer2;
@synthesize dataForPlot1,dataForPlot2;
@synthesize dataForPie;
@synthesize beginDateBtn;
@synthesize endDateBtn;
@synthesize yearMonthSegment;
@synthesize yearBtn;
@synthesize toLabel;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification];
    HDSSkinType skinType = [HDSUtil skinType];
    
    [HDSUtil changeSegment:yearMonthSegment textAttributeBySkin:skinType];
    [beginDateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal_110.png"] forState:UIControlStateNormal];
    [beginDateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight_110.png"] forState:UIControlStateHighlighted];
    [endDateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal_110.png"] forState:UIControlStateNormal];
    [endDateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight_110.png"] forState:UIControlStateHighlighted];
    [yearBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal.png"] forState:UIControlStateNormal];
    [yearBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight.png"] forState:UIControlStateHighlighted];
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    [beginDateBtn setTitleColor:color forState:UIControlStateNormal];
    [endDateBtn setTitleColor:color forState:UIControlStateNormal];
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
    // 开始日期
    beginDateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    beginDateBtn.frame = CGRectMake(20,50,119,31);
    beginDateBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    beginDateBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [beginDateBtn addTarget:self action:@selector(changeMonthTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:beginDateBtn];
    // 结束日期
    endDateBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    endDateBtn.frame = CGRectMake(147,50,119,31);
    endDateBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    endDateBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [endDateBtn addTarget:self action:@selector(changeMonthTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:endDateBtn];
    // 年度
    yearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    yearBtn.frame = CGRectMake(20,50,100,31);
    yearBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    yearBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    yearBtn.hidden = true;
    [yearBtn addTarget:self action:@selector(changeMonthTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:yearBtn];
    
    [super fillConditionView:view corpLine:2];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,barContainer1,barContainer2,pieContainer1,pieContainer2, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"散杂货吞吐量分析";
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
    [self addLinePlotView:plotView1 toContainer:barContainer1 title:@"月度吞吐量环比变化趋势(万吨)" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"吞吐量环比",nil] useLegend:NO useLegendIcon:NO];
    plotView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addLinePlotView:plotView2 toContainer:barContainer2 title:@"月度吞吐量同比变化趋势(万吨)" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"吞吐量环比",nil] useLegend:NO useLegendIcon:NO];
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
    [self refreshByDates:dates fromPopupBtn:endDateBtn];
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
//    plotView1.frame = CGRectInset(barContainer1.bounds,5.0f,5.0f);
}

- (void)viewDidUnload{
    [self setBarContainer1:nil];
    [self setBeginDateBtn:nil];
    [self setEndDateBtn:nil];
    [self setYearMonthSegment:nil];
    [self setYearBtn:nil];
    [self setToLabel:nil];
    [self setBarContainer2:nil];
    [self setPieContainer1:nil];
    [self setPieContainer2:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 9;
}

- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
    return 1;
}
// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column==0)
            return SMALL_FIRST_COL_WIDTH;
        return SMALL_OTHER_COL_WIDTH;
    }
    if(column == 0)
        return FIRST_COL_WIDTH;
    return OTHER_COL_WIDTH;
}


- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: {   
            return [NSString stringWithFormat:@"name%i",node.depth+1];
        }
        case 1: return @"win";
        case 2: return @"wout";
        case 3: return @"wtotal";
        case 4: return @"nin";
        case 5: return @"nout";
        case 6: return @"ntotal";
        case 7: return @"intotal";
        case 8: return @"outtotal";
        case 9: return @"total";
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
    float otherColWidth = isSmallView?SMALL_OTHER_COL_WIDTH:OTHER_COL_WIDTH;
    float colHeight = isSmallView?SMALL_COL_HEIGHT:COL_HEIGHT;
    HDSGradientView *header = [HDSUtil getTableViewMultiHeaderBackgroundView];
    
    if(tableViewIndex == 0){ // fixedTableView
        UILabel *cell=[[UILabel alloc] initWithFrame:CGRectMake(0, 0, firstColWidth+1, colHeight*2)];
        cell.text = @"货类/货种/货名";
        cell.textAlignment = UITextAlignmentCenter;
        cell.textColor = [UIColor whiteColor];
        cell.font = _tableView.titleFont;
        cell.backgroundColor = [UIColor clearColor];
        if([HDSUtil skinType] == HDSSkinBlue){
            [header addVerticalLineWithWidth:1 color:[UIColor blackColor] atX:firstColWidth+1];
            [cell addBottomLineWithWidth:1 color:[UIColor blackColor]];  
        }else{
            [header addVerticalLineWithWidth:1 color:[HDSUtil plotBorderColor] atX:firstColWidth+1];
        }
        [header addSubview:cell];
    }else{  // rightTableView
        CGRect rects[12] = {
//            CGRectMake(0, 0, firstColWidth+1, 60),   
            CGRectMake(/*firstColWidth+*/1, 0, otherColWidth*3+3, colHeight), 
            CGRectMake(/*firstColWidth+*/1+otherColWidth*3+3, 0, otherColWidth*3+3, colHeight), 
            CGRectMake(/*firstColWidth+*/1+otherColWidth*6+6, 0, otherColWidth*3+3, colHeight), 
            CGRectMake(/*firstColWidth+*/1,colHeight, otherColWidth+1, colHeight),
            CGRectMake(/*firstColWidth+*/1+otherColWidth+1,colHeight, otherColWidth+1, colHeight),
            CGRectMake(/*firstColWidth+*/1+otherColWidth*2+2,colHeight, otherColWidth+1, colHeight),
            CGRectMake(/*firstColWidth+*/1+otherColWidth*3+3,colHeight, otherColWidth+1, colHeight),
            CGRectMake(/*firstColWidth+*/1+otherColWidth*4+4,colHeight, otherColWidth+1, colHeight),
            CGRectMake(/*firstColWidth+*/1+otherColWidth*5+5,colHeight, otherColWidth+1, colHeight),
            CGRectMake(/*firstColWidth+*/1+otherColWidth*6+6,colHeight, otherColWidth+1, colHeight),
            CGRectMake(/*firstColWidth+*/1+otherColWidth*7+7,colHeight, otherColWidth+1, colHeight),
            CGRectMake(/*firstColWidth+*/1+otherColWidth*8+8,colHeight, otherColWidth+1, colHeight)
        };
        NSArray *titles = [NSArray arrayWithObjects:
//                           @"货类/货种/货名",
                           @"外贸",@"内贸",@"合计",@"进口",
                           @"出口",@"小计",@"进口",@"出口",@"小计",
                           @"进口",@"出口",@"小计",nil];
    
        UILabel *cell;
        for (int i=0; i<12; i++) {
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



- (NSInteger)tableView:(HDSTableView *)tableView canBeExpandedColumnIndexAtNode:(HDSTreeNode *)node{
//    if(isSmallView)
        return 0;
//    return [node depth];
}

-(void)tableView:(HDSTableView *)tableView didSelectRowAtNode:(HDSTreeNode *)node{
    NSInteger qLevel = node.depth+1;
    NSString *qName=[node.properties objectForKey:[NSString stringWithFormat:@"name%i",node.depth+1]];
    
    
    NSString *urlHB,*urlTB;
    NSURLRequest *theRequest;
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
            [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ThruputAnalysis_lineChart1" withExtension:@"json"]]];
            [parser3 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ThruputAnalysis_lineChart2" withExtension:@"json"]]];
        }else{
            urlHB = [[[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SCargoThruput/listMonthhbChart.json?level=%i&name=%@&beginYM=%@&endYM=%@&corps=%@",qLevel,qName,qBeginDate,qEndDate,qCompany] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            urlTB = [[[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SCargoThruput/listMonthtbChart.json?level=%i&name=%@&beginYM=%@&endYM=%@&corps=%@",qLevel,qName,qBeginDate,qEndDate,qCompany] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:urlHB] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
            conn2 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
            theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:urlTB] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
            conn3 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        }
        
        
        plotView1.hostedGraph.title = [NSString stringWithFormat:@"%@月度吞吐量环比(万吨)",qName];
        plotView2.hostedGraph.title = [NSString stringWithFormat:@"%@月度吞吐量同比(万吨)",qName];
        pieView1.hostedGraph.title= [NSString stringWithFormat:@"进出口比例",qBeginDate,qEndDate];
        pieView2.hostedGraph.title= [NSString stringWithFormat:@"内外贸比例",qBeginDate,qEndDate];
        
    }else{
        adapter4 = [[SBJsonStreamParserAdapter alloc] init];
        adapter4.delegate = self;
        parser4 = [[SBJsonStreamParser alloc] init];
        parser4.delegate = adapter4;
        
        if([HDSUtil isOffline]){    // 离线数据
            [parser4 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ThruputAnalysis_lineChart3" withExtension:@"json"]]];
        }else{
            urlHB = [[[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SCargoThruput/listYeartbChart.json?level=%i&name=%@&year=%@&corps=%@",qLevel,qName,qYear,qCompany] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
            theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:urlHB] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
            conn4 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        }
        
        plotView1.hostedGraph.title = [NSString stringWithFormat:@"%@年度吞吐量(万吨)",qName];
        pieView1.hostedGraph.title= [NSString stringWithFormat:@"进出口比例(%@年)",qYear];
        pieView2.hostedGraph.title= [NSString stringWithFormat:@"内外贸比例(%@年)",qYear];

    }
    // 饼图不需要访问数据库，可以直接刷新
    dataForPie = [node.properties copy];
    [pieView1.hostedGraph reloadData];
    [pieView2.hostedGraph reloadData];
    
    CABasicAnimation *rotation1 = [HDSUtil setAnimation:@"transform.rotation" toLayer:[pieView1.hostedGraph plotAtIndex:0] fromValue:M_PI * 3 toValue:0 forKey:@"pieRotation1"];
    CABasicAnimation *rotation2 = [HDSUtil setAnimation:@"transform.rotation" toLayer:[pieView2.hostedGraph plotAtIndex:0] fromValue:M_PI * 3 toValue:0 forKey:@"pieRotation2"];
    rotation1.delegate = self;
    rotation2.delegate = self;
}

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
        qEndDate = [NSString stringWithFormat:@"%d%02d",[_dates year],[_dates month]];
        return;
    }
    
    if(popupBtn == yearBtn){
        [yearBtn setTitle:[NSString stringWithFormat:@"     %d年",[_dates year]] forState:UIControlStateNormal];
        qYear = [NSString stringWithFormat:@"%d",[_dates year]];
    }else if(popupBtn == beginDateBtn){
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
                    return [(NSNumber *)[dataForPie objectForKey:@"intotal"] doubleValue];
                }else{
                    return [(NSNumber *)[dataForPie objectForKey:@"outtotal"] doubleValue];
                }
            }else if(plot == [pieView2.hostedGraph plotAtIndex:0]){ //内外贸
                if(index == 0){
                    return [(NSNumber *)[dataForPie objectForKey:@"ntotal"] doubleValue];
                }else{
                    return [(NSNumber *)[dataForPie objectForKey:@"wtotal"] doubleValue];
                }
            }
		}else {
			return index;
		}
	}else if ( [plot isKindOfClass:[CPTScatterPlot class]]){
        if(fieldEnum == CPTBarPlotFieldBarLocation ){
            return index+1;
        }else{  //CPTBarPlotFieldBarTip
            NSDictionary *dict;
            if(plot == [plotView1.hostedGraph plotAtIndex:0]){
                dict = [dataForPlot1 objectAtIndex:index];
            }else if(plot == [plotView2.hostedGraph plotAtIndex:0]){
                dict = [dataForPlot2 objectAtIndex:index];
            }
            return [(NSNumber *)[dict objectForKey:@"wgt"] doubleValue];
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
        newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.0f", 
        [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index]] style:whiteText];
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
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
    
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_S_ThruputAnalysis_grid" withExtension:@"json"]]];
    }else{
        // 表格数据
        NSString *url;
        if(yearMonthSegment.selectedSegmentIndex == 0){
            url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SCargoThruput/listMonth.json?beginYM=%@&endYM=%@&corps=%@",qBeginDate,qEndDate,qCompany];
        }else{
            url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/SCargoThruput/listYear.json?year=%@&corps=%@",qYear,qCompany];
        }
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
            [self loadChildren:node withData:data];
        }
        [tableView reloadData];
        if(!isSmallView){
            [self changeChartPosition];
        }
        // 查询完数据默认选中第一行
        [tableView doSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        
    }else if(parser == parser2){
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:array dataIsTreeNode:false  xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"wgt",nil] yTitleWidth:0 plotNum:1];
        
    }else if(parser == parser3){
        [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot2 data:array dataIsTreeNode:false  xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"wgt",nil] yTitleWidth:0 plotNum:1];
        
    }else if(parser == parser4){    //年度使用plotView1
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:array dataIsTreeNode:false  xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"wgt",nil] yTitleWidth:0 plotNum:1];
    }  
}

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
    }else if(connection == conn4){
        parser = parser4;
    }
    SBJsonStreamParserStatus status = [parser parse:data];
	if (status == SBJsonStreamParserError) {
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"吞吐量分析");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"吞吐量分析");
	} else{
        //        NSLog(@"Parser over.");
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

- (IBAction)changeSegmentTaped:(UISegmentedControl *)sender {
    if(yearMonthSegment.selectedSegmentIndex == 0){ //月度
        beginDateBtn.hidden = false;
        endDateBtn.hidden = false;
        toLabel.hidden = false;
        yearBtn.hidden = true;
        if(!isSmallView){
            CGRect frame = chooseCompBtn.frame;
            frame.origin.x = 389;
            chooseCompBtn.frame = frame;
            frame = companyLabel.frame;
            frame.origin.x = 497;
            frame.size.width = 186;
            companyLabel.frame = frame;
        }
    }else{
        beginDateBtn.hidden = true;
        endDateBtn.hidden = true;
        toLabel.hidden = true;
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

-(NSString *)transformXLabel:(NSString *)xLabel{
    //    if(xLabel.length>10){
    //        return [[xLabel substringWithRange:NSMakeRange(0, 10)] stringByAppendingString:@"..."];
    //    }
    return xLabel;
}
@end

