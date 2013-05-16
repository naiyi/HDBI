//
//  HDSTreeNode.m
//  MultiColumnTableView
//
//  Created by 毅 张 on 12-6-7.
//  Copyright (c) 2012年 Newegg.com. All rights reserved.
//

#import "HDSTreeNode.h"


@implementation HDSTreeNode

#pragma mark -
#pragma mark properties

@synthesize children = _children;
@synthesize parent = _parent;
@synthesize properties = _properties;
@synthesize depth = _depth;
@synthesize directoryIsExpanded = _expanded;

- (NSDictionary *)properties{
	if (!_properties) {
//		_properties = [self nonCashedProperties];
	}
	return _properties;
}

- (NSMutableArray *) children{
	if (!_children) {
        _children = [[NSMutableArray alloc] init];
        // 延迟加载子节点
//        for (NSString *path in paths) {
//            HDSTreeNode *childNode = [[HDSTreeNode alloc] initWithProperties: parent:self];
//            [_children addObject:childNode];
//        }
	}
	return _children;
}

- (BOOL) isDirectory{
	return [[self children] count] > 0 ;
}

- (NSInteger) depth{
	if (_depth == -1) {
		_depth = self.parent.depth + 1;
	}
	return _depth;
}


#pragma mark -
#pragma mark Life Cicle 

- (id) initWithProperties:(NSMutableDictionary *)properties parent:(HDSTreeNode *)parent expanded:(BOOL)expanded{
    // 因为直接给_properties实例变量赋值  而没有通过属性，所以必须显式调用retain
	if ((self = [super init])){
		_parent = parent;
		_properties = properties;
		_children = nil;
		_depth = parent == nil? 0: -1;
		_expanded = expanded;
//        [_properties retain];
	}
	return self;
}

#pragma mark -
#pragma mark public methods

- (void) expand{
    _expanded = YES;
}
- (void) collapse{
	_expanded = NO; 
}

- (void) flushCache{
//	if (!self.directoryIsExpanded) {
//		_children = nil;
//	}
//	_properties = nil;
}

NSString *space(int x){
	NSMutableString *res = [NSMutableString string];
	for (int i =0; i<x; i++) {
		[res appendString:@" "];
	}
	return res;
}

//- (NSString *) description{
//	return [NSString stringWithFormat:@"%@%@ %@ parent:%@", space(self.depth),self.isDirectory?@"D":@"F", self.properties,self.parent.properties];
//}
@end

