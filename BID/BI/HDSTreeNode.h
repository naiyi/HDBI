//
//  HDSTreeNode.h
//  MultiColumnTableView
//
//  Created by 毅 张 on 12-6-7.
//  Copyright (c) 2012年 Newegg.com. All rights reserved.
//

@interface HDSTreeNode : NSObject

@property (nonatomic, retain) NSMutableArray *children;
@property (nonatomic, retain, readonly) HDSTreeNode *parent; 
@property (nonatomic, readonly) BOOL isDirectory;
@property (nonatomic, readonly) NSInteger depth;
@property (nonatomic, readonly) BOOL directoryIsExpanded;
@property (nonatomic, retain, readonly) NSMutableDictionary *properties;

/// inits a node with a parent node
- (id) initWithProperties:(NSMutableDictionary *)properties parent:(HDSTreeNode *)parent expanded:(BOOL)expanded;


/// changes flag, loads children if needed.
- (void) expand;

/// changes flag, does not unload children
- (void) collapse;


/// children are unloaded here if needed
- (void) flushCache;

@end

