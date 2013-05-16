//
//  HDSTextField.m
//  HDBI
//
//  Created by 毅 张 on 13-2-26.
//  Copyright (c) 2013年 烟台华东电子. All rights reserved.
//

#import "HDSTextField.h"

@implementation HDSTextField

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/
- (UIView *)inputView{
    UIView *v = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 100, 100)];
    [v setBackgroundColor:[UIColor colorWithWhite:0.7 alpha:1.0]];
    return v;
}

@end
