//
//  HDSTableViewDataSource.h
//  MultiColumnTableView
//
//  Created by 毅 张 on 12-6-11.
//  Copyright (c) 2012年 Newegg.com. All rights reserved.
//
#import "HDSTableView.h"

@protocol HDSTableViewDataSource <NSObject>

@required
- (NSString *)tableView:(HDSTableView *)tableView propertyNameForColumn:(NSInteger)col node:(HDSTreeNode *)node; // 列对应属性名
- (CGFloat)tableView:(HDSTableView *)tableView widthForColumn:(NSInteger)column;    //列宽,内容超过该宽度会自动折行
- (NSInteger)numberOfColumnsInRightTableView:(HDSTableView *)tableView;

@optional

- (NSInteger)numberOfColumnsInFixedTableView:(HDSTableView *)tableView; // 实现该方法则有左侧固定列
- (UIView *)tableView:(HDSTableView *)tableView cellForIndexPath:(NSIndexPath *)indexPath column:(NSInteger)col; //左右表格公用，使用多个控件组成一个tableCell时使用，如果表格只使用UILabel显示文字内容则不需要实现
- (void)tableView:(HDSTableView *)tableView setContentForCell:(UIView *)cell indexPath:(NSIndexPath *)indexPath column:(NSInteger)col;//左右表格公用，使用多个控件组成一个tableCell时使用，如果表格只使用UILabel显示文字内容则不需要实现
- (CGFloat)tableView:(HDSTableView *)tableView heightForCellAtNode:(HDSTreeNode *)node column:(NSInteger)column; //根据单元格内容确定高度
- (NSString *)tableView:(HDSTableView *)tableView reuseIdForIndexPath:(NSIndexPath *)multiColIndexPath;
- (CGFloat)heightForHeaderCellOfTableView:(HDSTableView *)tableView;    //表格头高度
- (NSString *)tableView:(HDSTableView *)tableView propertyHeaderForColumn:(NSInteger)col; // 列对应表头名,单行表头适用
- (NSString *)tableView:(HDSTableView *)tableView propertyFooterForColumn:(NSInteger)col; // 合计行
- (UIView *)tableView:(HDSTableView *)tableView multiRowHeaderInTableViewIndex:(NSInteger) tableViewIndex; // 复合表头
- (UITableViewCellAccessoryType)tableView:(HDSTableView *)tableView accessoryTypeForNode:(HDSTreeNode *)node atTableIndex:(NSInteger) tableIndex; // 附件按钮样式
- (void)tableView:(HDSTableView *)tableView accessoryButtonTappedForNode:(HDSTreeNode *)node atTableIndex:(NSInteger) tableIndex;   //附件按钮行为,与上个函数必须同时定义
- (UIControl *)tableView:(HDSTableView *)tableView accessoryViewForNode:(HDSTreeNode *)node atIndexPath:(NSIndexPath *)indexPath atTableIndex:(NSInteger) tableIndex;    //自定义附件
- (void)tableView:(HDSTableView *)tableView accessoryView:(UIControl *)accessory tappedForNode:(HDSTreeNode *)node atTableIndex:(NSInteger) tableIndex;   //自定义附件按钮行为,与上个函数必须同时定义
#pragma mark - 树状表格
- (NSInteger)treeLevelForTableView:(HDSTableView *)tableView ;
- (NSMutableArray *)rootArrayForTableView:(HDSTableView *)tableView ;
- (NSInteger)tableView:(HDSTableView *)tableView  canBeExpandedColumnIndexAtNode:(HDSTreeNode *) node;

#pragma mark - 表格操作callback
- (void)tableView:(HDSTableView *)tableView swapDataOfColumn:(NSInteger)col1 andColumn:(NSInteger)col2;
- (void)tableView:(HDSTableView *)tableView didSelectRowAtNode:(HDSTreeNode *)node;

@end
