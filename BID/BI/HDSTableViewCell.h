//
//  HDSTableViewCell.h
//  MultiColumnTableView
//
//  Created by 毅 张 on 12-6-12.
//  Copyright (c) 2012年 Newegg.com. All rights reserved.
//

@interface HDSTableViewCell : UIView 

@property (nonatomic,retain) CALayer *triangleLayer;
@property (nonatomic,assign) BOOL expanded;

- (void) setExpanded:(BOOL)flag animation:(BOOL) animation;

@end
