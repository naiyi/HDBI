//
//  HDS_C_PortContainer.m
//  HDBI
//
//  Created by 毅 张 on 12-8-15.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//
#define L_Width 663
#define P_Width 728

#define COL0_WIDTH 160.0f
#define OTHER_COL_WIDTH 60.0f
#define COL_HEIGHT 20.0f
#define SMALL_COL0_WIDTH 100.0f
#define SMALL_OTHER_COL_WIDTH 40.0f
#define SMALL_COL_HEIGHT 15.0f

#import "HDS_C_PortContainer.h"
#import "UIView+AddLine.h"
#import "HDSGradientView.h"

@implementation HDS_C_PortContainer{
    
    CPTGraphHostingView *plotView1;
    CPTGraphHostingView *plotView2;
    CPTGraphHostingView *plotView3;
    CPTGraphHostingView *plotView4;
    
    UIPopoverController *datePopover;
    
    NSURLConnection *conn1; // 表格数据
    SBJsonStreamParser *parser1;
    SBJsonStreamParserAdapter *adapter1;
    
    NSString *qDate;
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

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification]; 
    
    [self refreshPlotTheme:plotView1];
    [self refreshPlotTheme:plotView2];
    [self refreshPlotTheme:plotView3];
    [self refreshPlotTheme:plotView4];
}

- (void)fillConditionView:(UIView *)view{
    [super fillConditionView:view corpLine:0];
}

- (void)viewDidLoad{
    [super viewDidLoad];
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer,plotContainer1,plotContainer2,plotContainer3,plotContainer4, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"在场箱查询";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
    }

    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    
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
    [self addBarPlotView:plotView1 toContainer:plotContainer1 title:@"在场箱堆存情况(内外贸)" xTitle:nil yTitle:nil plotNum:2 identifier:[NSArray arrayWithObjects:@"内贸",@"外贸",nil] useLegend:YES useLegendIcon:NO];
    
    plotView2 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView2 toContainer:plotContainer2 title:@"在场箱堆存情况(尺寸)" xTitle:nil yTitle:nil plotNum:3 identifier:[NSArray arrayWithObjects:@"20尺",@"40尺",@"45尺",nil] useLegend:YES useLegendIcon:NO];
    
    plotView3 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView3 toContainer:plotContainer3 title:@"在场箱堆存情况(空重)" xTitle:nil yTitle:nil plotNum:2 identifier:[NSArray arrayWithObjects:@"空箱",@"重箱",nil] useLegend:YES useLegendIcon:NO];
    
    plotView4 = [[CPTGraphHostingView alloc] initWithFrame:CGRectZero];
    [self addBarPlotView:plotView4 toContainer:plotContainer4 title:@"在场箱堆存情况(合计)" xTitle:nil yTitle:nil plotNum:1 identifier:[NSArray arrayWithObjects:@"箱量",nil] useLegend:YES useLegendIcon:NO];

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
    return 14;
}

- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
    return 2;
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
    
    CGRect rects[22] = {  
        CGRectMake(1, 0, col0Width, colHeight*3),// 公司
        CGRectMake(1+col0Width, 0, otherColWidth, colHeight*3),//合计箱量
        
        CGRectMake(1, 0, otherColWidth*7, colHeight),//内贸
        CGRectMake(1, colHeight, otherColWidth*3, colHeight),//空箱
        CGRectMake(1+otherColWidth*3,colHeight, otherColWidth*3, colHeight),//重箱
        CGRectMake(1+otherColWidth*6,colHeight, otherColWidth, colHeight*2),//合计
        CGRectMake(1, colHeight*2, otherColWidth, colHeight),//20
        CGRectMake(1+otherColWidth, colHeight*2, otherColWidth, colHeight),//40
        CGRectMake(1+otherColWidth*2, colHeight*2, otherColWidth, colHeight),//45
        CGRectMake(1+otherColWidth*3, colHeight*2, otherColWidth, colHeight),//20
        CGRectMake(1+otherColWidth*4, colHeight*2, otherColWidth, colHeight),//40
        CGRectMake(1+otherColWidth*5, colHeight*2, otherColWidth, colHeight),//45
        
        CGRectMake(1+otherColWidth*7, 0, otherColWidth*7, colHeight),//外贸
        CGRectMake(1+otherColWidth*7, colHeight, otherColWidth*3, colHeight),//空箱
        CGRectMake(1+otherColWidth*10,colHeight, otherColWidth*3, colHeight),//重箱
        CGRectMake(1+otherColWidth*13,colHeight, otherColWidth, colHeight*2),//合计
        CGRectMake(1+otherColWidth*7, colHeight*2, otherColWidth, colHeight),//20
        CGRectMake(1+otherColWidth*8, colHeight*2, otherColWidth, colHeight),//40
        CGRectMake(1+otherColWidth*9, colHeight*2, otherColWidth, colHeight),//45
        CGRectMake(1+otherColWidth*10, colHeight*2, otherColWidth, colHeight),//20
        CGRectMake(1+otherColWidth*11, colHeight*2, otherColWidth, colHeight),//40
        CGRectMake(1+otherColWidth*12, colHeight*2, otherColWidth, colHeight),//45
    };
    NSArray *titles = [NSArray arrayWithObjects:
                       @"公司",@"箱量\n合计",@"内贸",@"空箱",@"重箱",@"内贸\n合计",@"20",
                       @"40",@"45",@"20",@"40",@"45",@"外贸",@"空箱",@"重箱",@"外贸\n合计",@"20",
                       @"40",@"45",@"20",@"40",@"45",nil];
    UILabel *cell;
    int beginIndex,endIndex;
    if(tableViewIndex == 0){
        beginIndex = 0;
        endIndex = 2;
    }else{
        beginIndex = 2;
        endIndex = 22;
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
            [header addVerticalLineWithWidth:1 color:[HDSUtil plotBorderColor] atX:col0Width+otherColWidth];
        }
    }
    return header;
}

- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"corp";
        case 1: return @"total";
        case 2: return @"ne20";
        case 3: return @"ne40";
        case 4: return @"ne45";
        case 5: return @"nf20";
        case 6: return @"nf40";
        case 7: return @"nf45";
        case 8: return @"ntotal";
        case 9: return @"we20";
        case 10: return @"we40";
        case 11: return @"we45";
        case 12: return @"wf20";
        case 13: return @"wf40";
        case 14: return @"wf45";
        case 15: return @"wtotal";
        default:return @"";
    }
}

#pragma mark -
#pragma mark Plot Data Source Methods
//-(NSString *)legendTitleForBarPlot:(CPTBarPlot *)barPlot recordIndex:(NSUInteger)index{
//    return [NSString stringWithFormat:@"Bar %lu", (unsigned long)(index + 1)];
//}

-(NSUInteger)numberOfRecordsForPlot:(CPTPlot *)plot{
    return [dataForPlot1 count];
}

-(double)doubleForPlot:(CPTPlot *)plot field:(NSUInteger)fieldEnum recordIndex:(NSUInteger)index{
    NSString *graphId = (NSString *)plot.graph.identifier;
    NSMutableArray *plotProps = [[NSMutableArray alloc] init];
    if([graphId hasSuffix:@"(内外贸)"]){
        if ( [(NSString *)plot.identifier isEqualToString:@"内贸"] ) {
            [plotProps addObject:@"ntotal"];
        }else{
            [plotProps addObject:@"wtotal"];
        }
    }else if([graphId hasSuffix:@"(尺寸)"]){
        if ( [(NSString *)plot.identifier isEqualToString:@"20尺"] ) {
            [plotProps addObject:@"_20"];
        }else if( [(NSString *)plot.identifier isEqualToString:@"40尺"] ) {
            [plotProps addObject:@"_40"];
        }else if( [(NSString *)plot.identifier isEqualToString:@"45尺"] ) {
            [plotProps addObject:@"_45"];
        }
    }else if([graphId hasSuffix:@"(空重)"]){
        if ( [(NSString *)plot.identifier isEqualToString:@"空箱"] ) {
            [plotProps addObject:@"emp"];
        }else if( [(NSString *)plot.identifier isEqualToString:@"重箱"] ) {
            [plotProps addObject:@"ful"];
        }
    }else if([graphId hasSuffix:@"(合计)"]){
        [plotProps addObject:@"total"];
    }
    if(fieldEnum == CPTBarPlotFieldBarLocation ){
        return index+1;
    }else{  //CPTBarPlotFieldBarTip
        // dataForPlot1 - dataForPlot4 内容一样，不需要区分
        NSDictionary *dict = [(HDSTreeNode *)[dataForPlot1 objectAtIndex:index] properties];
        double result = 0;
        for(int i=0; i<plotProps.count; i++){
            result += [(NSNumber *)[dict objectForKey:[plotProps objectAtIndex:i]] doubleValue];
        }
        return result;
    }
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

#pragma mark - 数据读取相关
- (void)loadData {
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
	
    // 表格数据
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_PortContainer" withExtension:@"json"]]];
    }else{
        NSString *url;
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CPortContainer/list.json?corps=%@",qCompany];
        
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
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
            double _20 = [(NSNumber *)[prop objectForKey:@"ne20"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"nf20"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"we20"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"wf20"] doubleValue];
            [prop setObject:[NSNumber numberWithDouble:_20] forKey:@"_20"];
            
            double _40 = [(NSNumber *)[prop objectForKey:@"ne40"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"nf40"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"we40"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"wf40"] doubleValue];
            [prop setObject:[NSNumber numberWithDouble:_40] forKey:@"_40"];
            
            double _45 = [(NSNumber *)[prop objectForKey:@"ne45"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"nf45"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"we45"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"wf45"] doubleValue];
            [prop setObject:[NSNumber numberWithDouble:_45] forKey:@"_45"];
            
            double emp = [(NSNumber *)[prop objectForKey:@"ne20"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"ne40"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"ne45"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"we20"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"we40"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"we45"] doubleValue];
            [prop setObject:[NSNumber numberWithDouble:emp] forKey:@"emp"];
            
            double ful = [(NSNumber *)[prop objectForKey:@"nf20"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"nf40"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"nf45"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"wf20"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"wf40"] doubleValue]
                        +[(NSNumber *)[prop objectForKey:@"wf45"] doubleValue];
            [prop setObject:[NSNumber numberWithDouble:ful] forKey:@"ful"];
            
            node = [[HDSTreeNode alloc] initWithProperties:prop parent:nil expanded:YES];
            [self.rootArray addObject:node];
        }
        [tableView reloadData];
        
        [self refreshBarPlotView:plotView1 dataForPlot:dataForPlot1 data:self.rootArray dataIsTreeNode:true  xLabelKey:@"corp" yLabelKey:[NSArray arrayWithObjects:@"ntotal",@"wtotal",nil] yTitleWidth:0 plotNum:2];
        [self refreshBarPlotView:plotView2 dataForPlot:dataForPlot2 data:self.rootArray dataIsTreeNode:true  xLabelKey:@"corp" yLabelKey:[NSArray arrayWithObjects:@"_20",@"_40",@"_45",nil] yTitleWidth:0 plotNum:3];
        [self refreshBarPlotView:plotView3 dataForPlot:dataForPlot3 data:self.rootArray dataIsTreeNode:true  xLabelKey:@"corp" yLabelKey:[NSArray arrayWithObjects:@"emp",@"ful",nil] yTitleWidth:0 plotNum:2];
        [self refreshBarPlotView:plotView4 dataForPlot:dataForPlot4 data:self.rootArray dataIsTreeNode:true  xLabelKey:@"corp" yLabelKey:[NSArray arrayWithObjects:@"total",nil] yTitleWidth:0 plotNum:1];
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
    }
    SBJsonStreamParserStatus status = [parser parse:data];
	if (status == SBJsonStreamParserError) {
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"在场箱查询");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"在场箱查询");
	} else{
//        NSLog(@"Parser over.");
    }
}

@end
