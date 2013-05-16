//
//  HDSGradientView.m
//  BI
//
//  Created by 毅 张 on 12-6-28.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSGradientView.h"
#import <QuartzCore/QuartzCore.h>
#import "HDSUtil.h"

@implementation HDSGradientView

// 表格头渐变
- (id)initWithFrame:(CGRect)frame colors:(NSArray *)_colors locations:(NSArray *)_locations{
    self = [super initWithFrame:frame];
	if (self){
		CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
		NSMutableArray *colors = [[NSMutableArray alloc] initWithCapacity:3];
        for(int i= 0;i<_colors.count;i++){
            NSString * colorString = [_colors objectAtIndex:i];
            [colors addObject:(id)[HDSUtil colorFromString:colorString].CGColor];
        }
        gradientLayer.colors = colors;
        if(_locations != nil){
            gradientLayer.locations = _locations;
        }
		self.backgroundColor = [UIColor clearColor];
	}
	return self;
}

+ (Class)layerClass
{
	return [CAGradientLayer class];
}

// 主页视图背景渐变
- (void)setupSmallViewGradientLayer{
	CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
    if([HDSUtil skinType] == HDSSkinBlue){
        gradientLayer.colors =
        [NSArray arrayWithObjects:
         (id)[UIColor colorWithWhite:1 alpha:0.3].CGColor,
         (id)[UIColor colorWithWhite:1 alpha:0.3].CGColor,
         nil];
        gradientLayer.locations = 
        [NSArray arrayWithObjects:
         [NSNumber numberWithFloat:0],
         [NSNumber numberWithFloat:1],
         nil];
        self.backgroundColor = [UIColor whiteColor];
    }else{
        gradientLayer.colors =
        [NSArray arrayWithObjects:
         (id)[HDSUtil colorFromString:@"ffffff" alpha:0.3].CGColor,
         (id)[HDSUtil colorFromString:@"181818" alpha:0.3].CGColor,
         nil];
        gradientLayer.locations = 
        [NSArray arrayWithObjects:
         [NSNumber numberWithFloat:0],
         [NSNumber numberWithFloat:1],
         nil];
        self.backgroundColor = [UIColor clearColor];
    }
}

@end
