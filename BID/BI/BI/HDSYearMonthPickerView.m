//
//  HDSYearMonthPickerView.m
//  HDBI
//
//  Created by 毅 张 on 12-7-13.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSYearMonthPickerView.h"

@implementation HDSYearMonthPickerView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

// 自定义pickerView样式
//- (void)drawRect:(CGRect)rect
//{
//    UIImageView *img = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 320, 234)];
//    img.image = [UIImage imageNamed:@"Default-Landscape~ipad.png"];
//    [self addSubview:img];
//    
//    //4-选择区域的背景颜色; 0-大背景的颜色; 1-选择框左边的颜色; 2-? ;3-?; 5-滚动区域的颜色 回覆盖数据
//    //6-选择框的背景颜色 7-选择框左边的颜色 8-整个View的颜色 会覆盖所有的图片
//    UIView *v = [[self subviews] objectAtIndex:0];
//    [v setBackgroundColor:[UIColor clearColor]];
//    UIImageView *bgimg = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"Default-Portrait~ipad.png"]];
//    bgimg.frame = CGRectMake(-5, -3, 200, 55);
//    [v addSubview:bgimg];
//    
//    [self setNeedsDisplay];
//}

@end
