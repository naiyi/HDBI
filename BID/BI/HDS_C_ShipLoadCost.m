//
//  HDS_C_ShipLoadCost.m
//  HDBI
//
//  Created by 毅 张 on 12-9-11.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_C_ShipLoadCost.h"
#import "UIView+AddLine.h"
#import "HDSGradientView.h"

#define FIRST_COL_WIDTH 116.0f
#define OTHER_COL_WIDTH 108.0f
#define COL_HEIGHT 20.0f
#define SMALL_FIRST_COL_WIDTH 80.0f
#define SMALL_OTHER_COL_WIDTH 90.0f
#define SMALL_COL_HEIGHT 15.0f

@implementation HDS_C_ShipLoadCost{
    
    UIPopoverController *datePopover;
    
    NSURLConnection *conn1; // 表格数据
    SBJsonStreamParser *parser1;
    SBJsonStreamParserAdapter *adapter1;
    
    NSString *qDate;
}

@synthesize dateBtn;

-(void)updateTheme:(NSNotification*)notification{
    [super updateTheme:notification]; 
    
    HDSSkinType skinType = [HDSUtil skinType];
    [dateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal_110.png"] forState:UIControlStateNormal];
    [dateBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight_110.png"] forState:UIControlStateHighlighted];
    UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
    [dateBtn setTitleColor:color forState:UIControlStateNormal];
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
        pageViews = [NSArray arrayWithObjects:tableContainer, nil];
        currentViewIndex = 0;
        self.titleLabel.text = @"单船装卸成本收入分析";
        [self smallViewChangeToIndex:currentViewIndex];
        [self insertPageControlToSmallView];
        [self createConditionView];
        lastPageBtn.hidden = true;
        nextPageBtn.hidden = true;
        popPageBtn.frame = lastPageBtn.frame;
        refreshBtn.frame = nextPageBtn.frame;
    }
    
    tableView = [HDSUtil addTableViewInContainer:tableContainer smallView:isSmallView];
    tableView.dataSource = self;
    
    // 更新主题
    [self updateTheme:nil];
    
    // 从数据库加载数据
    self.rootArray = [[NSMutableArray alloc] init];
    
    // 初始化默认月份
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSDateComponents *dates = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
    [self refreshByDates:dates fromPopupBtn:dateBtn];
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
    [self setDateBtn:nil];
    [super viewDidUnload];
}

#pragma mark - HDSTableViewDataSource
- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView{
    return 6;
}

//- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView{
//    return 2;
//}
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
        case 0: return @"SHIP_NAM";
        case 1: return @"DEV_COST";
        case 2: return @"MAN_COST";
        case 3: return @"OTHER_COST";
        case 4: return @"SHIP_CHARGE";
        case 5: return @"CARGO_CHARGE";
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
    float firstColWidth = (isSmallView?SMALL_FIRST_COL_WIDTH:FIRST_COL_WIDTH)+1;
    float otherColWidth = (isSmallView?SMALL_OTHER_COL_WIDTH:OTHER_COL_WIDTH)+1;
    float colHeight = isSmallView?SMALL_COL_HEIGHT:COL_HEIGHT;
    HDSGradientView *header = [HDSUtil getTableViewMultiHeaderBackgroundView];

    CGRect rects[10] = {  
        CGRectMake(1, 0, firstColWidth, colHeight*2),
        CGRectMake(1+firstColWidth, 0, otherColWidth*3, colHeight), 
        CGRectMake(1+firstColWidth, colHeight, otherColWidth, colHeight), 
        CGRectMake(1+firstColWidth+otherColWidth,colHeight, otherColWidth, colHeight),
        CGRectMake(1+firstColWidth+otherColWidth*2, colHeight, otherColWidth, colHeight),
        CGRectMake(1+firstColWidth+otherColWidth*3, 0, otherColWidth*2, colHeight), 
        CGRectMake(1+firstColWidth+otherColWidth*3, colHeight, otherColWidth, colHeight),
        CGRectMake(1+firstColWidth+otherColWidth*4, colHeight, otherColWidth, colHeight)
    };
    NSArray *titles = [NSArray arrayWithObjects:
                       @"船名",@"成本",@"设备成本",@"人力成本",
                       @"其他成本",@"收入",@"船方收入",@"货方收入",
                       nil];
    
    UILabel *cell;
    for (int i=0; i<titles.count; i++) {
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

#pragma mark - 数据读取相关
- (void)loadData {
    adapter1 = [[SBJsonStreamParserAdapter alloc] init];
    adapter1.delegate = self;
    parser1 = [[SBJsonStreamParser alloc] init];
    parser1.delegate = adapter1;
	
    // 表格数据
    if([HDSUtil isOffline]){    // 离线数据
        [parser1 parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDS_C_ShipLoadCost" withExtension:@"json"]]];
    }else{
        NSString *url;
        url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/CShipLoadCost/list.json?yearMonth=%@&corps=%@",qDate,qCompany];
        
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
		NSLog(@"The parser encountered an error: %@ in %@.", parser.error,@"单船装卸成本收入分析");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data in %@",@"单船装卸成本收入分析");
	} else{

    }
}


@end
