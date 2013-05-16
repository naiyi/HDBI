//
//  HDS_C_ContainerThruput.m
//  HDBI
//
//  Created by 毅 张 on 12-8-16.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_C_ContainerThruput.h"
#import "UIView+AddLine.h"
#import "HDSGradientView.h"

#define L_Width 663
#define P_Width 728

#define COL0_WIDTH 110.0f
#define OTHER_COL_WIDTH 80.0f
#define COL_HEIGHT 20.0f
#define SMALL_COL0_WIDTH 100.0f
#define SMALL_OTHER_COL_WIDTH 60.0f
#define SMALL_COL_HEIGHT 15.0f

@implementation HDS_C_ContainerThruput{

    CPTGraphHostingView *plotView1;
    CPTGraphHostingView *plotView2;
    CPTGraphHostingView *pieView1;
    CPTGraphHostingView *pieView2;
    CPTGraphHostingView *pieView3;
    
    NSURLConnection *conn1; // 表格数据
    NSURLConnection *conn2;
    NSURLConnection *conn3;
    SBJsonStreamParser *parser1;
    SBJsonStreamParser *parser2;
    SBJsonStreamParser *parser3;
    SBJsonStreamParserAdapter *adapter1;
    SBJsonStreamParserAdapter *adapter2;
    SBJsonStreamParserAdapter *adapter3;
    
    UIPopoverController *beginMonthPopover;
    UIPopoverController *endMonthPopover;
    
    NSString *qBeginDate;
    NSString *qEndDate;
}
@synthesize plotContainer1,plotContainer2;
@synthesize scrollView;
@synthesize pageControl;
@synthesize pieContainer1,pieContainer2,pieContainer3;
@synthesize beginDateBtn,endDateBtn;
@synthesize dataForPlot1,dataForPlot2;
@synthesize dataForPie;

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
    [self refreshPlotTheme:pieView1];
    [self refreshPlotTheme:pieView2];
    [self refreshPlotTheme:pieView3];
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
        pageViews=[NSArray arrayWithObjects:tableContainer,plotContainer1,plotContainer2,pieContainer1,pieContainer2,pieContainer3,nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"集装箱吞吐量统计";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    tableView.treeInOneCell = true;
    tableView.dataMaxDepth = 3;
    
    int width = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])? L_Width:P_Width;
    scrollView.contentSize = CGSizeMake(width*2, 183);  //scrollview的滚动范围
    scrollView.delegate = self;
    scrollView.layer.borderColor = [HDSUtil plotBorderColor].CGColor;
    scrollView.layer.borderWidth = 1.0f;
    scrollView.layer.cornerRadius = isSmallView? Table_Corner_Small:Table_Corner;
    scrollView.layer.masksToBounds = true;
    
    UIInterfaceOrientation orientation =[[UIApplication sharedApplication] statusBarOrientation];
    [self changePlotContainerFrame:plotContainer1 index:0 orientation:orientation];
    [self changePlotContainerFrame:plotContainer2 index:1 orientation:orientation];
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addLinePlotView:plotView1 toContainer:plotContainer1 title:@"集装箱吞吐量环比(TEU)" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"箱量",nil] useLegend:NO useLegendIcon:NO];
    
    plotView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addLinePlotView:plotView2 toContainer:plotContainer2 title:@"集装箱吞吐量同比(TEU)" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"箱量",nil] useLegend:NO useLegendIcon:NO];
    
    pieView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addPiePlotView:pieView1 toContainer:pieContainer1 title:@"进出口" useLegend:YES useLegendIcon:YES];
    pieView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addPiePlotView:pieView2 toContainer:pieContainer2 title:@"空重" useLegend:YES useLegendIcon:YES];
    pieView3 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addPiePlotView:pieView3 toContainer:pieContainer3 title:@"尺寸" useLegend:YES useLegendIcon:YES];
    
    if(!isSmallView){
        plotView1.layer.borderWidth = 0;
        plotView1.layer.cornerRadius = isSmallView? Table_Corner_Small:0;
        plotView2.layer.borderWidth = 0;
        plotView2.layer.cornerRadius = isSmallView? Table_Corner_Small:0;
    }
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

- (void)changePlotContainerFrame:(UIView *)container index:(NSInteger)index orientation:(UIInterfaceOrientation) orientation{
    if(isSmallView) return;
    int width = UIInterfaceOrientationIsLandscape(orientation)? L_Width:P_Width;
    CGRect f = container.frame;
    f.origin.x = index*width;
    f.size.width = width;
    container.frame = f;
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)_scrollView{
    int width = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])? L_Width:P_Width;
    int page = _scrollView.contentOffset.x / width;
    pageControl.currentPage = page;
}


- (IBAction)changePage:(UIPageControl *)sender {
    int width = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])? L_Width:P_Width;
    int page = pageControl.currentPage;
    [scrollView setContentOffset:CGPointMake(width * page, 0)];
}

- (void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation{
    if(isSmallView) return;
    UIInterfaceOrientation toOrientation = UIInterfaceOrientationIsLandscape(fromInterfaceOrientation)?UIInterfaceOrientationPortrait:UIInterfaceOrientationLandscapeLeft;
    [self changePlotContainerFrame:plotContainer1 index:0 orientation:toOrientation];
    [self changePlotContainerFrame:plotContainer2 index:1 orientation:toOrientation];
    int width = UIInterfaceOrientationIsLandscape(toOrientation)? L_Width:P_Width;
    scrollView.contentSize = CGSizeMake(width*4, 186); 
    [self changePage:nil];
}


-(void)viewDidLayoutSubviews{
    if(isSmallView)
        return;
    [tableView adjustRightTableViewWidth];
    [tableView positionVerticalScrollBar];
    plotView1.frame = plotContainer1.bounds;
    plotView2.frame = plotContainer2.bounds;
    pieView1.frame = pieContainer1.bounds;
    pieView2.frame = pieContainer2.bounds;
    pieView3.frame = pieContainer3.bounds;
}

- (void)viewDidUnload{
    [self setPlotContainer1:nil];
    [self setPlotContainer2:nil];
    [self setPieContainer1:nil];
    [self setPieContainer2:nil];
    [self setPieContainer3:nil];
    [self setBeginDateBtn:nil];
    [self setEndDateBtn:nil];
    [self setPageControl:nil];
    [self setScrollView:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 23;
}

- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
    return 1;
}
- (CGFloat)heightForHeaderCellOfTableView:(HDSTableView *)tableView{
    if(isSmallView){
        return SMALL_COL_HEIGHT*3;
    }
    return COL_HEIGHT*3;
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
    
    CGRect rects[31] = {  
        CGRectMake(1, 0, col0Width, colHeight*3),// 公司
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
                       @"公司\n中转/本港",@"合计\n重量",@"合计箱量",@"自然箱",@"标准箱",@"进口",@"空箱",@"重箱",@"合计\n重量",@"合计\nTEU",@"20",
                       @"40",@"45",@"其他",@"20",@"40",@"45",@"其他",@"出口",@"空箱",@"重箱",@"合计\n重量",@"合计\nTEU",@"20",
                       @"40",@"45",@"其他",@"20",@"40",@"45",@"其他",nil];
    UILabel *cell;
    int beginIndex,endIndex;
    if(tableViewIndex == 0){
        beginIndex = 0;
        endIndex = 1;
    }else{
        beginIndex = 1;
        endIndex = 31;
    }
    for (int i=beginIndex; i<endIndex; i++) {
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

- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return [NSString stringWithFormat:@"name%i",node.depth+1];
        case 1: return @"totalWgt";
        case 2: return @"cntrNum";
        case 3: return @"teuNum";
        case 4: return @"ie20";
        case 5: return @"ie40";
        case 6: return @"ie45";
        case 7: return @"ieother";
        case 8: return @"if20";
        case 9: return @"if40";
        case 10: return @"if45";
        case 11: return @"ifother";
        case 12: return @"iWgt";
        case 13: return @"iTeuNum";
        case 14: return @"ee20";
        case 15: return @"ee40";
        case 16: return @"ee45";
        case 17: return @"eeother";
        case 18: return @"ef20";
        case 19: return @"ef40";
        case 20: return @"ef45";
        case 21: return @"efother";
        case 22: return @"eWgt";
        case 23: return @"eTeuNum";
        default:return @"";
    }
}

- (NSInteger)tableView:(HDSTableView *)tableView canBeExpandedColumnIndexAtNode:(HDSTreeNode *)node{
    return 0;
}

-(void)tableView:(HDSTableView *)tableView didSelectRowAtNode:(HDSTreeNode *)node{
    NSInteger qLevel = node.depth+1;
    
    NSString *qCorpCod,*qTransId,*qTradeId;
    NSMutableString *qName = [[NSMutableString alloc] init];
    if(node.depth == 0){
        [qName appendString:[node.properties objectForKey:@"name1"]];
        qCorpCod = [node.properties objectForKey:@"corpCod"];
    }else if(node.depth == 1){
        [qName appendString:[node.parent.properties objectForKey:@"name1"]];
        [qName appendString:[node.properties objectForKey:@"name2"]];
        qCorpCod = [node.parent.properties objectForKey:@"corpCod"];
        qTransId = [node.properties objectForKey:@"transId"];
    }else if(node.depth == 2){
        [qName appendString:[node.parent.parent.properties objectForKey:@"name1"]];
        [qName appendString:[node.parent.properties objectForKey:@"name2"]];
        [qName appendString:[node.properties objectForKey:@"name3"]];
        qCorpCod = [node.parent.parent.properties objectForKey:@"corpCod"];
        qTransId = [node.parent.properties objectForKey:@"transId"];
        qTradeId = [node.properties objectForKey:@"tradeId"];
    }
    
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
        [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ContainerThruputChart1" withExtension:@"json"]]];
        [parser3 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ContainerThruputChart2" withExtension:@"json"]]];
    }else{
        urlHB = [[[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CContainerThruput/listHbChart.json?level=%i&beginYM=%@&endYM=%@&corpCod=%@&transId=%@&tradeId=%@",qLevel,qBeginDate,qEndDate,qCorpCod,qTransId,qTradeId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        urlTB = [[[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CContainerThruput/listTbChart.json?level=%i&beginYM=%@&endYM=%@&corpCod=%@&transId=%@&tradeId=%@",qLevel,qBeginDate,qEndDate,qCorpCod,qTransId,qTradeId] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:urlHB] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        theRequest =[NSURLRequest requestWithURL:[NSURL URLWithString:urlTB] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn3 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }

    plotView1.hostedGraph.title = [NSString stringWithFormat:@"%@集装箱吞吐量环比(TEU)",qName];
    plotView2.hostedGraph.title = [NSString stringWithFormat:@"%@集装箱吞吐量同比(TEU)",qName];
    pieView1.hostedGraph.title= [NSString stringWithFormat:@"%@进出口比例",qName];
    pieView2.hostedGraph.title= [NSString stringWithFormat:@"%@空重比例",qName];
    pieView3.hostedGraph.title= [NSString stringWithFormat:@"%@尺寸比例",qName];
    
    // 饼图不需要访问数据库，可以直接刷新
    ((CPTPieChart *)[pieView1.hostedGraph plotAtIndex:0]).overlayFill = 
    ((CPTPieChart *)[pieView2.hostedGraph plotAtIndex:0]).overlayFill = 
    ((CPTPieChart *)[pieView3.hostedGraph plotAtIndex:0]).overlayFill = 
    [CPTFill fillWithGradient:[HDSUtil pieChartOverlay]];
    dataForPie = [node.properties copy];
    [pieView1.hostedGraph reloadData];
    [pieView2.hostedGraph reloadData];
    [pieView3.hostedGraph reloadData];
    
    CABasicAnimation *rotation1 = [HDSUtil setAnimation:@"transform.rotation" toLayer:[pieView1.hostedGraph plotAtIndex:0] fromValue:M_PI * 3 toValue:0 forKey:@"pieRotation1"];
    CABasicAnimation *rotation2 = [HDSUtil setAnimation:@"transform.rotation" toLayer:[pieView2.hostedGraph plotAtIndex:0] fromValue:M_PI * 3 toValue:0 forKey:@"pieRotation2"];
    CABasicAnimation *rotation3 = [HDSUtil setAnimation:@"transform.rotation" toLayer:[pieView3.hostedGraph plotAtIndex:0] fromValue:M_PI * 3 toValue:0 forKey:@"pieRotation3"];
    rotation1.delegate = self;
    rotation2.delegate = self;
    rotation3.delegate = self;
    
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
    }else if(anim == [pieView3.hostedGraph.legend animationForKey:@"legendAnimation"]){
        [pieView3 viewWithTag:Legend_Switch_Tag].hidden = NO;
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
    if ( plot == [plotView1.hostedGraph plotAtIndex:0] ) {
		return [dataForPlot1 count];
	}else if ( plot == [plotView2.hostedGraph plotAtIndex:0] ) {
		return [dataForPlot2 count];
	}else if ( plot == [pieView1.hostedGraph plotAtIndex:0] || plot == [pieView2.hostedGraph plotAtIndex:0]) {
		return 2;
	}else if ( plot == [pieView3.hostedGraph plotAtIndex:0] ) {
		return 4;
	}else {
		return 0;
	}
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    if ([plot isKindOfClass:[CPTScatterPlot class]]){
        if ( fieldEnum == CPTScatterPlotFieldY ) {
            if(plot == [plotView1.hostedGraph plotAtIndex:0]){   
                return [(NSNumber *)[[dataForPlot1 objectAtIndex:index] objectForKey:@"teu"] doubleValue];
            }else if(plot == [plotView2.hostedGraph plotAtIndex:0]){ 
                return [(NSNumber *)[[dataForPlot2 objectAtIndex:index] objectForKey:@"teu"] doubleValue];
            }
        }else { //CPTScatterPlotFieldX
            return index+1;
        }
        
    }else if([plot isKindOfClass:[CPTPieChart class]]){
        if ( fieldEnum == CPTPieChartFieldSliceWidth ) {
            if(plot == [pieView1.hostedGraph plotAtIndex:0]){   //进出口
                if(index == 0){
                    return [(NSNumber *)[dataForPie objectForKey:@"iTeuNum"] doubleValue];
                }else{
                    return [(NSNumber *)[dataForPie objectForKey:@"eTeuNum"] doubleValue];
                }
            }else if(plot == [pieView2.hostedGraph plotAtIndex:0]){    //空重
                if(index == 0){
                    return [(NSNumber *)[dataForPie objectForKey:@"ie20"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ie40"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ie45"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ieother"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ee20"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ee40"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ee45"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"eeother"] doubleValue];
                }else{
                    return [(NSNumber *)[dataForPie objectForKey:@"if20"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"if40"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"if45"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ifother"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ef20"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ef40"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ef45"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"efother"] doubleValue];
                }
            }else if(plot == [pieView3.hostedGraph plotAtIndex:0]){     //尺寸
                if(index == 0){ //20
                    return [(NSNumber *)[dataForPie objectForKey:@"ie20"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"if20"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ee20"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ef20"] doubleValue];
                }else if(index == 1){ //40
                    return [(NSNumber *)[dataForPie objectForKey:@"ie40"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"if40"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ee40"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ef40"] doubleValue];
                }else if(index == 2){ //45
                    return [(NSNumber *)[dataForPie objectForKey:@"ie45"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"if45"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ee45"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ef45"] doubleValue];
                }else{  //其他
                    return [(NSNumber *)[dataForPie objectForKey:@"ieother"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"ifother"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"eeother"] doubleValue]
                        +[(NSNumber *)[dataForPie objectForKey:@"efother"] doubleValue];
                }
            }
        }else {
            return index;
        }
    }
    return 0;
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView)
        return nil;
    
	CPTTextStyle *whiteText = [HDSUtil plotTextStyle:10];
    NSString *label;
    
    if ( [plot isKindOfClass:[CPTPieChart class]] && [self doubleForPlot:plot field:CPTPieChartFieldSliceWidth recordIndex:index]>0 ) {
        if(plot == [pieView1.hostedGraph plotAtIndex:0]){
            switch (index) {
                case 0: label = @"进口"; break;
                case 1: label = @"出口"; break;
            }
        }else if(plot == [pieView2.hostedGraph plotAtIndex:0]){
            switch (index) {
                case 0: label = @"空箱"; break;
                case 1: label = @"重箱"; break;
            }
        }else if(plot == [pieView3.hostedGraph plotAtIndex:0]){
            switch (index) {
                case 0: label = @"20尺"; break;
                case 1: label = @"40尺"; break;
                case 2: label = @"45尺"; break;
                case 3: label = @"其他"; break;
            }
        }
	}
	return [[CPTTextLayer alloc] initWithText:label  style:whiteText];;
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
        switch (index) {
            case 0: return @"进口";
            case 1: return @"出口";
        }
    }else if(pieChart == [pieView2.hostedGraph plotAtIndex:0]){
        switch (index) {
            case 0: return @"空箱";
            case 1: return @"重箱";
        }
    }else if(pieChart == [pieView3.hostedGraph plotAtIndex:0]){
        switch (index) {
            case 0: return @"20尺";
            case 1: return @"40尺";
            case 2: return @"45尺";
            case 3: return @"其他";
        }
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
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ContainerThruputGrid" withExtension:@"json"]]];
    }else{
        NSString *url;
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CContainerThruput/list.json?beginYM=%@&endYM=%@&corps=%@",qBeginDate, qEndDate, qCompany];
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
            [self loadChildren:node withData:data expand:true];
        }
        [tableView reloadData];
        // 查询完数据默认选中第一行
        [dataForPlot1 removeAllObjects];
        [dataForPlot2 removeAllObjects];
        dataForPie = nil;
        ((CPTPieChart *)[pieView1.hostedGraph plotAtIndex:0]).overlayFill = nil;
        ((CPTPieChart *)[pieView2.hostedGraph plotAtIndex:0]).overlayFill = nil;
        ((CPTPieChart *)[pieView3.hostedGraph plotAtIndex:0]).overlayFill = nil;
        if( self.rootArray.count >0 ){
            [tableView doSelectRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0]];
        }else{
            // 清空原来的图表数据
            [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:[NSArray array] dataIsTreeNode:false xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"teu", nil] yTitleWidth:0 plotNum:1];
            [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot2 data:[NSArray array] dataIsTreeNode:false xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"teu", nil] yTitleWidth:0 plotNum:1];
            [pieView1.hostedGraph reloadData];
            [pieView2.hostedGraph reloadData];
            [pieView3.hostedGraph reloadData];
        }
        
    }else if(parser == parser2){
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:array dataIsTreeNode:false xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"teu", nil] yTitleWidth:0 plotNum:1];
    }else if(parser == parser3){
        [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot2 data:array dataIsTreeNode:false xLabelKey:@"date" yLabelKey:[NSArray arrayWithObjects:@"teu", nil] yTitleWidth:0 plotNum:1];
    }
}


- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"集装箱吞吐量统计");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"集装箱吞吐量统计");
	} else{

    }
}
@end
