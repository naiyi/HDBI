//
//  HDSFunctionCache.m
//  BI
//
//  Created by 毅 张 on 12-6-5.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSFunctionCache.h"

@implementation HDSFunctionCache{
    NSMutableDictionary *functionsDict;
    NSMutableDictionary *functionsDictSmall;
    NSMutableDictionary *functionsDictHome;
}

@synthesize fc0key,fc1key,fc2key,fc0val,fc1val,fc2val;
@synthesize fs0key,fs1key,fs2key,fs0val,fs1val,fs2val;
@synthesize mainPageFunctions;
static HDSFunctionCache *sharedFunctionCache = nil;

+ (HDSFunctionCache *) sharedFunctionCache{
    @synchronized(self){
		if (sharedFunctionCache == nil ) {
			sharedFunctionCache = [[self alloc] init];
		}
	}
	return sharedFunctionCache;
}

-(id)init{
	if (self = [super init]){
        functionsDict = [[NSMutableDictionary alloc] init]; // 详情功能
        functionsDictSmall = [[NSMutableDictionary alloc] init];    //仪表盘功能
        functionsDictHome = [[NSMutableDictionary alloc] init]; //仪表盘放大后功能
    }
	return self;
}

- (HDSViewController *) getViewControllerByKey:(NSString *)key{
    return (HDSViewController *)[functionsDict valueForKey:key];
}

- (void) addViewController:(HDSViewController *)vc toKey:(NSString *)key{
    [functionsDict setValue:vc forKey:key];
}

- (HDSViewController *) getHomeViewControllerByKey:(NSString *)key{
    return (HDSViewController *)[functionsDictHome valueForKey:key];
}

- (void) addHomeViewController:(HDSViewController *)vc toKey:(NSString *)key{
    [functionsDictHome setValue:vc forKey:key];
}

- (UIViewController *) getSmallViewControllerByKey:(NSString *)key{
    return (UIViewController *)[functionsDictSmall valueForKey:key];
}

- (void) addSmallViewController:(UIViewController *)vc toKey:(NSString *)key{
    [functionsDictSmall setValue:vc forKey:key];
}

- (void) clearFunctionCache{
    [functionsDict removeAllObjects];
    [functionsDictSmall removeAllObjects];
    [functionsDictHome removeAllObjects];
}

@end
