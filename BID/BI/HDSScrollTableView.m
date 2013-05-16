//
//  HDSScrollTableView.m
//  HDBI
//
//  Created by 毅 张 on 12-7-26.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSScrollTableView.h"
#import "HDSTableViewCell.h"

@implementation HDSScrollTableView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
    }
    return self;
}

- (BOOL)touchesShouldBegin:(NSSet *)touches withEvent:(UIEvent *)event inContentView:(UIView *)view{
//    NSLog(@"uiview begin in %@",view.class);
    if( ([view isKindOfClass:[UILabel class]] && [view.superview isKindOfClass:[HDSTableViewCell class]]) || [view isKindOfClass:[HDSTableViewCell class]]){
        return true;
    }
    return [super touchesShouldBegin:touches withEvent:event inContentView:view];
    
}

- (BOOL)touchesShouldCancelInContentView:(UIView *)view{
    //    NSLog(@"手指很快划过内部控件时，该调用不被执行");
//    NSLog(@"uiview cancel in %@",view.class);
    if( ([view isKindOfClass:[UILabel class]] && [view.superview isKindOfClass:[HDSTableViewCell class]]) || [view isKindOfClass:[HDSTableViewCell class]]){
        return true;
    }
    return [super touchesShouldCancelInContentView:view];
}

//- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
//    NSLog(@"uiview touch begin");
//}
//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
//    NSLog(@"uiview touch moves");
//}
//- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event{
//    NSLog(@"uiview touch ends");
//}
//- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
//    NSLog(@"uiview touch cancelled");
//}




@end
