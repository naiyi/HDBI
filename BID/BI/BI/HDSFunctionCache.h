//
//  HDSFunctionCache.h
//  BI
//
//  Created by 毅 张 on 12-6-5.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HDSViewController.h"

@class HDSDashboardViewController;

@interface HDSFunctionCache : NSObject

@property (retain,nonatomic) NSMutableArray* fc0key;
@property (retain,nonatomic) NSMutableArray* fc1key;
@property (retain,nonatomic) NSMutableArray* fc2key;
@property (retain,nonatomic) NSMutableArray* fc0val;
@property (retain,nonatomic) NSMutableArray* fc1val;
@property (retain,nonatomic) NSMutableArray* fc2val;
@property (retain,nonatomic) NSMutableArray* fs0key;
@property (retain,nonatomic) NSMutableArray* fs1key;
@property (retain,nonatomic) NSMutableArray* fs2key;
@property (retain,nonatomic) NSMutableArray* fs0val;
@property (retain,nonatomic) NSMutableArray* fs1val;
@property (retain,nonatomic) NSMutableArray* fs2val;
@property (retain,nonatomic) NSMutableArray* mainPageFunctions;

+ (HDSFunctionCache *) sharedFunctionCache;
- (HDSViewController *) getViewControllerByKey:(NSString *)key; 
- (void) addViewController:(HDSViewController *)vc toKey:(NSString *)key;
- (HDSViewController *) getHomeViewControllerByKey:(NSString *)key; 
- (void) addHomeViewController:(HDSViewController *)vc toKey:(NSString *)key;
- (UIViewController *) getSmallViewControllerByKey:(NSString *)key; 
- (void) addSmallViewController:(UIViewController *)vc toKey:(NSString *)key;
- (void) clearFunctionCache;

@end
