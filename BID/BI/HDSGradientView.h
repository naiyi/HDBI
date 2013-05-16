//
//  HDSGradientView.h
//  BI
//
//  Created by 毅 张 on 12-6-28.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

@interface HDSGradientView : UIView

- (id)initWithFrame:(CGRect)frame colors:(NSArray *)colors locations:(NSArray *)locations;
- (void)setupSmallViewGradientLayer;

@end
