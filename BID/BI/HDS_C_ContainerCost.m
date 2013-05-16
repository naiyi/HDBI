//
//  HDS_C_ContainerCost.m
//  HDBI
//
//  Created by 毅 张 on 12-9-11.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_C_ContainerCost.h"

@implementation HDS_C_ContainerCost{
    
    UIPopoverController *yearPopover;
    
    NSURLConnection *conn1; // 表格数据
    SBJsonStreamParser *parser1;
    SBJsonStreamParserAdapter *adapter1;
    
    NSString *qYear;
}

@synthesize yearBtn;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification];
    HDSSkinType skinType = [HDSUtil skinType];
    
    [yearBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal.png"] forState:UIControlStateNormal];
    [yearBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight.png"] forState:UIControlStateHighlighted];
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    [yearBtn setTitleColor:color forState:UIControlStateNormal];
}

- (void)fillConditionView:(UIView *)view{
    // 年度
    yearBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    yearBtn.frame = CGRectMake(20,10,100,31);
    yearBtn.titleLabel.font = [UIFont fontWithName:@"Helvetica" size:SmallViewConditionFontSize];
    yearBtn.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
    [yearBtn addTarget:self action:@selector(changeMonthTaped:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:yearBtn];
    
    [super fillConditionView:view];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    if(isSmallView){
        pageViews = [NSArray arrayWithObjects:tableContainer, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"单箱成本收入分析";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
        lastPageBtn.hidden = true;
        nextPageBtn.hidden = true;
        popPageBtn.frame = lastPageBtn.frame;
        refreshBtn.frame = nextPageBtn.frame;
    }
    
    headerNames = [NSArray arrayWithObjects:@"月份",@"自然箱量",@"标箱量",@"总收入",@"总成本",@"总利润",@"单箱收入",@"单箱成本",@"单箱利润", nil];
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    
    // 初始化默认月份
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit fromDate:[NSDate date]];
    [self refreshByDates:dates fromPopupBtn:yearBtn];
    // 默认全部权限的公司
    [self refreshByComps:[HDSCompanyViewController companys]];
    [self loadData];
}

-(void)viewDidLayoutSubviews{
    if(isSmallView)
        return;
    [tableView adjustRightTableViewWidth];
    [tableView positionVerticalScrollBar];
}

- (void)viewDidUnload{
    [self setYearBtn:nil];
    [super viewDidUnload];
}


#pragma mark - HDSTableViewDataSource

- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)_tableView{
    return 9;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)_tableView{
//    return 0;
//}

// 列宽不包括边框宽度
- (CGFloat)tableView:(HDSTableView *)_tableView widthForColumn:(NSInteger)column{
    if(isSmallView){
        if(column==0)   return 50.0f;
        if(column<=5)   return 95.0f;
        return 75.0f;
    }
    if(column==0)   return 65.0f;
    if(column<=5)   return 115.0f;
    return 85.0f;
}

- (NSString *)tableView:(HDSTableView *)_tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node{
    switch (col) {
        case 0: return @"YEAR_MONTH";
        case 1: return @"NVL(CNTR_NUM,0)";
        case 2: return @"NVL(TEU_NUM,0)";
        case 3: return @"NVL(MON_INCOME,0)";
        case 4: return @"NVL(MON_COST,0)";
        case 5: return @"NVL(MON_PROFITS,0)";
        case 6: return @"NVL(TEU_INCOME,0)";
        case 7: return @"NVL(TEU_COST,0)";
        case 8: return @"NVL(TEU_PROFITS,0)";
        default:return @"";
    }
}

- (IBAction)changeMonthTaped:(UIButton *)sender {
    if(yearPopover == nil){
        HDSYearMonthPicker *picker = [[HDSYearMonthPicker alloc] initWithDateFormat:HDSYearPickerFormat popupBtn:yearBtn];
        picker.delegate = self;
        yearPopover= [[UIPopoverController alloc] initWithContentViewController:picker];
        yearPopover.popoverContentSize = picker.view.frame.size;
        yearPopover.delegate = picker;
    }
    [yearPopover presentPopoverFromRect:yearBtn.frame inView:[yearBtn superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

- (void)refreshByDates:(NSDateComponents *)_dates fromPopupBtn:(UIButton *)popupBtn{ 
    [yearBtn setTitle:[NSString stringWithFormat:@"     %d年",[_dates year]] forState:UIControlStateNormal];
    qYear = [NSString stringWithFormat:@"%d",[_dates year]];    
}

#pragma mark - 数据读取相关
- (void)loadData {
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
	
    // 表格数据
	NSString *url;
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ContainerCost" withExtension:@"json"]]];
    }else{
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CContainerCost/list.json?year=%@&corps=%@",qYear,qCompany];
        
        NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
        conn1 = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
    }
}

#pragma mark SBJsonStreamParserAdapterDelegate methods
- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
    NSDictionary *data;
    NSMutableDictionary *prop;
    HDSTreeNode *node;
    if(parser == parser1){
        [self.rootArray removeAllObjects];
        for(int i=0; i<array.count; i++){
            data = [array objectAtIndex:i];
            prop = [data objectForKey:@"properties"];
            node = [[HDSTreeNode alloc] initWithProperties:prop parent:nil expanded:YES];
            [self.rootArray addObject:node];
        }
        [tableView reloadData];
        
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"单箱成本收入分析");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"单箱成本收入分析");
	} else{
        
    }
}

@end
