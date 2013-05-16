//
//  HDSCargoDelegate.h
//  HDBI
//
//  Created by 毅 张 on 12-7-19.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "SBJson.h"

@interface HDSCargoDelegate : NSObject<SBJsonStreamParserAdapterDelegate>

@property (readonly,strong,nonatomic) SBJsonStreamParser *parser;
@property (readonly,strong,nonatomic) SBJsonStreamParserAdapter *adapter;

- (void)parseData:(NSData *)data;

@end
