//
//  HDSTableScrollView.m
//  HDBI
//
//  Created by 毅 张 on 12-7-12.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSTableScrollView.h"
#import "HDSTableViewCell.h"

@implementation HDSTableScrollView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.delaysContentTouches = false;
//        self.canCancelContentTouches = false;
    }
    return self;
}

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view{
//    NSLog(@"scrlView begin in %@",view.class);
    if( ([view isKindOfClass:[UILabel class]] && [view.superview isKindOfClass:[HDSTableViewCell class]]) || [view isKindOfClass:[HDSTableViewCell class]]){
        return true;
    }
    return [super touchesShouldBegin:touches withEvent:event inContentView:view];
    
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view{
//    NSLog(@"手指很快划过内部控件时，该调用不被执行");
//    NSLog(@"scrlView cancel in %@",view.class);
    if( ([view isKindOfClass:[UILabel class]] && [view.superview isKindOfClass:[HDSTableViewCell class]]) || [view isKindOfClass:[HDSTableViewCell class]]){
        return true;
    }
    return [super touchesShouldCancelInContentView:view];
}

//- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
//    NSLog(@"scrlView touch begin");
//}
//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
//    NSLog(@"scrlView touch moves");
//}
//- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event{
//    NSLog(@"scrlView touch ends");
//}
//- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
//    NSLog(@"scrlView touch cancelled");
//}

@end
