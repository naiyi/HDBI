//
//  HDS_C_ContainerStuff.m
//  HDBI
//
//  Created by 毅 张 on 12-9-6.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#define L_Width 663
#define P_Width 728

#define COL0_WIDTH 160.0f
#define OTHER_COL_WIDTH 60.0f
#define COL_HEIGHT 20.0f
#define SMALL_COL0_WIDTH 120.0f
#define SMALL_OTHER_COL_WIDTH 40.0f
#define SMALL_COL_HEIGHT 15.0f

#import "HDS_C_ContainerStuff.h"
#import "UIView+AddLine.h"
#import "HDSGradientView.h"

@implementation HDS_C_ContainerStuff{
    
    CPTGraphHostingView *plotView1;
    CPTGraphHostingView *plotView2;
    CPTGraphHostingView *plotView3;
    CPTGraphHostingView *plotView4;
    
    UIPopoverController *datePopover;
    
    NSURLConnection *conn1; // 表格数据
    SBJsonStreamParser *parser1;
    SBJsonStreamParserAdapter *adapter1;
    NSURLConnection *conn2; // 
    SBJsonStreamParser *parser2;
    SBJsonStreamParserAdapter *adapter2;
    NSURLConnection *conn3; // 
    SBJsonStreamParser *parser3;
    SBJsonStreamParserAdapter *adapter3;
    NSURLConnection *conn4; // 
    SBJsonStreamParser *parser4;
    SBJsonStreamParserAdapter *adapter4;
    NSURLConnection *conn5; // 
    SBJsonStreamParser *parser5;
    SBJsonStreamParserAdapter *adapter5;
    
    NSString *qMonth;
}
@synthesize pageControl;

@synthesize plotContainer1;
@synthesize plotContainer2;
@synthesize plotContainer3;
@synthesize plotContainer4;
@synthesize dataForPlot1;
@synthesize dataForPlot2;
@synthesize dataForPlot3;
@synthesize dataForPlot4;
@synthesize scrollView;
@synthesize monthBtn;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification]; 
    
    HDSSkinType skinType = [HDSUtil skinType];
    [monthBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal_110.png"] forState:UIControlStateNormal];
    [monthBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight_110.png"] forState:UIControlStateHighlighted];
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    [monthBtn setTitleColor:color forState:UIControlStateNormal];
    
    [self refreshPlotTheme:plotView1];
    [self refreshPlotTheme:plotView2];
    [self refreshPlotTheme:plotView3];
    [self refreshPlotTheme:plotView4];
}

- (void)fillConditionView:(UIView *)view{
    // 月度
    monthBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    monthBtn.frame = CGRectMake(20,10,119,31);
    monthBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    monthBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [monthBtn addTarget:self action:@selector(changeMonthTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:monthBtn];
    
    [super fillConditionView:view];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,plotContainer1,plotContainer2,plotContainer3,plotContainer4, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"拆装箱作业统计";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    tableView.treeInOneCell = true;
    tableView.dataMaxDepth = 3;
    
    int width = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])? L_Width:P_Width;
    scrollView.contentSize = CGSizeMake(width*4, 286);  //scrollview的滚动范围
    scrollView.delegate = self;
    scrollView.layer.borderColor = [HDSUtil plotBorderColor].CGColor;
    scrollView.layer.borderWidth = 1.0f;
    scrollView.layer.cornerRadius = isSmallView? Table_Corner_Small:Table_Corner;
    scrollView.layer.masksToBounds = true;
    
    UIInterfaceOrientation orientation =[[UIApplication sharedApplication] statusBarOrientation];
    [self changePlotContainerFrame:plotContainer1 index:0 orientation:orientation];
    [self changePlotContainerFrame:plotContainer2 index:1 orientation:orientation];
    [self changePlotContainerFrame:plotContainer3 index:2 orientation:orientation];
    [self changePlotContainerFrame:plotContainer4 index:3 orientation:orientation];
    
    plotView1 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView1 toContainer:plotContainer1 title:@"箱公司装箱分析" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"箱量",nil] useLegend:NO useLegendIcon:NO];
    
    plotView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView2 toContainer:plotContainer2 title:@"箱公司拆箱分析" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"箱量",nil] useLegend:NO useLegendIcon:NO];
    
    plotView3 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView3 toContainer:plotContainer3 title:@"按货名装箱分析" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"箱量",nil] useLegend:NO useLegendIcon:NO];
    
    plotView4 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView4 toContainer:plotContainer4 title:@"按货名拆箱分析" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"箱量",nil] useLegend:NO useLegendIcon:NO];
    
    if(!isSmallView){
        plotView1.layer.borderWidth = 0;
        plotView1.layer.cornerRadius = isSmallView? Table_Corner_Small:0;
        plotView2.layer.borderWidth = 0;
        plotView2.layer.cornerRadius = isSmallView? Table_Corner_Small:0;
        plotView3.layer.borderWidth = 0;
        plotView3.layer.cornerRadius = isSmallView? Table_Corner_Small:0;
        plotView4.layer.borderWidth = 0;
        plotView4.layer.cornerRadius = isSmallView? Table_Corner_Small:0;
    }
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    self.dataForPlot1 = [[NSMutableArray alloc] init];
    self.dataForPlot2 = [[NSMutableArray alloc] init];
    self.dataForPlot3 = [[NSMutableArray alloc] init];
    self.dataForPlot4 = [[NSMutableArray alloc] init];
    
    // 初始化默认月份
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:[NSDate date]];
    [self refreshByDates:dates fromPopupBtn:monthBtn];
    // 默认全部权限的公司
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

//- (void)scrollViewDidScroll:(UIScrollView *)sender {
//    int width = UIInterfaceOrientationIsLandscape([[UIApplication sharedApplication] statusBarOrientation])? L_Width:P_Width;
//    int page = scrollView.contentOffset.x / width;
//    pageControl.currentPage = page;
//}
//- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate{
//
//}

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
    [self changePlotContainerFrame:plotContainer3 index:2 orientation:toOrientation];
    [self changePlotContainerFrame:plotContainer4 index:3 orientation:toOrientation];
    int width = UIInterfaceOrientationIsLandscape(toOrientation)? L_Width:P_Width;
    scrollView.contentSize = CGSizeMake(width*4, 286); 
    [self changePage:nil];
}

- (void)willRotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    
}

//- (void)showLegend:(UIButton *)legendSwitch{
//    legendSwitch.hidden = YES;
//    CAKeyframeAnimation *anim = [CAKeyframeAnimation animationWithKeyPath:@"opacity"];
//    anim.values = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:1.0],[NSNumber numberWithFloat:0.0],nil ];
//    anim.keyTimes = [NSArray arrayWithObjects:[NSNumber numberWithFloat:0.0], [NSNumber numberWithFloat:0.2],[NSNumber numberWithFloat:0.8],[NSNumber numberWithInt:1.0],nil ];
//    anim.duration = 5.0f;
//    anim.removedOnCompletion = NO;
//    anim.delegate			 = self;
//    CPTLegend *theLegend = plotView1.hostedGraph.legend;
//    [theLegend addAnimation:anim forKey:@"legendAnimation"];
//}
//
//-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
//    if(anim == [plotView1.hostedGraph.legend animationForKey:@"legendAnimation"]){
//        [plotView1 viewWithTag:Legend_Switch_Tag].hidden = NO;
//    }
//}

-(void)viewDidLayoutSubviews{
    if(isSmallView)
        return;
    [tableView adjustRightTableViewWidth];
    [tableView positionVerticalScrollBar];
    plotView1.frame = plotContainer1.bounds;
    plotView2.frame = plotContainer2.bounds;
    plotView3.frame = plotContainer3.bounds;
    plotView4.frame = plotContainer4.bounds;
}

- (void)viewDidUnload{
    [self setPlotContainer1:nil];
    [self setScrollView:nil];
    [self setPageControl:nil];
    [self setPlotContainer2:nil];
    [self setPlotContainer3:nil];
    [self setPlotContainer4:nil];
    [self setDataForPlot1:nil];
    [self setDataForPlot2:nil];
    [self setDataForPlot3:nil];
    [self setDataForPlot4:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 12;
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
    
    CGRect rects[19] = {  
        CGRectMake(1, 0, col0Width, colHeight*3),// 公司
//        CGRectMake(1+col0Width, 0, col0Width, colHeight*3),//箱公司
//        CGRectMake(1+col0Width*2, 0, col0Width, colHeight*3),//货名
        
        CGRectMake(1, 0, otherColWidth*6, colHeight),//装箱
        CGRectMake(1, colHeight, otherColWidth*3, colHeight),//外贸
        CGRectMake(1+otherColWidth*3,colHeight, otherColWidth*3, colHeight),//内贸
        CGRectMake(1, colHeight*2, otherColWidth, colHeight),//20
        CGRectMake(1+otherColWidth, colHeight*2, otherColWidth, colHeight),//40
        CGRectMake(1+otherColWidth*2, colHeight*2, otherColWidth, colHeight),//45
        CGRectMake(1+otherColWidth*3, colHeight*2, otherColWidth, colHeight),//20
        CGRectMake(1+otherColWidth*4, colHeight*2, otherColWidth, colHeight),//40
        CGRectMake(1+otherColWidth*5, colHeight*2, otherColWidth, colHeight),//45
        
        CGRectMake(1+otherColWidth*6, 0, otherColWidth*6, colHeight),//拆箱
        CGRectMake(1+otherColWidth*6, colHeight, otherColWidth*3, colHeight),//外贸
        CGRectMake(1+otherColWidth*9,colHeight, otherColWidth*3, colHeight),//内贸
        CGRectMake(1+otherColWidth*6, colHeight*2, otherColWidth, colHeight),//20
        CGRectMake(1+otherColWidth*7, colHeight*2, otherColWidth, colHeight),//40
        CGRectMake(1+otherColWidth*8, colHeight*2, otherColWidth, colHeight),//45
        CGRectMake(1+otherColWidth*9, colHeight*2, otherColWidth, colHeight),//20
        CGRectMake(1+otherColWidth*10, colHeight*2, otherColWidth, colHeight),//40
        CGRectMake(1+otherColWidth*11, colHeight*2, otherColWidth, colHeight),//45
    };
    NSArray *titles = [NSArray arrayWithObjects:
                       @"公司/箱公司/货名",/*@"箱公司",@"货名",*/@"装箱",@"外贸",@"内贸",@"20",
                       @"40",@"45",@"20",@"40",@"45",@"拆箱",@"外贸",@"内贸",@"20",
                       @"40",@"45",@"20",@"40",@"45",nil];
    UILabel *cell;
    int beginIndex,endIndex;
    if(tableViewIndex == 0){
        beginIndex = 0;
        endIndex = 1;
    }else{
        beginIndex = 1;
        endIndex = 19;
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
        case 0:
            switch (node.depth) {
                case 0: return @"corp";
                case 1: return @"name1";
                case 2: return @"name2";
            }
//        case 1: return @"name1";
//        case 2: return @"name2";
        case 3-2: return @"zw20";
        case 4-2: return @"zw40";
        case 5-2: return @"zw45";
        case 6-2: return @"zn20";
        case 7-2: return @"zn40";
        case 8-2: return @"zn45";
        case 9-2: return @"cw20";
        case 10-2: return @"cw40";
        case 11-2: return @"cw45";
        case 12-2: return @"cn20";
        case 13-2: return @"cn40";
        case 14-2: return @"cn45";
        default:return @"";
    }
}

-(NSInteger)tableView:(HDSTableView*)_tableView canBeExpandedColumnIndexAtNode:(HDSTreeNode*)node{
//    if(node.depth < 2)
//        return node.depth;
//    return -1;
    return 0;
}

#pragma mark -
#pragma mark Plot Data Source Methods
//-(NSString *)legendTitleForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index{
//    return [NSString stringWithFormat:@"Bar %lu", (unsigned long)(index + 1)];
//}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
    NSString *graphId = (NSString *)plot.graph.identifier;
    if([graphId isEqualToString:@"箱公司装箱分析"]){
        return [dataForPlot1 count];
    }else if([graphId isEqualToString:@"箱公司拆箱分析"]){
        return [dataForPlot2 count];
    }else if([graphId isEqualToString:@"按货名装箱分析"]){
        return [dataForPlot3 count];
    }else if([graphId isEqualToString:@"按货名拆箱分析"]){
        return [dataForPlot4 count];
    }
    return 0;
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    NSString *graphId = (NSString *)plot.graph.identifier;
    NSArray *_dataForPlot;
    if(fieldEnum == CPTBarPlotFieldBarLocation ){
        return index+1;
    }else{  //CPTBarPlotFieldBarTip
        if([graphId isEqualToString:@"箱公司装箱分析"]){
            _dataForPlot = dataForPlot1;
        }else if([graphId isEqualToString:@"箱公司拆箱分析"]){
            _dataForPlot = dataForPlot2;
        }else if([graphId isEqualToString:@"按货名装箱分析"]){
            _dataForPlot = dataForPlot3;
        }else if([graphId isEqualToString:@"按货名拆箱分析"]){
            _dataForPlot = dataForPlot4;
        }
    }
    NSDictionary *dict = [_dataForPlot objectAtIndex:index];
    return [(NSNumber *)[dict objectForKey:@"SUM(CNTR_NUM)"] doubleValue];
}

-(CPTLayer *)dataLabelForPlot:(CPTPlot *)plot recordIndex:(NSUInteger)index{
    if(isSmallView)
        return nil;
    
	CPTTextLayer *newLayer = nil;
    double num = [self doubleForPlot:plot field:CPTBarPlotFieldBarTip recordIndex:index];
    newLayer = [[CPTTextLayer alloc] initWithText:[NSString stringWithFormat:@"%.0f", 
                                                   num] style:[HDSUtil plotTextStyle:10]];
    
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
    adapter2 = [[SBJsonStreamParserAdapter alloc] init];
    adapter2.delegate = self;
    parser2 = [[SBJsonStreamParser alloc] init];
    parser2.delegate = adapter2;
    adapter3 = [[SBJsonStreamParserAdapter alloc] init];
    adapter3.delegate = self;
    parser3 = [[SBJsonStreamParser alloc] init];
    parser3.delegate = adapter3;
    adapter4 = [[SBJsonStreamParserAdapter alloc] init];
    adapter4.delegate = self;
    parser4 = [[SBJsonStreamParser alloc] init];
    parser4.delegate = adapter4;
    adapter5 = [[SBJsonStreamParserAdapter alloc] init];
    adapter5.delegate = self;
    parser5 = [[SBJsonStreamParser alloc] init];
    parser5.delegate = adapter5;
	
    // 表格数据
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ContainerStuffGrid" withExtension:@"json"]]];
        [parser2 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ContainerStuffChart1" withExtension:@"json"]]];
        [parser3 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ContainerStuffChart2" withExtension:@"json"]]];
        [parser4 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ContainerStuffChart3" withExtension:@"json"]]];
        [parser5 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ContainerStuffChart4" withExtension:@"json"]]];
    }else{
        NSString *url;
        NSURLRequest *theRequest;
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CContainerStuff/list.json?yearMonth=%@&corps=%@",qMonth,qCompany];
        theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CContainerStuff/listCorpChart.json?yearMonth=%@&corps=%@&stuffId=1",qMonth,qCompany];
        theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn2 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CContainerStuff/listCorpChart.json?yearMonth=%@&corps=%@&stuffId=0",qMonth,qCompany];
        theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn3 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CContainerStuff/listCargoChart.json?yearMonth=%@&corps=%@&stuffId=1",qMonth,qCompany];
        theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn4 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
        
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CContainerStuff/listCargoChart.json?yearMonth=%@&corps=%@&stuffId=0",qMonth,qCompany];
        theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn5 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }
}

#pragma mark SBJsonStreamParserAdapterDelegate methods
- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
    NSDictionary *data;
    NSMutableDictionary *prop;
    if(parser == parser1){
        HDSTreeNode *node;
        [self.rootArray removeAllObjects];
        for(int i=0; i<array.count; i++){
            data = [array objectAtIndex:i];
            prop = (NSMutableDictionary *)[data objectForKey:@"properties"];
            node = [[HDSTreeNode alloc] initWithProperties:prop parent:nil expanded:YES];
            [self.rootArray addObject:node];
            [self loadChildren:node withData:data];
        }
        [tableView reloadData];
    }else if(parser == parser2){
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:array dataIsTreeNode:false  xLabelKey:@"CNTR_CORP_NAM" yLabelKey:[NSArray arrayWithObjects:@"SUM(CNTR_NUM)",nil] yTitleWidth:0 plotNum:1];
    }else if(parser == parser3){
        [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot2 data:array dataIsTreeNode:false  xLabelKey:@"CNTR_CORP_NAM" yLabelKey:[NSArray arrayWithObjects:@"SUM(CNTR_NUM)",nil] yTitleWidth:0 plotNum:1];
    }else if(parser == parser4){
        [self refreshBarPlotView:plotView3 dataForPlot:dataForPlot3 data:array dataIsTreeNode:false  xLabelKey:@"CARGO_KIND_NAM" yLabelKey:[NSArray arrayWithObjects:@"SUM(CNTR_NUM)",nil] yTitleWidth:0 plotNum:1];
    }else if(parser == parser5){
        [self refreshBarPlotView:plotView4 dataForPlot:dataForPlot4 data:array dataIsTreeNode:false  xLabelKey:@"CARGO_KIND_NAM" yLabelKey:[NSArray arrayWithObjects:@"SUM(CNTR_NUM)",nil] yTitleWidth:0 plotNum:1];
    }
}

-(NSString *)transformXLabel:(NSString *)xLabel{
    if(xLabel.length>10){
        return [[xLabel substringWithRange:NSMakeRange(0, 10)] stringByAppendingString:@"..."];
    }
    return xLabel;
}

- (void)parser:(SBJsonStreamParser *)parser foundObject:(NSDictionary *)dict {
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    //	NSLog(@"Connection didReceiveData of length: %u", data.length);
    SBJsonStreamParser *parser ; 
    if(connection == conn1){
        parser = parser1;
    }else if(connection == conn2){
        parser = parser2;
    }else if(connection == conn3){
        parser = parser3;
    }else if(connection == conn4){
        parser = parser4;
    }else if(connection == conn5){
        parser = parser5;
    }
    SBJsonStreamParserStatus status = [parser parse:data];
	if (status == SBJsonStreamParserError) {
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"拆装箱作业统计");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"拆装箱作业统计");
	} else{

    }
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    [monthBtn setTitle:[NSString stringWithFormat:@"   %d年%2d月",[_dates year] ,[_dates month]] forState:UIControlStateNormal];
    qMonth = [NSString stringWithFormat:@"%d%02d",[_dates year] ,[_dates month]];
}

- (IBAction)changeMonthTaped:(UIButton *)sender {
    if(datePopover == nil){
        HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearMonthPickerFormat popupBtn:sender];
        picker.delegate = self;
        datePopover= [[UIPopoverController alloc] initWithContentViewController:picker];
        datePopover.popoverContentSize = picker.view.frame.size;
        datePopover.delegate = picker;
    }
    [datePopover presentPopoverFromRect:monthBtn.frame inView:[monthBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

@end
