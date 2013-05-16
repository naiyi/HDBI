//
//  HDSTableView.m
//  MultiColumnTableView
//
//  Created by 毅 张 on 12-6-12.
//  Copyright (c) 2012年 Newegg.com. All rights reserved.
//


#import "HDSTableView.h"
#import <QuartzCore/QuartzCore.h>
#import "UIView+AddLine.h"
#import "HDSTreeNode.h"
#import "HDSTableViewDataSource.h"
#import "MGGradientView.h"
#import "HDSTableViewCell.h"
#import "HDSUtil.h"
#import "HDSTableScrollView.h"
#import "HDSScrollTableView.h"


#define HeaderCellTag -1
#define AddHeightTo(v, h) { CGRect f = v.frame; f.size.height += h; v.frame = f; }
#define CELL_Background_Tag 98
#define ACCESSORY_TAG 99
#define CELL_TAG_START 100
// 单元格超过该数量则不再计算行高，使用固定行高，多余内容用...代替
#define Max_CalHeight_Cell_Num 150 

@interface HDSTableView()

- (void)setupFixedTableView;
- (void)orientationChanged:(NSNotification *)notification;
- (void)highlightColumn:(NSInteger)col;
- (void)clearHighlightColumn;
- (void)reset;

- (CGFloat)heightForTopHeaderCell;
- (CGFloat)widthForFixedTableView;

- (CGRect)highlightRectForColumn:(NSInteger)col;

- (void)columnLongPressed:(UILongPressGestureRecognizer *)recognizer;

- (NSInteger)columnOfPointInTblView:(CGPoint)point;
- (void)swapColumn:(NSInteger)col1 andColumn:(NSInteger)col2;

- (void) traverseExpandRowsInArray:(NSMutableArray *)array;

@end



@implementation HDSTableView{   
    NSIndexPath *highlightingIndexPath; 
    BOOL isCalHeight;
}

@synthesize dataSource;
@synthesize fixedTableView;
@synthesize rightTableView;
@synthesize scrlView;
@synthesize cellHeight, cellWidth, topHeaderHeight;

@synthesize normalSeperatorLineColor, normalSeperatorLineWidth, boldSeperatorLineColor, boldSeperatorLineWidth;
@synthesize topHeaderBackgroundColor;

@synthesize singleRowHeader;
@synthesize nodes =_nodes;
@synthesize dataMaxDepth;
@synthesize titleFont,normalFont;
@synthesize treeInOneCell;
@synthesize forceCalHeight;


#pragma constructors and dealloc

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame])) {
        
        self.layer.borderColor = [[UIColor colorWithWhite:HDSTable_BorderColorGray alpha:0.5f] CGColor];
        self.layer.cornerRadius = HDSTable_CornerRadius;
        self.layer.borderWidth = HDSTable_BorderWidth;
        self.clipsToBounds = YES;
        self.backgroundColor = [UIColor clearColor];
        self.contentMode = UIViewContentModeRedraw;
        
//        cellHeight = HDSTable_DefaultCellHeight;
        topHeaderHeight = HDSTable_DefaultTopHeaderHeight;
        
        boldSeperatorLineWidth = HDSTable_BoldLineWidth;
        normalSeperatorLineWidth = HDSTable_NormalLineWidth;
        // 不加self指针引用会变。。为什么？
        self.boldSeperatorLineColor = [UIColor colorWithWhite:HDSTable_LineGray alpha:1.0f];
        self.normalSeperatorLineColor = [UIColor colorWithWhite:HDSTable_LineGray alpha:1.0f];
        
        topHeaderBackgroundColor = [UIColor clearColor];
        
        scrolled = NO;
        selectedColumn = -1;
        
        // 该视图用来使右表格左右滚动
        scrlView = [[HDSTableScrollView alloc] initWithFrame:self.bounds];
        scrlView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
        scrlView.delegate = self;
        [self addSubview:scrlView];

        rightTableView = [[HDSScrollTableView alloc] initWithFrame:scrlView.bounds];
        rightTableView.dataSource = self;
        rightTableView.delegate = self;
        rightTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
        // 存在scrollView嵌套导致的滚动问题
//        rightTableView.delaysContentTouches = false;
//        rightTableView.canCancelContentTouches = false;
        
        rightTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        rightTableView.backgroundColor = [UIColor clearColor];
        [scrlView addSubview:rightTableView];
        
        if([HDSUtil skinType] == HDSSkinBlue){
            scrlView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
            rightTableView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
        }else{
            scrlView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
            rightTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        }
        
        titleFont = [HDSUtil getFontBySize:HDSFontSizeNormal];
        normalFont = [HDSUtil getFontBySize:HDSFontSizeSmall];
        
        dataMaxDepth = 1;
        treeInOneCell = false;
        forceCalHeight = false;
        
        
//        UILongPressGestureRecognizer *recognizer = [[[UILongPressGestureRecognizer alloc] 
//                                                     initWithTarget:self action:@selector(columnLongPressed:)] autorelease];
//        recognizer.minimumPressDuration = 1.0;
//        [rightTableView addGestureRecognizer:recognizer];
        
        NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
        [center addObserver:self selector:@selector(orientationChanged:) name:UIDeviceOrientationDidChangeNotification object:nil];
        
    }
    
    return self;
}

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)drawRect:(CGRect)rect
{
    [super drawRect:rect];
    // 绘制两个表格之间的竖向分割线
//    if (hasFixedTableView) {
//        CGContextRef context = UIGraphicsGetCurrentContext();
//    
//        CGContextSetLineWidth(context, boldSeperatorLineWidth);
//        CGContextSetAllowsAntialiasing(context, 0);    
//        CGContextSetStrokeColorWithColor(context, [boldSeperatorLineColor CGColor]);
//
//        CGFloat x = [self widthForFixedTableView] + boldSeperatorLineWidth / 2.0f;
//        CGContextMoveToPoint(context, x, 0.0f);
//        CGContextAddLineToPoint(context, x, self.frame.size.height);
//        CGContextStrokePath(context);
//    }

}

#pragma mark - Methods

- (void)reloadData{
    
    [self reset];
    // 根据cell数量重设isCalHeight
    NSInteger numOfCols = [dataSource numberOfColumnsInRightTableView:self];
    if(hasFixedTableView){
        numOfCols += [dataSource numberOfColumnsInFixedTableView:self];
    }
    NSUInteger numOfCells = [self nodes].count * numOfCols;
    isCalHeight = numOfCells < Max_CalHeight_Cell_Num;
    
    highlightingIndexPath = nil;
    [fixedTableView reloadData];
    [rightTableView reloadData];
    [self adjustRightTableViewWidth];
}

- (void)updateTheme{
    highlightingIndexPath = nil;
    self.layer.borderColor = [HDSUtil plotBorderColor].CGColor;
    if([HDSUtil skinType] == HDSSkinBlue){
        scrlView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
        rightTableView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
    }else{
        scrlView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        rightTableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    }
    [fixedTableView reloadData];
    [rightTableView reloadData];
}


// 程序控制横向滚动到第几列
- (void)scrollToColumn:(NSInteger)col position:(HDSTableViewColumnPosition)pos animated:(BOOL)animated
{
//    CGFloat x = 0.0f;
//    for (int i = 0; i < col; i++) {
//        x += [dataSource tableView:self widthForColumn:i] + normalSeperatorLineWidth;
//    }
//    switch (pos) {
//        case HDSTableViewColumnPositionMiddle:
//            x -= (scrlView.bounds.size.width - (2 * normalSeperatorLineWidth + [dataSource tableView:self widthForColumn:col])) / 2;
//            if (x < 0.0f) x = 0.0f;
//            break;
//        case HDSTableViewColumnPositionRight:
//            x -= scrlView.bounds.size.width - (2 * normalSeperatorLineWidth + [dataSource tableView:self widthForColumn:col]);
//            if (x < 0.0f) x = 0.0f;
//            break;
//        default:
//            break;
//    }   
//    [scrlView setContentOffset:CGPointMake(x, 0) animated:animated];
}

#pragma mark - Properties

- (void)setDataSource:(id<HDSTableViewDataSource>)_dataSource
{
    if (dataSource != _dataSource) {
        dataSource = _dataSource;

        hasFixedTableView = [dataSource respondsToSelector:@selector(numberOfColumnsInFixedTableView:)] && [dataSource numberOfColumnsInFixedTableView:self]>0 ;
        if(hasFixedTableView){
            scrlView.bounces = false;
        }
       
        respondsToWidthForHeaderCell = [dataSource respondsToSelector:@selector(widthForHeaderCellOfTableView:)];
        respondsToSetContentForHeaderCellAtRow = [dataSource respondsToSelector:@selector(tableView:setContentForHeaderCell:atRow:)];
        respondsToHeightForTopHeaderCell = [dataSource respondsToSelector:@selector(heightForHeaderCellOfTableView:)];
        singleRowHeader = ![dataSource respondsToSelector:@selector(tableView:multiRowHeaderInTableViewIndex:)];
//        isTreeGrid = [dataSource respondsToSelector:@selector(tableView:canBeExpandedColumnIndexAtNode:)];
        isTreeGrid = [dataSource tableView:self canBeExpandedColumnIndexAtNode:nil]>=0;
        
        // set contentSize of the scrollView and the width of the tableView
        [self adjustRightTableViewWidth];
        
        [self reset];
        
        // 生成左侧固定表格
        if (hasFixedTableView)
            [self setupFixedTableView];
        
        [self positionVerticalScrollBar];
        
    }
}

#pragma mark - UITableViewDataSource & UITableViewDelegate

- (NSMutableArray *)nodes{
    if (!_nodes) {
		_nodes = [[NSMutableArray alloc] init];
		[self traverseExpandRowsInArray:[dataSource rootArrayForTableView:self]];	
	}
	return _nodes;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [[self nodes] count];
}

- (void) traverseExpandRowsInArray:(NSMutableArray *)array{
    for (HDSTreeNode *node in array) {
        // 将树形数组按展开顺序加入到线性数组中,供cellForIndexPath使用
        [_nodes addObject:node];
        // 向下级遍历
        if ([node isDirectory] && [node directoryIsExpanded]){
            [self traverseExpandRowsInArray:[node children]];
        }
    }
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
//    NSLog(@"row %i",indexPath.row);
    NSString *CellID, *CellIDPrefix,*CellIDSkin, *CellIDName;
    NSInteger beginColIndex, numOfCols;
    if ([dataSource respondsToSelector:@selector(tableView:reuseIdForIndexPath:)])
        CellIDName = [dataSource tableView:self reuseIdForIndexPath:indexPath];
    else
        CellIDName = @"MultiColumnCell";
    if(tableView == fixedTableView){
        CellIDPrefix = @"Fixed";
        beginColIndex = 0;
        numOfCols = [dataSource numberOfColumnsInFixedTableView:self];
    }else{ 
        CellIDPrefix = @"Right";
        beginColIndex = hasFixedTableView ? [dataSource numberOfColumnsInFixedTableView:self] : 0;
        numOfCols = [dataSource numberOfColumnsInRightTableView:self];
    }
    if([HDSUtil skinType] == HDSSkinBlue){
        CellIDSkin = @"Blue";
    }else{
        CellIDSkin = @"Black";
    }
    CellID = [[CellIDPrefix stringByAppendingString:CellIDName] stringByAppendingString:CellIDSkin];
    
    UITableViewCell *row = (UITableViewCell *)[tableView dequeueReusableCellWithIdentifier:CellID];
    
    if (row == nil) {
        row = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellID];
        row.selectionStyle = UITableViewCellSelectionStyleNone; // 手动设置行选中样式
//        row.selectedBackgroundView = [HDSUtil getTableViewSelectedRowBackgroundView];
        if([HDSUtil skinType] == HDSSkinBlue){
            [row addBottomLineWithWidth:normalSeperatorLineWidth color:normalSeperatorLineColor];
        }
        
        CGFloat x = 0.0f,   colWidth = 0.0f;
        UIView *tableCell;
        for (int i = beginColIndex; i < beginColIndex+numOfCols; i++) {
            colWidth = [dataSource tableView:self widthForColumn:i];
            if([dataSource respondsToSelector:@selector(tableView:cellForIndexPath:column:)]){
                //TODO 应该使用node替换indexPath
                tableCell = [dataSource tableView:self cellForIndexPath:indexPath column:i];
            }else{
                tableCell = [[HDSTableViewCell alloc] initWithFrame:CGRectMake(HDSTable_TextIndent, 0.0f, colWidth-HDSTable_TextIndent, 40.0f)]; // 文字左侧缩进
                UILabel *labelCell = [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, colWidth-HDSTable_TextIndent, 40.0f)]; 
                
//                labelCell.highlightedTextColor = [UIColor whiteColor];
                labelCell.backgroundColor = [UIColor clearColor];
                labelCell.numberOfLines = 0;
                labelCell.lineBreakMode = UILineBreakModeTailTruncation;
                // userInteractionEnabled在UILabel中默认为No,在UIView默认为YES
                labelCell.userInteractionEnabled = YES;
                [tableCell addSubview:labelCell];
            }
            tableCell.tag = i+CELL_TAG_START; // 使用tag标示cell,从100开始记录
            tableCell.backgroundColor = [UIColor clearColor];
            CGRect f = tableCell.frame;
            f.origin.x += x+normalSeperatorLineWidth;
            tableCell.frame = f;
            [row.contentView addSubview:tableCell];
            // 单元格左侧边框 fixed与right之间使用双竖线分割
            if([HDSUtil skinType] == HDSSkinBlue){
                if( (hasFixedTableView && ( tableView == rightTableView || i!= beginColIndex)) ||
                   (!hasFixedTableView && i!= beginColIndex) ){
                    [row addVerticalLineWithWidth:normalSeperatorLineWidth color:normalSeperatorLineColor atX:x];
                }
            }
            
            x += colWidth + normalSeperatorLineWidth;
        }
        // 最后一个单元格的右侧
        if (tableView == fixedTableView) {
            if([HDSUtil skinType] == HDSSkinBlue){
                [row addVerticalLineWithWidth:normalSeperatorLineWidth color:normalSeperatorLineColor atX:x];
            }else{
                [row addVerticalLineWithWidth:normalSeperatorLineWidth color:[HDSUtil plotBorderColor] atX:x];
            }
        }
    }
    // 表格附件按钮
    row.accessoryType = UITableViewCellAccessoryNone;
    if([dataSource respondsToSelector:@selector(tableView:accessoryTypeForNode:atTableIndex:)]){
        row.accessoryType = [dataSource tableView:self accessoryTypeForNode:[self.nodes objectAtIndex:indexPath.row] atTableIndex:tableView == fixedTableView ?0:1];
    }
    [[row.contentView viewWithTag:ACCESSORY_TAG] removeFromSuperview] ;
    if([dataSource respondsToSelector:@selector(tableView:accessoryViewForNode:atIndexPath:atTableIndex:)]){
        UIControl *accessory = [dataSource tableView:self accessoryViewForNode:[self.nodes objectAtIndex:indexPath.row] atIndexPath:indexPath atTableIndex:tableView == fixedTableView ?0:1];
        if(accessory){
            accessory.tag = ACCESSORY_TAG;
            [accessory addTarget:self action:@selector(accessoryViewTaped:) forControlEvents:UIControlEventTouchUpInside];
            [row.contentView addSubview:accessory];
        }
    }
    
    // 树表格支持多级背景色 
//    if(isTreeGrid){
//        HDSTreeNode *node = (HDSTreeNode *)[[self nodes] objectAtIndex:indexPath.row];
//        if([HDSUtil skinType] == HDSSkinBlue){
//            float maxDepth = [[NSNumber numberWithInt:self.dataMaxDepth] floatValue];
//            row.contentView.backgroundColor = [UIColor colorWithWhite:(180.0f+(node.depth+1)/maxDepth*75.0f)/255.0f alpha:1.0];
//        }else{
//            UIColor *backgroundColor;
//            switch (node.depth) {
//                case 0: backgroundColor = [HDSUtil colorFromString:@"29272b"];  break;
//                case 1: backgroundColor = [HDSUtil colorFromString:@"1c1c1c"];  break;    
//                case 2: backgroundColor = [HDSUtil colorFromString:@"121115"];  break;
//            }
//            row.contentView.backgroundColor = backgroundColor;
//        }
//    }else{ //普通表格隔行变色
        if([HDSUtil skinType] == HDSSkinBlue){
            row.contentView.backgroundColor = indexPath.row%2 == 0?[HDSUtil colorFromString:@"dce8fc"]:[HDSUtil colorFromString:@"ffffff"];
        }else{
            row.contentView.backgroundColor = indexPath.row%2 == 0?[HDSUtil colorFromString:@"1d1b1f"]:[HDSUtil colorFromString:@"121115"];
        }
//    }
    
    
    // 恢复之前选中但被滚动出可视区域的高亮行
    if(highlightingIndexPath!=nil && highlightingIndexPath.row == indexPath.row && highlightingIndexPath.section == indexPath.section){
        [self highlightSelectedRowAtCell:row highlight:true];
        [self addBackgroundViewInRowContent:row.contentView tableView:tableView indexPath:indexPath];
    }else{  // 隐藏选中行背景
        [[row.contentView viewWithTag:CELL_Background_Tag] removeFromSuperview];
    }
    
    // 填充cell
    for (int i = beginColIndex; i < beginColIndex+numOfCols; i++) {
        HDSTreeNode *_node = [[self nodes] objectAtIndex:indexPath.row];
        CGFloat colWidth = [dataSource tableView:self widthForColumn:i];
        if([dataSource respondsToSelector:@selector(tableView:setContentForCell:indexPath:column:)]){
            //TODO 应该使用node替换indexPath
            // [[row.contentView subviews] objectAtIndex:i]
            [dataSource tableView:self setContentForCell:[row.contentView viewWithTag:i+CELL_TAG_START] indexPath:indexPath column:i];
        }else{
            HDSTableViewCell *viewCell = (HDSTableViewCell *)[row.contentView viewWithTag:i+CELL_TAG_START];
            // 重设triangleLayer的图标
            viewCell.triangleLayer.contents = nil;
            viewCell.triangleLayer.transform = CATransform3DIdentity;
            //TODO 测试是否有不正确的箭头方向,清除原有动画
            [viewCell.triangleLayer removeAllAnimations];
            viewCell.expanded = false;
            UILabel *labelCell = (UILabel *)[[viewCell subviews] lastObject];
            // 重设label的frame,防止重用的cell中有trianglelayer引起的偏移
            CGRect f = labelCell.frame;
            if([HDSUtil skinType] == HDSSkinBlue){
                labelCell.textColor = [UIColor blackColor];
                labelCell.highlightedTextColor = [UIColor blackColor];
            }else{
                labelCell.textColor = [UIColor colorWithWhite:1.0f alpha:0.8f];
                labelCell.highlightedTextColor = [UIColor whiteColor];
            }
            
            f.origin.x = 0.0f;
            f.size.width = colWidth-HDSTable_TextIndent-5; // -5保证数字右对齐时候的边距
            f.size.height = [self tableView:nil heightForRowAtIndexPath:indexPath]-normalSeperatorLineWidth;
            labelCell.frame = f;
            
            NSDictionary *properties = [_node properties];
            labelCell.font = normalFont;
            // 返回json数据可能是string或者number
//            NSLog(@"row:%i,col:%i",indexPath.row,i);
            labelCell.text = [HDSUtil convertDataToString:[properties objectForKey:[dataSource tableView:self propertyNameForColumn:i node:_node]] label:labelCell];
            
            // 删除复用的cell里已有的Gesture
            if([viewCell.gestureRecognizers count] == 1){
                [viewCell removeGestureRecognizer:[viewCell.gestureRecognizers objectAtIndex:0]];
            }
            if(isTreeGrid && i ==[dataSource tableView:self canBeExpandedColumnIndexAtNode:_node]){
                if(_node.isDirectory){
                    // 注册单击展开树节点的手势
                    [viewCell addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleTreeNodeTap:)]];
                    viewCell.triangleLayer.contents = (id)[UIImage imageNamed:@"triangleSmall.png"].CGImage;
                    if(_node.directoryIsExpanded){
                        [viewCell setExpanded:YES animation:NO];
                    }
                    // 三角形图标
                    if(treeInOneCell){  // 在同一列显示树状结构
                        float indent = _node.depth*30.0f;
                        viewCell.triangleLayer.frame = CGRectMake(indent,([self tableView:nil heightForRowAtIndexPath:indexPath]-12)/2,12,12);
                        // label设置缩进
                        CGRect f = labelCell.frame;
                        f.size.width = colWidth-2*HDSTable_TextIndent-12.0f-indent;
                        f.origin.x = HDSTable_TextIndent+12.0f+indent;
                        labelCell.frame = f;
                    }else{
                        viewCell.triangleLayer.frame = CGRectMake(0.0f,([self tableView:nil heightForRowAtIndexPath:indexPath]-12)/2,12,12);
                        // label设置缩进
                        CGRect f = labelCell.frame;
                        f.size.width = colWidth-2*HDSTable_TextIndent-12.0f;
                        f.origin.x = HDSTable_TextIndent+12.0f;
                        labelCell.frame = f;
                    } 
                }else{
                    if(treeInOneCell){
                        float indent = _node.depth*30.0f;
                        CGRect f = labelCell.frame;
                        f.size.width = colWidth-2*HDSTable_TextIndent-indent;
                        f.origin.x = HDSTable_TextIndent+indent;
                        labelCell.frame = f;
                    }
                }
                
            }
        }
    }
    
    AddHeightTo(row, normalSeperatorLineWidth);
    return row;
}
- (void) accessoryViewTaped:(UIControl *) accessory{
    UITableViewCell *cell = (UITableViewCell *)[[accessory superview] superview];
    UITableView *tv = (UITableView *)[cell superview];
    NSIndexPath *indexPath = [tv indexPathForCell:cell];
    [dataSource tableView:self accessoryView:accessory tappedForNode:[self.nodes objectAtIndex:indexPath.row] atTableIndex:tv == fixedTableView ?0:1];
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    [dataSource tableView:self accessoryButtonTappedForNode:[self.nodes objectAtIndex:indexPath.row] atTableIndex:tableView == fixedTableView ?0:1];
}

- (void)handleTreeNodeTap:(UITapGestureRecognizer *)recognizer{
    HDSTableViewCell *viewCell = (HDSTableViewCell *)[recognizer view];
    UITableViewCell *tableCell = (UITableViewCell *)[[viewCell superview] superview]; 
    NSIndexPath *indexPath = [(UITableView *)[tableCell superview] indexPathForCell:tableCell];
    
    [self tableView:rightTableView willSelectRowAtIndexPath:indexPath];

    NSInteger rowNumber = [indexPath row];
    HDSTreeNode *node = (HDSTreeNode *)[[self nodes] objectAtIndex:rowNumber];
    
    [rightTableView beginUpdates];
    [fixedTableView beginUpdates];
    if([node directoryIsExpanded]){
        [viewCell setExpanded:NO animation:YES];
        NSRange collapsedRange = [self collapseNodeAtIndex:rowNumber];
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        for (int i = 0; i<collapsedRange.length; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:collapsedRange.location+i inSection:0]];
        }
        [rightTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [fixedTableView deleteRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }else{
        [viewCell setExpanded:YES animation:YES];
        NSRange expandedRange = [self expandNodeAtIndex:rowNumber];
        NSMutableArray *indexPaths = [[NSMutableArray alloc] init];
        for (int i = 0; i<expandedRange.length; i++) {
            [indexPaths addObject:[NSIndexPath indexPathForRow:expandedRange.location+i inSection:0]];
        }
        [rightTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
        [fixedTableView insertRowsAtIndexPaths:indexPaths withRowAnimation:UITableViewRowAnimationAutomatic];
    }
    [rightTableView endUpdates];
    [fixedTableView endUpdates];
    
    // 重设isCallHeight
    NSInteger numOfCols = [dataSource numberOfColumnsInRightTableView:self];
    if(hasFixedTableView){
        numOfCols += [dataSource numberOfColumnsInFixedTableView:self];
    }
    NSUInteger numOfCells = [self nodes].count * numOfCols;
    isCalHeight = numOfCells < Max_CalHeight_Cell_Num;
}

// heightForRowAtIndexPath会对表格所有行进行计算，而不是仅对可视行进行计算，并且每次insert/delete rows的时候都会重新计算所有行，所以有两个方案:1.不能在此放置大量的计算工作,2.控制表格加载的行数
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    NSDateFormatter *df = [[NSDateFormatter alloc] init];
//    df.dateFormat = @"HH:mm:ss.SSS";
//    NSLog(@"row %i begin:%@",indexPath.row,[df stringFromDate:[NSDate date]]);
    
    if (forceCalHeight || (isCalHeight && [dataSource respondsToSelector:@selector(tableView:heightForCellAtNode:column:)]) ) {
        CGFloat height = 0.0f;
        NSInteger numOfCols = [dataSource numberOfColumnsInRightTableView:self];
        if(hasFixedTableView){
            numOfCols += [dataSource numberOfColumnsInFixedTableView:self];
        }
        for (int i = 0; i < numOfCols; i++) {
            HDSTreeNode *node = (HDSTreeNode *)[[self nodes] objectAtIndex:indexPath.row];
            CGFloat h = [dataSource tableView:self heightForCellAtNode:node column:i];
            if (h > height) height = h;
        }
        return height + normalSeperatorLineWidth;
    }
    return cellHeight;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    if(singleRowHeader){
        UIView *tableHeaderView;
        NSInteger beginColIndex, numOfCols;
        if (tableView == fixedTableView) {
            fixedTableHeader = [[UIView alloc] initWithFrame:CGRectZero];
            tableHeaderView = fixedTableHeader;
            beginColIndex = 0;
            numOfCols = [dataSource numberOfColumnsInFixedTableView:self];
        }else{
            rightTableHeader = [[UIView alloc] initWithFrame:CGRectZero];
            tableHeaderView = rightTableHeader;
            beginColIndex = hasFixedTableView ? [dataSource numberOfColumnsInFixedTableView:self] : 0;
            numOfCols = [dataSource numberOfColumnsInRightTableView:self];
        }
            
        tableHeaderView.clipsToBounds = YES;
        CGFloat x = 0.0f, colWidth = 0.0f;
        for (int i = beginColIndex; i < beginColIndex + numOfCols; i++) {
            colWidth = [dataSource tableView:self widthForColumn:i];
            int offsetWidth = normalSeperatorLineWidth, offsetX = 0;
            if([HDSUtil skinType] == HDSSkinBlue){
                if( (hasFixedTableView && ( tableView == rightTableView || i!= beginColIndex)) ||
                   (!hasFixedTableView && i!= beginColIndex) ){
                    offsetX = normalSeperatorLineWidth;
                    offsetWidth = 0;
                    // header部分左边框
                    [tableHeaderView addVerticalLineWithWidth:normalSeperatorLineWidth color:normalSeperatorLineColor atX:x];
                }
            }
            if(!hasFixedTableView && i == beginColIndex + numOfCols -1){
                offsetWidth += normalSeperatorLineWidth;
            }
            UILabel *headerCell =  [[MGGradientView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, colWidth+offsetWidth, [self heightForTopHeaderCell])] ;
            headerCell.text = [dataSource tableView:self propertyHeaderForColumn:i];
            headerCell.textAlignment = UITextAlignmentCenter;
            headerCell.textColor = [UIColor whiteColor];
            headerCell.font = titleFont;
            headerCell.backgroundColor = [UIColor clearColor];
            headerCell.userInteractionEnabled = YES;
            CGRect f = headerCell.frame;
            f.origin.x = x+offsetX;
            headerCell.frame = f;
            [tableHeaderView addSubview:headerCell];
                
            x += colWidth+normalSeperatorLineWidth;
        }
        // 固定表格最后一个单元格的右侧，用来区分固定和可滚动区域
        if (tableView == fixedTableView) {
            if([HDSUtil skinType] == HDSSkinBlue){
                [tableHeaderView addVerticalLineWithWidth:normalSeperatorLineWidth color:normalSeperatorLineColor atX:x];
            }else{
                [tableHeaderView addVerticalLineWithWidth:normalSeperatorLineWidth color:[HDSUtil plotBorderColor] atX:x];
            }
        }
            
        CGRect f = tableHeaderView.frame;
        f.size = CGSizeMake(x, [self heightForTopHeaderCell]);
        tableHeaderView.frame = f;
        tableHeaderView.backgroundColor = self.topHeaderBackgroundColor;
        [tableHeaderView addBottomLineWithWidth:normalSeperatorLineWidth color:normalSeperatorLineColor];
            
        return tableHeaderView;
        
    }else{
        return [dataSource tableView:self multiRowHeaderInTableViewIndex:tableView==fixedTableView?0:1];
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section{
    if([dataSource respondsToSelector:@selector(tableView:propertyFooterForColumn:)]){
        UIView *tableFooterView = [[UIView alloc] initWithFrame:CGRectZero];
        NSInteger beginColIndex, numOfCols;
        if (tableView == fixedTableView) {
            beginColIndex = 0;
            numOfCols = [dataSource numberOfColumnsInFixedTableView:self];
        }else{
            beginColIndex = hasFixedTableView ? [dataSource numberOfColumnsInFixedTableView:self] : 0;
            numOfCols = [dataSource numberOfColumnsInRightTableView:self];
        }
        tableFooterView.clipsToBounds = YES;
        CGFloat x = 0.0f, colWidth = 0.0f;
        for (int i = beginColIndex; i < beginColIndex + numOfCols; i++) {
            colWidth = [dataSource tableView:self widthForColumn:i];
            UILabel *footerCell =  [[MGGradientView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, colWidth+([HDSUtil skinType] == HDSSkinBlue?0:normalSeperatorLineWidth), [self heightForTopHeaderCell])] ;
            footerCell.text = [dataSource tableView:self propertyFooterForColumn:i];
            footerCell.textAlignment = UITextAlignmentRight;
            footerCell.textColor = [UIColor whiteColor];
            footerCell.font = titleFont;
            footerCell.backgroundColor = [UIColor clearColor];
            footerCell.userInteractionEnabled = YES;
            CGRect f = footerCell.frame;
            f.origin.x = x+([HDSUtil skinType] == HDSSkinBlue?normalSeperatorLineWidth:0);
            footerCell.frame = f;
            [tableFooterView addSubview:footerCell];
            // header部分左边框
            if([HDSUtil skinType] == HDSSkinBlue){
                [tableFooterView addVerticalLineWithWidth:normalSeperatorLineWidth color:normalSeperatorLineColor atX:x];
            }
            
            x += colWidth+normalSeperatorLineWidth;
        }
        // 固定表格最后一个单元格的右侧，用来区分固定和可滚动区域
        if([HDSUtil skinType] == HDSSkinBlue){
            [tableFooterView addVerticalLineWithWidth:normalSeperatorLineWidth color:normalSeperatorLineColor atX:x];
        }else{
            [tableFooterView addVerticalLineWithWidth:normalSeperatorLineWidth color:[HDSUtil plotBorderColor] atX:x];
        }
        
        CGRect f = tableFooterView.frame;
        f.size = CGSizeMake(x, [self heightForTopHeaderCell]);
        tableFooterView.frame = f;
        tableFooterView.backgroundColor = self.topHeaderBackgroundColor;
        [tableFooterView addBottomLineWithWidth:normalSeperatorLineWidth color:normalSeperatorLineColor];
        
        return tableFooterView;
        
    }
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return [self heightForTopHeaderCell] + normalSeperatorLineWidth;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    if([dataSource respondsToSelector:@selector(tableView:propertyFooterForColumn:)]){
        return [self heightForTopHeaderCell];
    }
    return 0;
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
//{
//        
//}

- (NSRange) expandNodeAtIndex:(NSUInteger)index{
	HDSTreeNode *node = (HDSTreeNode *)[self.nodes objectAtIndex:index];
	[node expand];
	int expandedNum = [self _insertChildren:node.children inArray:_nodes atIndex:index+1];
	NSRange expandRange = NSMakeRange(index+1, expandedNum);
	return expandRange;
}

- (int) _insertChildren:(NSArray *)children inArray:(NSMutableArray *)array atIndex:(NSUInteger)index{
    [array replaceObjectsInRange:NSMakeRange(index, 0) withObjectsFromArray:children];
	int res = children.count;   //res纪录该次递归插入的所有节点数量:sum(当前节点+当前节点的所有下级节点)
	int i=0; // i为在数组中绘制新节点的位置定位
    int numOfDescendantInCurrentNode;
	for (HDSTreeNode *child in children) {
		if (child.directoryIsExpanded) {
			numOfDescendantInCurrentNode = [self _insertChildren:child.children inArray:array atIndex:index+i+1];//该级节点所有下级节点的数量
            i += numOfDescendantInCurrentNode;
			res += numOfDescendantInCurrentNode;
		}
		i++;//i增加下一个上级节点
	}
	return res;
	
}

- (NSRange) collapseNodeAtIndex:(NSUInteger)index{
    HDSTreeNode *node = (HDSTreeNode *)[self.nodes objectAtIndex:index];
	int collapsedNum = [self _collapseNode:node];
	
	NSRange collapseRange = NSMakeRange(index+1, collapsedNum);
	[_nodes removeObjectsInRange:collapseRange];
	[node collapse];
	return collapseRange;
	
}

- (int) _collapseNode:(HDSTreeNode *)node{
	int res = 0;
	if (node.directoryIsExpanded) {
		NSArray *children = node.children;
		res = children.count;
		for (HDSTreeNode *child in children) {
			res += [self _collapseNode:child];
		}
	}
	return res;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if(scrollView == scrlView){
        // 横向滚动主表格
        scrolled = YES;
        [self positionVerticalScrollBar];
    }else{
        // 竖向滚动锁定表格或者主表格
        UIScrollView *target;
        if (scrollView == rightTableView){
            target = fixedTableView;
        }else{
            target = rightTableView;
        }
        
        target.contentOffset = scrollView.contentOffset;
    }
}

- (void)positionVerticalScrollBar{
    // 初始化主表格竖向滚动条的位置
    CGFloat rightInset = .0f;
    if(scrolled){
        CGFloat left = scrlView.contentOffset.x;
        rightInset = rightTableView.frame.size.width-scrlView.frame.size.width-left;
    }else{
        rightInset = rightTableView.frame.size.width - scrlView.frame.size.width ;
    }
    rightTableView.scrollIndicatorInsets = UIEdgeInsetsMake([self heightForTopHeaderCell] , 0, 0, rightInset);
}

#pragma mark Procedures

- (void)reset {
    _nodes = nil;
}

- (void)adjustRightTableViewWidth{
    CGFloat width = 0.0f;
    NSInteger cols = [dataSource numberOfColumnsInRightTableView:self];
    NSInteger beginColIndex = hasFixedTableView?[dataSource numberOfColumnsInFixedTableView:self]:0;

    for (int i = beginColIndex; i < beginColIndex + cols; i++) {
        width += [dataSource tableView:self widthForColumn:i] + normalSeperatorLineWidth;
    }
    // 增加最后一个右边框的宽度
    width += normalSeperatorLineWidth;
    scrlView.contentSize = CGSizeMake(width, 0.0f);
    
    CGRect f = rightTableView.frame;
    f.size.width = MAX(self.frame.size.width - [self widthForFixedTableView], width);
    rightTableView.frame = f;
}

- (void)setupFixedTableView{
    CGFloat headerCellWidth = [self widthForFixedTableView];
    [fixedTableView removeFromSuperview];
    fixedTableView = [[HDSScrollTableView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, headerCellWidth, self.frame.size.height)];
    fixedTableView.autoresizingMask = UIViewAutoresizingFlexibleHeight;
    fixedTableView.delegate = self;
    fixedTableView.dataSource = self;
    fixedTableView.backgroundColor = [UIColor clearColor];
    // 默认分割线不能定义线的宽度和竖向边框的颜色,需要使用自定义的分割线
    fixedTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    fixedTableView.showsVerticalScrollIndicator = NO;
    [self addSubview:fixedTableView];
    scrlView.frame = CGRectMake(headerCellWidth, 0.0f, self.frame.size.width - headerCellWidth, self.frame.size.height);
}

//- (void)deselectRowAtIndexPath:(NSIndexPath *)indexPath{
//    highlightingIndexPath = nil;
//    [UIView animateWithDuration:1 animations:^{
//        [fixedTableView cellForRowAtIndexPath:indexPath].contentView.backgroundColor=[UIColor clearColor];
//        [rightTableView cellForRowAtIndexPath:indexPath].contentView.backgroundColor=[UIColor clearColor];
//    }];
//}

- (void) doSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if([dataSource respondsToSelector:@selector(tableView:didSelectRowAtNode:)] && [self nodes].count > 0){
        [dataSource tableView:self didSelectRowAtNode:[[self nodes] objectAtIndex:indexPath.row]]; 
    }
}

// 选中行字体颜色高亮为白色
- (void)highlightSelectedRowAtIndexPath:(NSIndexPath *)_indexPath inTableView:(UITableView *)_tableView highlight:(BOOL) _highlight{
    [self highlightSelectedRowAtCell:[_tableView cellForRowAtIndexPath:_indexPath] highlight:_highlight];
}

- (void)highlightSelectedRowAtCell:(UITableViewCell *)_cell highlight:(BOOL) _highlight{
    for(UIView *cellView in _cell.contentView.subviews){
        for(UIView *cellLabel in [cellView subviews]){
            if([cellLabel isKindOfClass:[UILabel class]]){
                [(UILabel *)cellLabel setHighlighted:_highlight];
            }
        }
    }
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [self highlightSelectedRowAtIndexPath:indexPath inTableView:fixedTableView highlight:true];
    [self highlightSelectedRowAtIndexPath:indexPath inTableView:rightTableView highlight:true];
    
    // 树状表格展开后，前后indexPath一致并不一定代表指向同一个节点，故无法判断
    if(highlightingIndexPath != nil){
        if(indexPath.row == highlightingIndexPath.row && indexPath.section == highlightingIndexPath.section){
            return nil;
        }else{
            [self highlightSelectedRowAtIndexPath:highlightingIndexPath inTableView:fixedTableView highlight:false];
            [self highlightSelectedRowAtIndexPath:highlightingIndexPath inTableView:rightTableView highlight:false];
            
            [[[fixedTableView cellForRowAtIndexPath:highlightingIndexPath].contentView viewWithTag:CELL_Background_Tag] removeFromSuperview];
            [[[rightTableView cellForRowAtIndexPath:highlightingIndexPath].contentView viewWithTag:CELL_Background_Tag] removeFromSuperview];
        }
    }
    
    // 存在的问题：两个表格的选中动画无法同步，无法保留表格边框线
//    if (tableView == fixedTableView) {
//        [rightTableView selectRowAtIndexPath:indexPath animated:false scrollPosition:UITableViewScrollPositionNone];
//    }else{
//        [fixedTableView selectRowAtIndexPath:indexPath animated:false scrollPosition:UITableViewScrollPositionNone];
//    }
    
    // 自定义行选中背景色能保留表格列的分割线，但会带来一系列问题，比如滚动出可视区域不能保留选中，背景色不能渐变
    // 背景层
    [self addBackgroundViewInRowContent:[rightTableView cellForRowAtIndexPath:indexPath].contentView tableView:rightTableView indexPath:indexPath];
    [self addBackgroundViewInRowContent:[fixedTableView cellForRowAtIndexPath:indexPath].contentView tableView:fixedTableView indexPath:indexPath];
    
    highlightingIndexPath = indexPath;
    
    // 执行选中后的操作
    [self doSelectRowAtIndexPath:indexPath];
    
    return indexPath;
}

- (void) addBackgroundViewInRowContent:(UIView *)contentView tableView:(UITableView *)_tableView indexPath:(NSIndexPath *)indexPath{
    CGRect frame = contentView.frame;
    frame.size.height = [self tableView:_tableView heightForRowAtIndexPath:indexPath];
    UIImageView *backgroundView = [[UIImageView alloc] initWithFrame:frame];
    backgroundView.tag = CELL_Background_Tag;
    [contentView addSubview:backgroundView];
    [contentView sendSubviewToBack:backgroundView];
    UIImage *backgroundImage = [HDSUtil loadImageSkin:[HDSUtil skinType] imageName:@"table_selected_bg.png"];
    if( [[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0){
        backgroundView.image = [backgroundImage resizableImageWithCapInsets:UIEdgeInsetsMake(15, 0, 15, 0)];
    }else{
        backgroundView.image = [backgroundImage stretchableImageWithLeftCapWidth:0 topCapHeight:15];
    }
    
}

//- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
//    
//}


- (void)swapColumn:(NSInteger)col1 andColumn:(NSInteger)col2{
    [dataSource tableView:self swapDataOfColumn:col1 andColumn:col2];
    [rightTableView reloadData];
}

- (void)highlightColumn:(NSInteger)col{
    if (highlightColumnLayer == nil) {
        highlightColumnLayer = [[CALayer alloc] init];
        highlightColumnLayer.borderColor = [[UIColor colorWithRed:232.0f/255.0f green:142.0f/255.0f blue:20.0f/255.0f alpha:1.0f] CGColor];
        highlightColumnLayer.borderWidth = 4.0;
        highlightColumnLayer.shadowRadius = 5.0f;
        highlightColumnLayer.shadowOpacity = 0.5f;
        [self.layer addSublayer:highlightColumnLayer];
    }
    
    
    [CATransaction begin]; 
    [CATransaction setValue: (id) kCFBooleanTrue forKey: kCATransactionDisableActions];
    highlightColumnLayer.frame = [self highlightRectForColumn:selectedColumn];
    [CATransaction commit];
}

- (void)clearHighlightColumn
{
    [highlightColumnLayer removeFromSuperlayer];
    highlightColumnLayer = nil;
}

#pragma mark Computations

- (CGFloat)heightForTopHeaderCell
{
    if (respondsToHeightForTopHeaderCell)
        return [dataSource heightForHeaderCellOfTableView:self];
    else
        return topHeaderHeight;
}

- (CGFloat)widthForFixedTableView
{
    if (hasFixedTableView) {
        CGFloat width = 0.0f;
        NSInteger numberOfFixedColumns = [dataSource numberOfColumnsInFixedTableView:self];
        for(int i=0;i<numberOfFixedColumns;i++){
            width += [dataSource tableView:self widthForColumn:i] + normalSeperatorLineWidth;
        }
        // 增加最后一个右边框的宽度
        width += normalSeperatorLineWidth;
        return width;
    } else {
        return 0.0f;
    }
}

- (NSInteger)columnOfPointInTblView:(CGPoint)point
{
    CGFloat x = point.x, w = 0.0f;
    NSInteger cols = [dataSource numberOfColumnsInRightTableView:self];
    
    for (int i = 0; i < cols; i++) {
        w += [dataSource tableView:self widthForColumn:i];
        if (x < w)
            return i;
    }
    
    return -1;
}

- (CGRect)highlightRectForColumn:(NSInteger)col
{
    CGFloat x = fixedTableView.frame.size.width - scrlView.contentOffset.x + boldSeperatorLineWidth;
    for (int i = 0; i < col; i++) {
        x += [dataSource tableView:self widthForColumn:i] + normalSeperatorLineWidth;
    }
    
    CGFloat w = [dataSource tableView:self widthForColumn:col];
    
    return CGRectMake(x, HDSTable_BorderWidth, w, self.frame.size.height - HDSTable_BorderWidth * 2);
}

#pragma mark Event Handelers

- (void)orientationChanged:(NSNotification *)notification{
    [self adjustRightTableViewWidth];
}

- (void)columnLongPressed:(UILongPressGestureRecognizer *)recognizer
{
    if ([dataSource respondsToSelector:@selector(tableView:swapDataOfColumn:andColumn:)]) {
        switch (recognizer.state) {
            case UIGestureRecognizerStateBegan: {
                // create the drag overlay layer
                CGPoint point = [recognizer locationInView:scrlView];
                selectedColumn = [self columnOfPointInTblView:point];
                
                // Highlight the column
                [self highlightColumn:selectedColumn];
                break;
            } case UIGestureRecognizerStateChanged: {
                // move the dragging layer to the destination.
                CGPoint point = [recognizer locationInView:scrlView];
                NSInteger currentCol = [self columnOfPointInTblView:point];
                
                if (currentCol >= 0 && currentCol != selectedColumn) {
                    [self swapColumn:selectedColumn andColumn:currentCol];
                    selectedColumn = currentCol;
                    [self highlightColumn:selectedColumn];
                }
                
                break;
            }
            case UIGestureRecognizerStateEnded: 
            case UIGestureRecognizerStateCancelled: {
                [self clearHighlightColumn];
                selectedColumn = -1;
                // swap the column
                break;
            } 
            default:
                NSLog(@"recognizer.state: %d", recognizer.state);
                break;
        }
    }
    
}

@end
