//
//  HDSTableViewCell.m
//  MultiColumnTableView
//
//  Created by 毅 张 on 12-6-12.
//  Copyright (c) 2012年 Newegg.com. All rights reserved.
//

#import "HDSTableViewCell.h"
#import <QuartzCore/QuartzCore.h>

@implementation HDSTableViewCell{
    CATransform3D _transform;
}

@synthesize triangleLayer;
@synthesize expanded = _expanded;

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        triangleLayer = [CALayer layer];
		
//        triangleLayer.borderColor = [UIColor redColor].CGColor;
//        triangleLayer.borderWidth = 1;
        
        [self.layer addSublayer:triangleLayer];
    }
    return self;
}

- (void) setExpanded:(BOOL)flag animation:(BOOL) animation{
	if (_expanded != flag) {
		_expanded = flag;
		
        triangleLayer.transform = CATransform3DIdentity;
        _transform = _expanded?CATransform3DRotate(CATransform3DIdentity, M_PI/2, 0, 0, 1.0):CATransform3DIdentity;
        if(animation){
            CABasicAnimation *ani = [CABasicAnimation animationWithKeyPath:@"transform"];
            [ani setTimingFunction:[CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut]];
            [ani setDuration:0.2];
            [ani setRepeatCount:1.0];
            [ani setAutoreverses:NO];
            [ani setFillMode:kCAFillModeForwards];	
            [ani setRemovedOnCompletion:NO];
            [ani setDelegate:self];
            [ani setToValue:[NSValue valueWithCATransform3D:_transform]];
            
//            NSString *animationKey = _expanded?@"expandingTransform":@"collapsingTransform";
            [triangleLayer addAnimation:ani forKey:@"transform"];
        }else{
            triangleLayer.transform = _transform;
        }
        
		
	}
}

//- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event{
//    NSLog(@"TableViewCell touch begin");
//}
//- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event{
//    NSLog(@"TableViewCell touch moves");
//}
//- (void)touchesEnded:(NSSet*)touches withEvent:(UIEvent*)event{
//    NSLog(@"TableViewCell touch ends");
//}
//- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event{
//    NSLog(@"TableViewCell touch cancels");
//}

- (void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag{
//    triangleLayer.transform = _transform;
}


@end
