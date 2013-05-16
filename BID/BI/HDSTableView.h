//
//  HDSTableView.m
//  MultiColumnTableView
//
//  Created by 毅 张 on 12-6-12.
//  Copyright (c) 2012年 Newegg.com. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "HDSTableViewDefaults.h"
#import "HDSTreeNode.h"

@protocol HDSTableViewDataSource;

typedef enum __HDSTableViewColumnPosition {
    HDSTableViewColumnPositionLeft,
    HDSTableViewColumnPositionMiddle,
    HDSTableViewColumnPositionRight
} HDSTableViewColumnPosition;


@interface HDSTableView : UIView<UITableViewDelegate, UITableViewDataSource, UIScrollViewDelegate> {
    BOOL respondsToNumberOfSections;
    
    BOOL hasFixedTableView;
    BOOL respondsToWidthForHeaderCell;
    BOOL respondsToSetContentForHeaderCellAtRow;
    BOOL respondsToHeightForTopHeaderCell;
    
    BOOL respondsToNumberOfRowsInHeader;
    BOOL isTreeGrid;
    
    NSInteger selectedColumn;
    
    UIView *fixedTableHeader;
    UIView *rightTableHeader;
    
    CALayer *highlightColumnLayer;
    BOOL scrolled; // 标示scrollView滚动过
    
    HDSTreeNode *currentTapedNode;
}

@property (nonatomic, strong) id<HDSTableViewDataSource> dataSource; //assign会被释放，修改为strong
@property (nonatomic, strong) UITableView *fixedTableView;
@property (nonatomic, strong) UITableView *rightTableView;
@property (nonatomic, strong) UIScrollView *scrlView;

@property (nonatomic, assign) CGFloat cellHeight;
@property (nonatomic, assign) CGFloat cellWidth;
@property (nonatomic, assign) CGFloat topHeaderHeight;
@property (nonatomic, assign) CGFloat boldSeperatorLineWidth;
@property (nonatomic, assign) CGFloat normalSeperatorLineWidth;

@property (nonatomic, retain) UIColor *boldSeperatorLineColor;
@property (nonatomic, retain) UIColor *normalSeperatorLineColor;

@property (nonatomic, retain) UIColor *topHeaderBackgroundColor;

@property (nonatomic, assign) BOOL singleRowHeader;
@property (nonatomic, assign) int dataMaxDepth;

@property (retain,nonatomic,readonly) NSMutableArray *nodes;
@property (nonatomic, retain) UIFont *titleFont;
@property (nonatomic, retain) UIFont *normalFont;

@property (nonatomic, assign) BOOL treeInOneCell;
@property (nonatomic, assign) BOOL forceCalHeight;

- (void)reloadData;

- (void)scrollToColumn:(NSInteger)col position:(HDSTableViewColumnPosition)pos animated:(BOOL)animated;

- (void)positionVerticalScrollBar;
- (void)adjustRightTableViewWidth;
- (void)doSelectRowAtIndexPath:(NSIndexPath *)indexPath;
- (void)updateTheme;

@end
