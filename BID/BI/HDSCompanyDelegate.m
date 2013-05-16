//
//  HDSCompanyDelegate.m
//  HDBI
//
//  Created by 毅 张 on 12-7-19.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSCompanyDelegate.h"
#import "HDSCompanyViewController.h"

@implementation HDSCompanyDelegate
    
@synthesize adapter,parser;

- (id)init{
    if(self = [super init]){
        adapter = [[SBJsonStreamParserAdapter alloc] init];
        adapter.delegate = self;
        parser = [[SBJsonStreamParser alloc] init];
        parser.delegate = adapter;
    }
    return self;
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    SBJsonStreamParserStatus status = [parser parse:data];
	if (status == SBJsonStreamParserError) {
		NSLog(@"The parser encountered an error: %@ in %@", parser.error,@"加载公司代码");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data");
	} else{
        //        NSLog(@"Parser over.");
    }
}

- (void)parseData:(NSData *)data {
    SBJsonStreamParserStatus status = [parser parse:data];
	if (status == SBJsonStreamParserError) {
		NSLog(@"The parser encountered an error: %@ in %@", parser.error,@"加载公司代码");
	} else if (status == SBJsonStreamParserWaitingForData) {
		NSLog(@"Parser waiting for more data");
	} else{
        //        NSLog(@"Parser over.");
    }
}

- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
//    NSDictionary *data;
//    for(int i=0; i<array.count; i++){
//        data = [array objectAtIndex:i];
//    }
    [HDSCompanyViewController setCompanys:array];
}

- (void)parser:(SBJsonStreamParser*)parser foundObject:(NSDictionary*)dict{
    
}

@end
