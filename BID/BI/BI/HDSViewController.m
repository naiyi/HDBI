//
//  HDSViewController.m
//  HDBI
//
//  Created by 毅 张 on 12-7-16.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#define Animation_Time 1

#import "HDSViewController.h"

@interface HDSViewController (){
    // 保存每个图表刷新时y轴left padding的变化量 key:图表名
    NSMutableDictionary *plotLeftPaddingDict;
}

@end

@implementation HDSViewController

@synthesize tableContainer;
@synthesize popPageBtn;
@synthesize refreshBtn;
@synthesize lastPageBtn;
@synthesize nextPageBtn;
@synthesize titleLabel;
@synthesize chooseCompBtn;
@synthesize companyLabel;
@synthesize chooseCargoBtn;
@synthesize cargoLabel;
@synthesize rootArray;

@synthesize inHomePage;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        [[NSNotificationCenter defaultCenter] addObserver:self 
             selector:@selector(updateTheme:) name:@"themeNotification" object:nil];
        if([nibNameOrNil hasSuffix:@"-small"]){
            isSmallView = true;
        }
        plotLeftPaddingDict = [[NSMutableDictionary alloc] init];
        fps = 20;
        isLog = false;
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(isSmallView){
        isShowingCondition = false;
        [popPageBtn addTarget:self action:@selector(showConditionPopup) forControlEvents:UIControlEventTouchUpInside];
        [refreshBtn addTarget:self action:@selector(loadData) forControlEvents:UIControlEventTouchUpInside];
    }
}

- (void)showConditionPopup{
    isShowingCondition = !isShowingCondition;

    ((UIView *)[pageViews objectAtIndex:currentViewIndex]).hidden = isShowingCondition;
    pc.hidden = isShowingCondition;
    refreshBtn.enabled = !refreshBtn.enabled;
    lastPageBtn.enabled = !lastPageBtn.enabled;
    nextPageBtn.enabled = !nextPageBtn.enabled;
    conditionPopup.hidden = !isShowingCondition;
    
    CATransition *animation = [CATransition animation];
    animation.delegate = self; 
    animation.duration = Animation_Time;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.removedOnCompletion = YES;
    animation.type = @"cube"; 
    
    if(isShowingCondition){
        popPageBtn.layer.transform = CATransform3DRotate(CATransform3DIdentity, M_PI, 0, 0, 1.0);
        animation.subtype = kCATransitionFromTop;
    }else {
        popPageBtn.layer.transform = CATransform3DIdentity;
        animation.subtype = kCATransitionFromBottom;
    }
    [self.view.layer addAnimation:animation forKey:@"animation"];
}

- (void)createConditionView{
    conditionPopup = [[UIView alloc] initWithFrame:CGRectMake(5, 35, 310, 175-3)];
    conditionPopup.backgroundColor = [UIColor colorWithRed:0.15 green:0.15 blue:0.15 alpha:0.7];
    conditionPopup.layer.cornerRadius = 5;
    conditionPopup.hidden = true;
    [self fillConditionView:conditionPopup];
    [self.view addSubview:conditionPopup];
}

- (void)fillConditionView:(UIView *)view{
    [self fillConditionView:view corpLine:1];
}

- (void)fillConditionView:(UIView *)view corpLine:(NSInteger)line{
    // 公司
    chooseCompBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    chooseCompBtn.frame = CGRectMake(20,10+40*line,100,31);
    chooseCompBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    chooseCompBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [chooseCompBtn setTitle:@"   选择公司" forState:UIControlStateNormal];
    [chooseCompBtn addTarget:self action:@selector(chooseCompBtnTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:chooseCompBtn];
    // 公司label
    companyLabel =[[UILabel alloc] initWithFrame:CGRectMake(128, 10+40*line, 170, 31)];
    companyLabel.font = [UIFont fontWithName:@"Heiti SC" size:SmallViewConditionFontSize];
    companyLabel.lineBreakMode = UILineBreakModeTailTruncation;
    companyLabel.textAlignment = UITextAlignmentLeft;
    companyLabel.numberOfLines = 1;
    companyLabel.backgroundColor = [UIColor clearColor];
    [view addSubview:companyLabel];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
	return YES;
}

- (void)viewDidUnload
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"themeNotification" object:nil];
    [self setTableContainer:nil];
    [self setPopPageBtn:nil];
    [self setRefreshBtn:nil];
    [self setLastPageBtn:nil];
    [self setNextPageBtn:nil];
    [self setTitleLabel:nil];
    [self setChooseCompBtn:nil];
    [self setCompanyLabel:nil];
    [self setChooseCargoBtn:nil];
    [self setCargoLabel:nil];
    [super viewDidUnload];
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

-(void)updateTheme:(NSNotification*)notification{
//    NSLog(@"%@ should be implement in sub class",NSStringFromSelector(_cmd));
//    NSLog(@"%s", __PRETTY_FUNCTION__);
    HDSSkinType  skinType = [HDSUtil skinType];
    if(!isSmallView){   
        if(skinType == HDSSkinBlue){
            self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
            tableContainer.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.8];
        }else{
            self.view.backgroundColor = [UIColor colorWithPatternImage:[HDSUtil loadImageSkin:HDSSkinBlack imageName:@"index_bg_2048_right.png"]];
            tableContainer.backgroundColor = [UIColor clearColor];
        }
    }else{
        // 1.使用渐变背景或者2.纯色背景  
        [((HDSGradientView *)self.view) setupSmallViewGradientLayer];   //1
        self.view.layer.borderColor = [HDSUtil plotBorderColor].CGColor;//1
        self.view.layer.borderWidth = 1;                                //1
        if(skinType == HDSSkinBlue){
//            self.view.backgroundColor = [UIColor whiteColor];         //2
            [titleLabel setTextColor:[UIColor blackColor]];
        }else{
//            self.view.backgroundColor = [UIColor colorWithWhite:1.0 alpha:0.3];//2
            [titleLabel setTextColor:[UIColor colorWithWhite:1 alpha:0.8]];
        }
        [popPageBtn setImage:[HDSUtil loadImageSkin:skinType imageName:@"tile_popup.png"] forState:UIControlStateNormal];
        [refreshBtn setImage:[HDSUtil loadImageSkin:skinType imageName:@"tile_refresh.png"] forState:UIControlStateNormal];
        [lastPageBtn setImage:[HDSUtil loadImageSkin:skinType imageName:@"tile_arrowleft.png"] forState:UIControlStateNormal];
        [nextPageBtn setImage:[HDSUtil loadImageSkin:skinType imageName:@"tile_arrowright.png"] forState:UIControlStateNormal];
        [popPageBtn setAlpha:0.8];
        [refreshBtn setAlpha:0.8];
        [lastPageBtn setAlpha:0.8];
        [nextPageBtn setAlpha:0.8];
    }
    
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    companyLabel.textColor = color;
    cargoLabel.textColor = color;
    [chooseCompBtn setTitleColor:color forState:UIControlStateNormal];
    [chooseCargoBtn setTitleColor:color forState:UIControlStateNormal];
    
    [chooseCompBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal.png"] forState:UIControlStateNormal];
    [chooseCompBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight.png"] forState:UIControlStateHighlighted];
    [chooseCargoBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal.png"] forState:UIControlStateNormal];
    [chooseCargoBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight.png"] forState:UIControlStateHighlighted];
    [tableView updateTheme];
}

- (void)refreshPlotTheme:(CPTGraphHostingView *)plotView{
    plotView.layer.borderColor = [HDSUtil plotBorderColor].CGColor;
    CPTGraph *graph = plotView.hostedGraph;
    NSArray *axes = graph.axisSet.axes;
    for(CPTXYAxis *axis in axes){
        [HDSUtil setAxis:axis titleFontSize:0 labelFontSize:isSmallView?10.0f:12.0f];
    }
    graph.titleTextStyle = [HDSUtil plotTextStyle:isSmallView?14.0f:16.0f];
    graph.fill = [HDSUtil plotBackgroundFill];
    if(graph.legend != nil){
        graph.legend.textStyle = [HDSUtil plotTextStyle:isSmallView?12.0f:14.0f];
        [graph.legend setNeedsDisplay];
    }
    UIButton *legendSwitch = (UIButton *)[plotView viewWithTag:Legend_Switch_Tag];
    [legendSwitch setImage:[HDSUtil loadImageSkin:[HDSUtil skinType] imageName:@"tile_legend.png"] forState:UIControlStateNormal];
    for(CPTPlot *plot in [graph allPlots])  [plot reloadData];
}

- (IBAction)pageButtonTaped:(UIButton *)sender{
    CATransition *animation = [CATransition animation];
    animation.delegate = self; 
    animation.duration = Animation_Time;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.removedOnCompletion = YES;
    // 设定动画类型
    // @"cube" 立方体  @"oglFlip" 翻转   @"pageCurl" 翻页  @"pageUnCurl" 反翻页
    if(sender == nextPageBtn){
        if(currentViewIndex == pageViews.count-1){
            currentViewIndex= 0;
        }else{
            currentViewIndex++;
        }
        [self smallViewChangeToIndex:currentViewIndex];
        animation.type = @"cube"; 
        animation.subtype = kCATransitionFromRight;
        [self.view.layer addAnimation:animation forKey:@"animation"];
    }
    if(sender == lastPageBtn){
        if(currentViewIndex == 0){
            currentViewIndex= pageViews.count-1;
        }else{
            currentViewIndex--;
        }
        [self smallViewChangeToIndex:currentViewIndex];
        animation.type = @"cube"; 
        animation.subtype = kCATransitionFromLeft;
        [self.view.layer addAnimation:animation forKey:@"animation"];
    }
    pc.currentPage = currentViewIndex;
}

- (IBAction)chooseCompBtnTaped:(UIButton *)sender{
    if(compPopController == nil){
        HDSCompanyViewController *companyVC = [[HDSCompanyViewController alloc] init];
        companyVC.delegate = self;
        compPopController = [[UIPopoverController alloc] initWithContentViewController:companyVC];
        compPopController.popoverContentSize = CGSizeMake(200, 300); 
        compPopController.delegate = companyVC;
    }
    [compPopController presentPopoverFromRect:sender.frame inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (IBAction)chooseCargoTaped:(UIButton *)sender {
    if(cargoPopController == nil){
        HDSCargoViewController *cargoVC = [[HDSCargoViewController alloc] init];
        cargoVC.delegate = self; // 刷新数据回调
        cargoPopController = [[UIPopoverController alloc] initWithContentViewController:cargoVC];
        cargoPopController.popoverContentSize = CGSizeMake(200, 300); 
        cargoPopController.delegate = cargoVC;
    }
    [cargoPopController presentPopoverFromRect:sender.frame inView:[sender superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)refreshByComps:(NSArray *)comps{
    companyLabel.text = @"";
    qCompany = @"";
    for(int i=0;i<comps.count;i++){
        NSString *companyCode = [[comps objectAtIndex:i] objectForKey:@"code"];
        NSString *companyName = [[comps objectAtIndex:i] objectForKey:@"name"];
        companyLabel.text = [companyLabel.text stringByAppendingFormat:@"%@  ",companyName];
        qCompany = [qCompany stringByAppendingFormat:@"'%@'",companyCode];
        if(i != comps.count-1)
            qCompany = [qCompany stringByAppendingString:@","];
    }
}

- (void) refreshByCargos:(NSArray *) cargos{
    cargoLabel.text = @"";
    qCargo = @"";
    for(int i=0;i<cargos.count;i++){
        NSString *cargoCode = [[cargos objectAtIndex:i] objectForKey:@"code"];
        NSString *cargoName = [[cargos objectAtIndex:i] objectForKey:@"name"];
        cargoLabel.text = [cargoLabel.text stringByAppendingFormat:@"%@  ",cargoName];
        qCargo = [qCargo stringByAppendingFormat:@"'%@'",cargoCode];
        if(i != cargos.count-1)
            qCargo = [qCargo stringByAppendingString:@","];
    }
}

- (void)loadDataByDate{
    [self loadData];
}

- (void)loadDataByComp{
    [self loadData];
}

- (void)loadDataByCargos{
    [self loadData];
}

- (void)loadData{
    NSLog(@"%@ should be implement in sub class",NSStringFromSelector(_cmd));
}

- (void)smallViewChangeToIndex:(NSInteger)index{
    for(int i=0;i<pageViews.count;i++){
        if (i != index) {
            [(UIView *)[pageViews objectAtIndex:i] setHidden:YES];
        }else{
            [(UIView *)[pageViews objectAtIndex:i] setHidden:NO];
        }
    }
}

// 在每个主页视图的下面增加pageControl提示
- (void)insertPageControlToSmallView{
    for(int i=0;i<pageViews.count;i++){
        UIView *v = (UIView *)[pageViews objectAtIndex:i];
        CGRect f = v.frame;
        f.size.height -= 3;
        v.frame = f;
    }
    pc = [[UIPageControl alloc] initWithFrame:CGRectMake(0, 209, 320, 5)];
    pc.alpha = 0.7;
    pc.numberOfPages = pageViews.count;
    [self.view addSubview:pc];
}

- (NSMutableArray *)rootArrayForTableView:(HDSTableView *)tableView {
    return rootArray;
}

- (CGFloat)heightForHeaderCellOfTableView:(HDSTableView *)tableView{
    if(isSmallView){
        return Table_Header_Height_Small;
    }
    return Table_Header_Height;
}

- (NSString *)tableView:(HDSTableView *)tableView propertyHeaderForColumn:(NSInteger)col{
    return [headerNames objectAtIndex:col];
}

- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column{
    NSLog(@"%@ should be implement in sub class",NSStringFromSelector(_cmd));
    return 0;
}


- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    NSLog(@"%@ should be implement in sub class",NSStringFromSelector(_cmd));
    return @"";
}
- (NSInteger)tableView:(HDSTableView *)tableView canBeExpandedColumnIndexAtNode:(HDSTreeNode *)node{
//    NSLog(@"%@ should be implement in sub class",NSStringFromSelector(_cmd));
    return -1;
}

- (CGFloat)tableView:(HDSTableView *)_tableView heightForCellAtNode:(HDSTreeNode *)node column:(NSInteger)col{ 
    // 根据文字大小调整行高,有时汉字高度计算会有问题(比如列宽240,30个汉字)
    NSString *str = [HDSUtil convertDataToString:[[node properties] objectForKey:[self tableView:_tableView propertyNameForColumn:col node:node]] label:nil];
    CGFloat width = [self tableView:_tableView widthForColumn:col]-HDSTable_TextIndent;
    if(node.isDirectory && col == [self tableView:_tableView canBeExpandedColumnIndexAtNode:node]){
        width -= HDSTable_TextIndent+12.0f;
    }
    UIFont *font = isSmallView?[HDSUtil getFontBySize:HDSFontSizeVerySmall]:[HDSUtil getFontBySize:HDSFontSizeNormal];
    CGSize s = [str sizeWithFont:font constrainedToSize:CGSizeMake(width, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
    return s.height + (isSmallView?6.0f:8.0f);
}

#pragma mark- NSURLConnectionDelegate methods
// 网络请求发送测试回调
//- (BOOL)connectionShouldUseCredentialStorage:(NSURLConnection *)connection{
//    NSLog(@"1");
//    return true;
//}
//- (void)connection:(NSURLConnection *)connection willSendRequestForAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge{
//    NSLog(@"2");
//}
//- (NSURLRequest *)connection:(NSURLConnection *)connection willSendRequest:(NSURLRequest *)request redirectResponse:(NSURLResponse *)response{
//    NSLog(@"3");
//    return request;
//}
//
//- (NSInputStream *)connection:(NSURLConnection *)connection needNewBodyStream:(NSURLRequest *)request{
//    NSLog(@"4");
//    return nil;
//}
//
//- (void)connection:(NSURLConnection *)connection   didSendBodyData:(NSInteger)bytesWritten
// totalBytesWritten:(NSInteger)totalBytesWritten
//totalBytesExpectedToWrite:(NSInteger)totalBytesExpectedToWrite{
//    NSLog(@"5");
//}
//
//- (NSCachedURLResponse *)connection:(NSURLConnection *)connection willCacheResponse:(NSCachedURLResponse *)cachedResponse{
//    NSLog(@"6");
//    return cachedResponse;
//}
//
//- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
//    NSLog(@"Connection didReceiveResponse: %@ - %@", response, [response MIMEType]);
//}
//
//- (void)connection:(NSURLConnection *)connection didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge {
//    NSLog(@"Connection didReceiveAuthenticationChallenge: %@", challenge);
////    NSURLCredential *credential = [NSURLCredential credentionalWithUser:username.text password:password.text persistence:NSURLCredentialPersistenceForSession];
////    [[challenge sender] useCredential:credential forAuthenticationChallenge:challenge];
//}
//
//- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
//    NSLog(@"Connection finishLoading!");
//}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error {
    NSLog(@"Connection failed! Error - %@ %@",[error localizedDescription],[[error userInfo] objectForKey:NSURLErrorFailingURLStringErrorKey]);
}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
    NSLog(@"%@ should be implement in subclass!",NSStringFromSelector(_cmd));
    return 0;
}

- (void) loadChildren:(HDSTreeNode *)node withData:(NSDictionary *)data{
    [self loadChildren:node withData:data expand:false];
}

// expand：二级以下的树节点是否展开
- (void) loadChildren:(HDSTreeNode *)node withData:(NSDictionary *)data expand:(BOOL)expand{
    NSArray *children = (NSArray *)[data objectForKey:@"children"];
    NSDictionary *_data;
    HDSTreeNode *_node;
    for(int i=0;i<children.count;i++){
        _data = [children objectAtIndex:i];
        _node = [[HDSTreeNode alloc] initWithProperties:[_data objectForKey:@"properties"] parent:node expanded:expand];
        [[node children] addObject:_node];
        [self loadChildren:_node withData:_data expand:expand];
    }
}

-(void) addPlotType:(Class)plotClass PlotView:(CPTGraphHostingView *)_plotView toContainer:(UIView *)container title:(NSString *)title xTitle:(NSString *)xTitle yTitle:(NSString *)yTitle plotNum:(NSInteger)plotNum identifier:(NSArray *)identifier useLegend:(BOOL)useLegend useLegendIcon:(BOOL)useLegendIcon{
    _plotView.frame = container.bounds;
    _plotView.autoresizesSubviews = false;
    _plotView.autoresizingMask =  UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _plotView.layer.borderColor = [HDSUtil plotBorderColor].CGColor;
    _plotView.layer.borderWidth = 1.0f;
    _plotView.layer.cornerRadius = isSmallView? Table_Corner_Small:Table_Corner;
    _plotView.layer.masksToBounds = true;
    [container addSubview:_plotView];
    
    CPTXYGraph *graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
	[graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
	_plotView.hostedGraph = graph;
    
    [HDSUtil setTitle:title forGraph:graph withFontSize:isSmallView?14.0f:16.0f];
    [HDSUtil setInnerPaddingTop:6.0 right:15.0 bottom:25.0 left:0.0 forGraph:graph];
    [HDSUtil setPadding:0 forGraph:graph withBounds:_plotView.bounds];
    
	CPTXYPlotSpace *plotSpace = (CPTXYPlotSpace *)graph.defaultPlotSpace;
	CPTXYAxisSet *axisSet = (CPTXYAxisSet *)graph.axisSet;
	CPTXYAxis *x = axisSet.xAxis;
    [HDSUtil setAxis:x majorIntervalLength:1.0 minorTicksPerInterval:0 title:xTitle titleOffset:35 titleFontSize:isSmallView?12.0f:14.0f labelFontSize:isSmallView?10.0f:12.0f ];
    // 自定义坐标轴label
	x.labelingPolicy = CPTAxisLabelingPolicyNone;
    
	CPTXYAxis *y = axisSet.yAxis;
    [HDSUtil setAxis:y majorIntervalLength:0 minorTicksPerInterval:0 title:yTitle titleOffset:35 titleFontSize:isSmallView?12.0f:14.0f labelFontSize:isSmallView?10.0f:12.0f];
    y.orthogonalCoordinateDecimal = CPTDecimalFromCGFloat(0.5);
    NSNumberFormatter *nf = [[NSNumberFormatter alloc] init];
    nf.numberStyle = NSNumberFormatterDecimalStyle;
    y.labelFormatter = nf;
    
    plotSpace.allowsUserInteraction = YES;
    // 使坐标轴固定且图表可以横向拖动
    x.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    y.axisConstraints = [CPTConstraints constraintWithLowerOffset:0.0];
    plotSpace.delegate = [HDSUtil getPlotDelegate];
    
    if(plotClass == [CPTBarPlot class]){
        for(int i=0;i<plotNum;i++){
            CPTBarPlot *barPlot= [CPTBarPlot tubularBarPlotWithColor:[CPTColor clearColor] horizontalBars:NO];
            barPlot.fill	   = [CPTFill fillWithGradient:[HDSUtil barChartGradientAtIndex:i]];
            barPlot.lineStyle  = nil;   //[HDSUtil plotBorderStyle];
            barPlot.baseValue  = CPTDecimalFromString(@"0");
            barPlot.dataSource = self;
            barPlot.barCornerRadius = 0.0f;
            barPlot.identifier = [identifier objectAtIndex:i];
            barPlot.barOffset  = CPTDecimalFromFloat(plotNum==1 ? 0:(i-0.5)*(0.8/plotNum));
            barPlot.barWidth = CPTDecimalFromFloat(0.8/plotNum);
            barPlot.labelOffset = 0.0f;
            [graph addPlot:barPlot toPlotSpace:plotSpace ];
        }
    }else if(plotClass == [CPTScatterPlot class]){
        for(int i=0;i<plotNum;i++){
            CPTScatterPlot *linePlot = [[CPTScatterPlot alloc] init];
            linePlot.identifier = [identifier objectAtIndex:i];
            
            CPTMutableLineStyle *lineStyle = [linePlot.dataLineStyle mutableCopy];
            lineStyle.lineWidth	= 2.0f;
            CPTPlotSymbol *plotSymbol= [CPTPlotSymbol ellipsePlotSymbol];
            plotSymbol.lineStyle	 = nil;
            plotSymbol.size	= CGSizeMake(isSmallView?5.0f:8.0f, isSmallView?5.0f:8.0f);
            
            if(plotNum == 1){   // 单线图在线图下方使用渐变色
                CPTGradient *areaGradient = [CPTGradient gradientWithBeginningColor:[CPTColor colorWithCGColor:[HDSUtil colorFromString:@"042e7d"].CGColor] endingColor:[CPTColor colorWithCGColor:[HDSUtil colorFromString:@"252d3b"].CGColor]];
                areaGradient.angle = -90.0f;
                CPTFill *areaGradientFill = [CPTFill fillWithGradient:areaGradient];
                linePlot.areaFill		 = areaGradientFill;
                linePlot.areaBaseValue = CPTDecimalFromString(@"0");
                lineStyle.lineColor	= [CPTColor colorWithCGColor:[HDSUtil colorFromString:@"006be3"].CGColor];
                plotSymbol.fill		= [CPTFill fillWithColor:[CPTColor colorWithCGColor:[HDSUtil colorFromString:@"006be3"].CGColor]];
            }else{
                lineStyle.lineColor	= [CPTColor colorWithCGColor:[HDSUtil lineChartColorAtIndex:i].CGColor];
                plotSymbol.fill		= [CPTFill fillWithColor:[CPTColor colorWithCGColor:[HDSUtil lineChartPointColorAtIndex:i].CGColor]];
            }
            
            linePlot.dataLineStyle = lineStyle;
            linePlot.plotSymbol = plotSymbol;
            linePlot.dataSource = self;
            
            [graph addPlot:linePlot toPlotSpace:plotSpace ];
        }
    }
    
    if(useLegend){
        // 增加图例,legend必须在plot添加到graph之后调用
        CPTLegend *theLegend = [CPTLegend legendWithGraph:graph];
        theLegend.fill = [CPTFill fillWithColor:[CPTColor clearColor]];
        if(isSmallView){
            if(useLegendIcon){
                UIButton *legendSwitch = [UIButton buttonWithType:UIButtonTypeCustom];
                legendSwitch.tag = Legend_Switch_Tag;
                [legendSwitch setImage:[HDSUtil loadImageSkin:[HDSUtil skinType] imageName:@"tile_legend.png"] forState:UIControlStateNormal];
                legendSwitch.frame = CGRectMake(_plotView.bounds.size.width-29-5, _plotView.bounds.size.height-29-5, 29, 29);
                // 图表内y坐标系相反，需要旋转图例图标
                legendSwitch.layer.transform =CATransform3DRotate(CATransform3DRotate(CATransform3DIdentity, M_PI, 0, 0, 1.0),M_PI, 0, 1.0, 0);
                [legendSwitch addTarget:self action:@selector(showLegend:) forControlEvents:UIControlEventTouchUpInside];
                [_plotView addSubview:legendSwitch];
                theLegend.opacity = 0;
            }
            [HDSUtil setLegend:theLegend withCorner:5.0 swatch:10.0 font:12.0 rowMargin:5.0 numberOfRows:plotNum padding:3.0];
            graph.legendAnchor		 = CPTRectAnchorTopRight;
            graph.legendDisplacement = CGPointMake(-5.0, -5.0);
        }else{
            [HDSUtil setLegend:theLegend withCorner:5.0 swatch:12.0 font:14.0 rowMargin:5.0 numberOfRows:1 padding:5.0];
            graph.legendAnchor		 = CPTRectAnchorTopRight;
            graph.legendDisplacement = CGPointMake(-10.0, 0.0);
        }
        graph.legend = theLegend;
    }
}

-(void) addBarPlotView:(CPTGraphHostingView *)_plotView toContainer:(UIView *)container title:(NSString *)title xTitle:(NSString *)xTitle yTitle:(NSString *)yTitle plotNum:(NSInteger)plotNum identifier:(NSArray *)identifier useLegend:(BOOL)useLegend useLegendIcon:(BOOL)useLegendIcon{
    [self addPlotType:[CPTBarPlot class] PlotView:_plotView toContainer:container title:title xTitle:xTitle yTitle:yTitle plotNum:plotNum identifier:identifier useLegend:useLegend useLegendIcon:useLegendIcon];
}

-(void) addLinePlotView:(CPTGraphHostingView *)_plotView toContainer:(UIView *)container title:(NSString *)title xTitle:(NSString *)xTitle yTitle:(NSString *)yTitle plotNum:(NSInteger)plotNum identifier:(NSArray *)identifier useLegend:(BOOL)useLegend useLegendIcon:(BOOL)useLegendIcon{
    [self addPlotType:[CPTScatterPlot class] PlotView:_plotView toContainer:container title:title xTitle:xTitle yTitle:yTitle plotNum:plotNum identifier:identifier useLegend:useLegend useLegendIcon:useLegendIcon];
}

-(void) addPiePlotView:(CPTGraphHostingView *)_plotView toContainer:(UIView *)container title:(NSString *)title useLegend:(BOOL)useLegend useLegendIcon:(BOOL)useLegendIcon{
    _plotView.frame = container.bounds;
    _plotView.autoresizingMask =  UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _plotView.layer.borderColor = [HDSUtil plotBorderColor].CGColor;
    _plotView.layer.borderWidth = 1.0f;
    _plotView.layer.cornerRadius = isSmallView? Table_Corner_Small:Table_Corner;
    _plotView.layer.masksToBounds = true;
    [container addSubview:_plotView];
    
    CPTXYGraph *graph = [[CPTXYGraph alloc] initWithFrame:CGRectZero];
	[graph applyTheme:[CPTTheme themeNamed:kCPTPlainWhiteTheme]];
	_plotView.hostedGraph = graph;
    
    [HDSUtil setTitle:title forGraph:graph withFontSize:isSmallView?14.0f:16.0f];
    [HDSUtil setInnerPaddingTop:0.0 right:0.0 bottom:0.0 left:0.0 forGraph:graph];
    [HDSUtil setPadding:0 forGraph:graph withBounds:_plotView.bounds];
    
	graph.axisSet = nil;
    
    CPTPieChart *piePlot	= [[CPTPieChart alloc] init];
	piePlot.dataSource		= self;
	piePlot.pieRadius		= MIN(_plotView.bounds.size.width,_plotView.bounds.size.height)/3;
	piePlot.startAngle		= M_PI_4;
	piePlot.sliceDirection	= CPTPieDirectionCounterClockwise;
	piePlot.borderLineStyle = [CPTLineStyle lineStyle];
	piePlot.labelOffset		= 5.0;
    // 无数据的时候也会显示overlayFill，故在每次加载数据后判断再执行该语句
	piePlot.overlayFill		= [CPTFill fillWithGradient:[HDSUtil pieChartOverlay]];
	[graph addPlot:piePlot];
    
    if(useLegend){
        CPTLegend *theLegend = [CPTLegend legendWithGraph:graph];
        theLegend.fill = [CPTFill fillWithColor:[CPTColor clearColor]];
        if(isSmallView){
            if(useLegendIcon){
                UIButton *legendSwitch = [UIButton buttonWithType:UIButtonTypeCustom];
                legendSwitch.tag = Legend_Switch_Tag;
                [legendSwitch setImage:[HDSUtil loadImageSkin:[HDSUtil skinType] imageName:@"tile_legend.png"] forState:UIControlStateNormal];
                legendSwitch.frame = CGRectMake(5, 5, 29, 29);
                // 图表内y坐标系相反，需要旋转图例图标
                legendSwitch.layer.transform =CATransform3DRotate(CATransform3DRotate(CATransform3DIdentity, M_PI, 0, 0, 1.0),M_PI, 0, 1.0, 0);
                [legendSwitch addTarget:self action:@selector(showLegend:) forControlEvents:UIControlEventTouchUpInside];
                [_plotView addSubview:legendSwitch];
                theLegend.opacity = 0;
            }
            [HDSUtil setLegend:theLegend withCorner:5.0 swatch:10.0 font:12.0 rowMargin:5.0 numberOfRows:0 padding:3.0];
            graph.legendAnchor		 = CPTRectAnchorBottomLeft;
            graph.legendDisplacement = CGPointMake(5.0, 5.0);
            graph.legend = theLegend;
        }else{
//            [HDSUtil setLegend:theLegend withCorner:5.0 swatch:12.0 font:14.0 rowMargin:5.0 numberOfRows:0 padding:5.0];
//            graph.legendAnchor		 = CPTRectAnchorBottomLeft;
//            graph.legendDisplacement = CGPointMake(10.0, 0.0);
//            graph.legend = theLegend;
        }
        
    }
}

// 包括barPlot和linePlot
-(void) refreshBarPlotView:(CPTGraphHostingView *)_plotView dataForPlot:(NSMutableArray *)_dataForPlot data:(NSArray *)array dataIsTreeNode:(BOOL)dataIsTreeNode xLabelKey:(NSString *)xLabelKey yLabelKey:(NSArray *)yLabelKey yTitleWidth:(CGFloat)yTitleWidth plotNum:(NSInteger)plotNum{
    
    [_dataForPlot removeAllObjects];
    [_dataForPlot addObjectsFromArray:array];
    NSMutableArray *customLabels = [[NSMutableArray alloc] init];
    CPTAxisLabel *newLabel;
    float maxY = 0.0f;
    float maxX = 0.0f,maxHeight = 0.0f;
    int xAxisMaxCount ;
    CPTXYAxisSet *axisSet = (CPTXYAxisSet *)_plotView.hostedGraph.axisSet;
    CPTXYAxis *x = axisSet.xAxis;
    xAxisMaxCount = [self xAxisMaxCount:plotNum plotView:_plotView];
    
    for (int i=0;i<_dataForPlot.count;i++ ) {
        NSDictionary *_data;
        if(dataIsTreeNode){
            _data = [(HDSTreeNode *)[_dataForPlot objectAtIndex:i] properties];
        }else{
            _data = [_dataForPlot objectAtIndex:i];
        }
        NSString *xLabel = [_data objectForKey:xLabelKey];
        xLabel = [self transformXLabel:xLabel];
        
        if([self xLabelInterval] == 1){
            CGSize s = [xLabel sizeWithFont:[UIFont fontWithName:x.labelTextStyle.fontName size:x.labelTextStyle.fontSize] constrainedToSize:CGSizeMake(MAXFLOAT, 30) lineBreakMode:UILineBreakModeWordWrap];
            maxX = MAX(maxX, s.width);
            maxHeight = MAX(maxHeight, s.height);
        }
        
        if(i%[self xLabelInterval] == 0){
            newLabel = [[CPTAxisLabel alloc] initWithText:xLabel textStyle:x.labelTextStyle];
            newLabel.tickLocation = CPTDecimalFromInt(i+1);
            newLabel.offset		  = x.labelOffset+5.0f;
            [customLabels addObject:newLabel];
        }
        
        for(int j = 0;j<yLabelKey.count; j++){
            NSNumber *y = [_data objectForKey:[yLabelKey objectAtIndex:j] ];
            maxY = MAX(maxY,[y floatValue]);
        }
    }
    // y轴label宽度根据数字长度调节
    CGSize yLabelSize = [[NSString stringWithFormat:@"%.1f",maxY*1.2] sizeWithFont:[UIFont fontWithName:axisSet.yAxis.labelTextStyle.fontName size:axisSet.yAxis.labelTextStyle.fontSize] constrainedToSize:CGSizeMake(MAXFLOAT, 30) lineBreakMode:UILineBreakModeWordWrap];
    axisSet.yAxis.titleOffset = yLabelSize.width +5.0f/*tick宽度*//*+10.0ftitle与label的空白*/;
    _plotView.hostedGraph.plotAreaFrame.paddingLeft = axisSet.yAxis.titleOffset+yTitleWidth/*title宽度*/;
    
    // 计算xLabel倾斜角度和bottom padding  xLabelInteval != 1的情况下需要自己处理来保证label长度不重叠
    if([self xLabelInterval] == 1){
        // 计算跟上次的偏移量
        NSNumber *lastNum = [plotLeftPaddingDict objectForKey:_plotView.hostedGraph.identifier];
        float lastFloat ;
        if(lastNum == nil){
            [plotLeftPaddingDict setObject:[NSNumber numberWithInt:0] forKey:_plotView.hostedGraph.identifier];
            lastFloat = 0;
        }else{
            lastFloat = [lastNum floatValue];
        }
        float dFloat = _plotView.hostedGraph.plotAreaFrame.paddingLeft - lastFloat;
        [plotLeftPaddingDict setObject:[NSNumber numberWithInt:_plotView.hostedGraph.plotAreaFrame.paddingLeft] forKey:_plotView.hostedGraph.identifier];
        
        // 实际长度为当前frame.width - 本次与上次的偏移量之差
        float plotWidth = _plotView.hostedGraph.plotAreaFrame.plotArea.frame.size.width ;
        if(plotWidth == 0){
            plotWidth = _plotView.hostedGraph.bounds.size.width - 50;
        }else{
            plotWidth -= dFloat;
        }
        float perBarWidth = plotWidth/MIN(_dataForPlot.count,xAxisMaxCount);
        if(maxX>perBarWidth){
            float radian = acosf(perBarWidth/maxX)/2;
            for(newLabel in customLabels){
                newLabel.rotation = radian;
            }
            _plotView.hostedGraph.plotAreaFrame.paddingBottom = maxX * sinf(radian)+maxHeight;
        }else{
            _plotView.hostedGraph.plotAreaFrame.paddingBottom = 25.0f;
        }
    }
    
    x.axisLabels = [NSSet setWithArray:customLabels];
    
    // 根据bar数量调整bar的宽度和偏移
    for(int i=0;i<plotNum;i++){
        CPTPlot *plot = [_plotView.hostedGraph plotAtIndex:i];
        if([plot isKindOfClass:[CPTBarPlot class]]){
            ((CPTBarPlot *)plot).barWidth = CPTDecimalFromFloat(0.8/plotNum*MIN(_dataForPlot.count,xAxisMaxCount)/xAxisMaxCount);
            ((CPTBarPlot *)plot).barOffset = plotNum==1?CPTDecimalFromInt(0) : CPTDecimalFromFloat((i-0.5)*(0.8/plotNum)*MIN(_dataForPlot.count,xAxisMaxCount)/xAxisMaxCount);
        }
    }
    ((CPTXYPlotSpace *)[_plotView.hostedGraph plotSpaceAtIndex:0]).xRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.5) length:CPTDecimalFromInteger(MIN(_dataForPlot.count,xAxisMaxCount)  ) ];
    ((CPTXYPlotSpace *)[_plotView.hostedGraph plotSpaceAtIndex:0]).yRange = [CPTPlotRange plotRangeWithLocation:CPTDecimalFromFloat(0.0) length:CPTDecimalFromFloat(maxY*1.2)];
    
    
    [_plotView.hostedGraph reloadData];
    
    for(int i=0;i<plotNum;i++){
        CPTPlot *plot = [_plotView.hostedGraph plotAtIndex:i];
        if([plot isKindOfClass:[CPTBarPlot class]] || (plotNum==1 && [plot isKindOfClass:[CPTScatterPlot class]]) ){
            [HDSUtil setAnimation:@"transform.scale.y" toLayer:plot fromValue:0.1 toValue:1 forKey:@"barScaleY"];
        }else if([plot isKindOfClass:[CPTScatterPlot class]]){
            [plot deleteDataInIndexRange:NSMakeRange(0, pointCount)];
        }
    }
    
}

-(NSString *)transformXLabel:(NSString *)xLabel{
//    if(xLabel.length>10){
//        return [[xLabel substringWithRange:NSMakeRange(0, 10)] stringByAppendingString:@"..."];
//    }
    return xLabel;
}

-(NSInteger)xLabelInterval{
    return 1;
}

-(NSInteger)xAxisMaxCount:(NSInteger)plotNum plotView:(CPTGraphHostingView *)_plotView{
    if(isSmallView){
        return 8/plotNum+2;
    }else{
        return 10/plotNum+5;
    }
}

@end
