//
//  HDSUtil.m
//  BI
//
//  Created by 毅 张 on 12-5-31.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSUtil.h"
#import "HDSPlotDelegate.h"
#import "HDSCompanyViewController.h"
#import "HDSCargoViewController.h"
#import "HDSMasterViewController.h"

@implementation HDSUtil

static NSString *serverURL;
static NSDateFormatter *dateFormatter;
static HDSPlotDelegate *plotDelegate;
static NSArray *beginColors;
static NSArray *endColors;
static NSArray *barGradientColors;
static NSArray *pieGradientColors;
static NSMutableDictionary *setting;

+ (NSString *) serverURL{
    @synchronized(self){
		if (serverURL == nil ) {
//            serverURL = @"http://10.18.13.216:8080";
//            serverURL = @"http://10.18.8.21:8088";
//            serverURL = @"http://localhost:8080";
//            serverURL = @"http://10.18.3.100:8088";
            serverURL = @"http://221.0.92.90:18088";
//            serverURL = @"http://192.168.18.14:8080";
		}
	}
	return serverURL;
}

#pragma mark - orientatino test
+ (void) checkDeviceOrientation:(UIDeviceOrientation) deviceOrientation{
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            NSLog(@"====device portrait");
            break;
        case UIDeviceOrientationPortraitUpsideDown:
            NSLog(@"====device portrait reverse");
            break;
        case UIDeviceOrientationLandscapeLeft:
            NSLog(@"====device landscape left");
            break;
        case UIDeviceOrientationLandscapeRight:
            NSLog(@"====device landscape right");
            break;
        default:
            NSLog(@"====device not four orientation");
            break;
    }
}

+ (void) checkInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation{
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortrait:
            NSLog(@"====interface portrait");
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            NSLog(@"====interface portrait reverse");
            break;
        case UIInterfaceOrientationLandscapeLeft:
            NSLog(@"====interface landscape left");
            break;
        case UIInterfaceOrientationLandscapeRight:
            NSLog(@"====interface landscape right");
            break;
        default:
            NSLog(@"====interface not four orientation");
            break;
    }
}

+ (UIInterfaceOrientation) getInterfaceOrientationFromDeviceOrientation:(UIDeviceOrientation)deviceOrientation{
    switch (deviceOrientation) {
        case UIDeviceOrientationPortrait:
            return UIInterfaceOrientationPortrait;
        case UIDeviceOrientationPortraitUpsideDown:
            return UIInterfaceOrientationPortraitUpsideDown;
        case UIDeviceOrientationLandscapeLeft:
            return UIInterfaceOrientationLandscapeRight;
        case UIDeviceOrientationLandscapeRight:
            return UIInterfaceOrientationLandscapeLeft;
        default:
            NSLog(@"====can't change from device to interface!");
            return UIInterfaceOrientationPortrait;
    }
}

+ (void) showFrameDetail:(UIView *)view{
//    NSLog(@"%@",NSStringFromCGRect(view.frame));
    NSLog(@"x:%g,y:%g,w:%g,h:%g",view.frame.origin.x,view.frame.origin.y,
          view.frame.size.width,view.frame.size.height);
}
+ (void) showBoundsDetail:(UIView *)view{
    NSLog(@"x:%g,y:%g,w:%g,h:%g",view.bounds.origin.x,view.bounds.origin.y,
          view.bounds.size.width,view.bounds.size.height);
}

#pragma mark - font
+ (void) changeUIControlFont:(UISegmentedControl *)seg toSize:(HDSFontSize)size height:(CGFloat)height{
    CGRect frame = seg.frame;
    frame.size.height = height;
    seg.frame = frame;
    // 设备版本号判断,5.0以上版本才能自定义segment背景以及textAttribute
    if ([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0){
        NSDictionary *attributes = [NSDictionary dictionaryWithObjectsAndKeys:[HDSUtil getFontBySize:size],UITextAttributeFont,nil];
        [seg setTitleTextAttributes:attributes forState:UIControlStateNormal];
    }
}

+ (void) changeSegment:(UISegmentedControl *)seg textAttributeBySkin:(HDSSkinType)skin{
    // 设备版本号判断,5.0以上版本才能自定义segment背景以及textAttribute
    if([[[UIDevice currentDevice] systemVersion] floatValue] >= 5.0){
        NSMutableDictionary *attributes = [[seg titleTextAttributesForState:UIControlStateNormal] mutableCopy];
        if ( skin == HDSSkinBlack){
            [attributes setObject:[UIColor colorWithWhite:1.0 alpha:0.8] forKey:UITextAttributeTextColor];
            [attributes setObject:[UIColor blackColor] forKey:UITextAttributeTextShadowColor];
            [seg setTitleTextAttributes:attributes forState:UIControlStateNormal];
            
            [seg setBackgroundImage:[HDSUtil loadImageSkin:HDSSkinBlack imageName:@"segment_unselected.png"]forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            [seg setBackgroundImage:[HDSUtil loadImageSkin:HDSSkinBlack imageName:@"segment_selected.png"]  forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
            [seg setDividerImage:[self loadImageSkin:HDSSkinBlack imageName:@"segment_center1.png"] forLeftSegmentState:UIControlStateSelected  rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            [seg setDividerImage:[self loadImageSkin:HDSSkinBlack imageName:@"segment_center2.png"] forLeftSegmentState:UIControlStateNormal  rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault]; 
            [seg setDividerImage:[self loadImageSkin:HDSSkinBlack imageName:@"segment_center3.png"] forLeftSegmentState:UIControlStateNormal  rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            // 调整文字偏移
            [seg setContentPositionAdjustment:UIOffsetMake(3,1) forSegmentType:UISegmentedControlSegmentLeft barMetrics:UIBarMetricsDefault];
            [seg setContentPositionAdjustment:UIOffsetMake(-3,1) forSegmentType:UISegmentedControlSegmentRight barMetrics:UIBarMetricsDefault];
        }else{
            [attributes removeObjectForKey:UITextAttributeTextColor];
            [attributes removeObjectForKey:UITextAttributeTextShadowColor];
            [seg setTitleTextAttributes:attributes forState:UIControlStateNormal];
            
            [seg setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            [seg setBackgroundImage:nil forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
            [seg setDividerImage:nil forLeftSegmentState:UIControlStateSelected  rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            [seg setDividerImage:nil forLeftSegmentState:UIControlStateNormal  rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
            [seg setDividerImage:nil forLeftSegmentState:UIControlStateNormal  rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
            
            [seg setContentPositionAdjustment:UIOffsetMake(0,0) forSegmentType:UISegmentedControlSegmentLeft barMetrics:UIBarMetricsDefault];
            [seg setContentPositionAdjustment:UIOffsetMake(0,0) forSegmentType:UISegmentedControlSegmentRight barMetrics:UIBarMetricsDefault];
        } 
    }
}

+ (void) changeUIControlFont:(UIView *) aView toSize:(HDSFontSize) size{
    [self changeUIControlFont:aView toSize:size height:31.0];
}

+ (void) setSegmentSkin:(HDSSkinType)skin{
    // 该方法在修改主题后不能理解生效，切换view之后才生效
//    if ([[[UIDevice currentDevice] systemVersion] floatValue] < 5.0)
//        return ;
//    if (skin == HDSSkinBlack){
//        [[UISegmentedControl appearance] setBackgroundImage:[HDSUtil loadImageSkin:HDSSkinBlack imageName:@"segment_unselected.png"]forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//        [[UISegmentedControl appearance] setBackgroundImage:[HDSUtil loadImageSkin:HDSSkinBlack imageName:@"segment_selected.png"]  forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
//        [[UISegmentedControl appearance] setDividerImage:[self loadImageSkin:HDSSkinBlack imageName:@"segment_center1.png"] forLeftSegmentState:UIControlStateSelected  rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//        [[UISegmentedControl appearance] setDividerImage:[self loadImageSkin:HDSSkinBlack imageName:@"segment_center2.png"] forLeftSegmentState:UIControlStateNormal  rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault]; 
//        [[UISegmentedControl appearance] setDividerImage:[self loadImageSkin:HDSSkinBlack imageName:@"segment_center3.png"] forLeftSegmentState:UIControlStateNormal  rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//        
//        [[UISegmentedControl appearance] setContentPositionAdjustment:UIOffsetMake(3,1) forSegmentType:UISegmentedControlSegmentLeft barMetrics:UIBarMetricsDefault];
//        [[UISegmentedControl appearance] setContentPositionAdjustment:UIOffsetMake(-3,1) forSegmentType:UISegmentedControlSegmentRight barMetrics:UIBarMetricsDefault];
//    }else{
//        [[UISegmentedControl appearance] setBackgroundImage:nil forState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//        [[UISegmentedControl appearance] setBackgroundImage:nil forState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
//        [[UISegmentedControl appearance] setDividerImage:nil forLeftSegmentState:UIControlStateSelected  rightSegmentState:UIControlStateNormal barMetrics:UIBarMetricsDefault];
//        [[UISegmentedControl appearance] setDividerImage:nil forLeftSegmentState:UIControlStateNormal  rightSegmentState:UIControlStateSelected barMetrics:UIBarMetricsDefault];
//        
//        [[UISegmentedControl appearance] setContentPositionAdjustment:UIOffsetMake(0,0) forSegmentType:UISegmentedControlSegmentLeft barMetrics:UIBarMetricsDefault];
//        [[UISegmentedControl appearance] setContentPositionAdjustment:UIOffsetMake(0,0) forSegmentType:UISegmentedControlSegmentRight barMetrics:UIBarMetricsDefault];
//    }
}

+ (UIFont *) getFontBySize:(HDSFontSize) size{
    CGFloat _size = 12.0f;
    switch (size) {
        case HDSFontSizeBig:_size = 18.0f; break;
        case HDSFontSizeNormal:_size = 16.0f; break;
        case HDSFontSizeSmall:_size = 14.0f; break;
        case HDSFontSizeVerySmall:_size = 12.0f; break;
        default:    break;
    }
    return [UIFont fontWithName:@"STHeitiSC-Medium" size:_size];
}


#pragma mark - table data
+ (NSMutableArray *)loadTreeDataByColumns:(NSArray *) colNames{
    NSMutableArray *rootArray = [[NSMutableArray alloc] init];
    for (int i=0; i<2; i++) {
        HDSTreeNode *pNode = [self newTreeNodeWithParent:nil colNames:colNames];
        [rootArray addObject:pNode];
        for(int j=0;j<2;j++){
            HDSTreeNode *sonNode = [self newTreeNodeWithParent:pNode colNames:colNames];
            [[pNode children] addObject:sonNode];
            for(int k=0;k<5;k++){
                HDSTreeNode *childNode = [self newTreeNodeWithParent:sonNode colNames:colNames];
                [[sonNode children] addObject:childNode];
            }
        }
    }
    return rootArray;
}

+ (NSMutableArray *)loadPlainDataByColumns:(NSArray *) colNames{
    NSMutableArray *rootArray = [[NSMutableArray alloc] init];
    for (int i=0; i<20; i++) {
        HDSTreeNode *pNode = [self newTreeNodeWithParent:nil colNames:colNames];
        [rootArray addObject:pNode];
    }
    return rootArray;
}

+ (HDSTreeNode *) newTreeNodeWithParent:(HDSTreeNode *)parent colNames:(NSArray *) colNames{
    
    NSMutableDictionary *properties = [[NSMutableDictionary alloc] init ];
    NSInteger count = [colNames count];
    for(int i=0; i<count; i++){
        [properties setObject:[colNames objectAtIndex:i]  forKey:[@"col" stringByAppendingFormat:@"%i",i+1] ];
    }
    HDSTreeNode *node = [[HDSTreeNode alloc] initWithProperties:properties parent:parent expanded:YES];
    return node;
}

+ (HDSGradientView *)getTableViewMultiHeaderBackgroundView{
    if([HDSUtil skinType] == HDSSkinBlue){
        return [[HDSGradientView alloc] initWithFrame:CGRectZero 
            colors: [NSArray arrayWithObjects:@"0055e7",@"2495ed",@"0055e7",nil]
            locations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0],[NSNumber numberWithFloat:0.02f],[NSNumber numberWithFloat:1], nil]];
    }else{
        return [[HDSGradientView alloc] initWithFrame:CGRectZero 
            colors: [NSArray arrayWithObjects:@"414149",@"303039",@"2b2b35",@"2d2d37",nil]
            locations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0],[NSNumber numberWithFloat:0.5],[NSNumber numberWithFloat:0.5],[NSNumber numberWithFloat:1], nil]];
    }
}

+ (HDSGradientView *)getTableViewSelectedRowBackgroundView{
    return [[HDSGradientView alloc] initWithFrame:CGRectZero 
        colors: [NSArray arrayWithObjects:@"02a6e5",@"1a7ce4",nil]
        locations:nil];
}

// 不使用
+ (UIColor *)getTableViewSelectedRowPureColor{
    if([self skinType]==HDSSkinBlue){
        NSString *colorString = @"02a6e5";
        return [UIColor colorWithRed:strtoul([[colorString substringWithRange:NSMakeRange(0, 2)] UTF8String],0,16)/255.0f green:strtoul([[colorString substringWithRange:NSMakeRange(2, 2)] UTF8String],0,16)/255.0f blue:strtoul([[colorString substringWithRange:NSMakeRange(4, 2)] UTF8String],0,16)/255.0f alpha:1.0]; 
    }
    return [UIColor colorWithPatternImage:[[HDSUtil loadImageSkin:HDSSkinBlack imageName:@"table_selected_bg.png"] resizableImageWithCapInsets:UIEdgeInsetsMake(14, 0, 14, 0)] ];
}

+ (HDSGradientView *)getMenuSelectedBackgroundView{
    return [[HDSGradientView alloc] initWithFrame:CGRectZero 
        colors: [NSArray arrayWithObjects:@"ffffff",@"ff0000",@"434d57",nil]
        locations:[NSArray arrayWithObjects:[NSNumber numberWithFloat:0],[NSNumber numberWithFloat:0.02f],[NSNumber numberWithFloat:1], nil]];
}

#pragma mark - plot setting

+ (void)setTitle:(NSString *)title forGraph:(CPTGraph *)graph withFontSize:(CGFloat)fontSize{
    graph.identifier = title;
	graph.title = title;
	graph.titleTextStyle = [self plotTextStyle:fontSize];
    CGSize titleSize = [title sizeWithFont:[UIFont fontWithName:@"STHeitiSC-Medium" size:fontSize] constrainedToSize:CGSizeMake(600, MAXFLOAT) lineBreakMode:UILineBreakModeWordWrap];
    // graph的title默认位置在graph和plotAreaFrame中间
	graph.titleDisplacement		   = CGPointMake( 0.0f, titleSize.height/2);
	graph.titlePlotAreaFrameAnchor = CPTRectAnchorTop;
    graph.paddingTop = titleSize.height+5.0f;
}

+ (void)setPadding:(CGFloat)padding forGraph:(CPTGraph *)graph withBounds:(CGRect)bounds{
    CGFloat boundsPadding = padding!=-1 ? padding :round(bounds.size.width / (CGFloat)20.0);     
	graph.paddingLeft = boundsPadding;
    // paddingTop已根据title高度计算
//    graph.paddingTop = boundsPadding;
	graph.paddingRight	= boundsPadding;
	graph.paddingBottom = boundsPadding;
}

+ (void) setInnerPaddingTop:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom left:(CGFloat)left forGraph:(CPTGraph *)graph{
    graph.fill = [self plotBackgroundFill];
    graph.cornerRadius = 5.0f;
    graph.plotAreaFrame.fill		  = [CPTFill fillWithColor:[CPTColor clearColor]];
	graph.plotAreaFrame.paddingTop	  = top;
	graph.plotAreaFrame.paddingBottom = bottom;
	graph.plotAreaFrame.paddingLeft	  = left;
	graph.plotAreaFrame.paddingRight  = right;
    graph.plotAreaFrame.borderLineStyle = nil;
//    graph.plotAreaFrame.axisSet.borderLineStyle = nil;
	graph.plotAreaFrame.plotArea.fill = [CPTFill fillWithColor:[CPTColor clearColor]];
    graph.plotAreaFrame.plotArea.borderLineStyle = nil;
}
+ (CPTFill *)plotBackgroundFill{
    CPTGradient *backgroundGradient;
    if ([self skinType] == HDSSkinBlue) {
        backgroundGradient = [CPTGradient gradientWithBeginningColor:[CPTColor colorWithCGColor:[self colorFromString:@"dfdfdf" alpha:1.0].CGColor] endingColor:[CPTColor colorWithCGColor:[self colorFromString:@"ffffff" alpha:1.0].CGColor]];
    }else{
        backgroundGradient = [CPTGradient gradientWithBeginningColor:[CPTColor colorWithCGColor:[self colorFromString:@"0f0f0f" alpha:0.4].CGColor] endingColor:[CPTColor colorWithCGColor:[self colorFromString:@"ffffff" alpha:0.4].CGColor]];
    }
    backgroundGradient.angle = 270;
    return [CPTFill fillWithGradient:backgroundGradient];
}

+ (CPTColor *)plotTextColor{
    if([self skinType] == HDSSkinBlack){
        return [CPTColor colorWithComponentRed:1 green:1 blue:1 alpha:0.8];
    }else{
        return [CPTColor blackColor];
    }
}
+ (CPTTextStyle *)plotTextStyle:(CGFloat)fontSize{
    CPTMutableTextStyle *textStyle = [CPTMutableTextStyle textStyle];
	textStyle.color				   = [self plotTextColor];
	textStyle.fontName			   = @"STHeitiSC-Medium";
	textStyle.fontSize			   = fontSize;
    return textStyle;
}

+ (UIColor *)plotBorderColor{
    if([self skinType] == HDSSkinBlack){
        return [UIColor colorWithWhite:1.0f alpha:0.5];
    }else{
        return [UIColor blackColor];
    }
}
+ (CPTLineStyle *)plotBorderStyle{
    CPTMutableLineStyle *barLineStyle = [[CPTMutableLineStyle alloc] init];
	barLineStyle.lineWidth = 1.0;
	barLineStyle.lineColor = [CPTColor colorWithCGColor:[HDSUtil plotBorderColor].CGColor];
	return barLineStyle;
}

+ (void) setAxis:(CPTXYAxis *)axis majorIntervalLength:(CGFloat)majorIntervalLength minorTicksPerInterval:(NSInteger)minorTicksPerInterval title:(NSString *)title titleOffset:(CGFloat)titleOffset titleFontSize:(CGFloat)titleFontSize labelFontSize:(CGFloat)labelFontSize{

    [self setAxis:axis titleFontSize:titleFontSize labelFontSize:labelFontSize];
	axis.separateLayers			  = YES;
	axis.orthogonalCoordinateDecimal = CPTDecimalFromDouble(0.0);
    if(majorIntervalLength != 0){
        axis.majorIntervalLength     = CPTDecimalFromDouble(majorIntervalLength);
        axis.minorTicksPerInterval   = minorTicksPerInterval;
    } else{
        axis.labelingPolicy		     = CPTAxisLabelingPolicyAutomatic;
        axis.minorTicksPerInterval   = minorTicksPerInterval;
    }
    axis.tickDirection				 = CPTSignNegative;
	axis.majorTickLength			 = 4.0;
	axis.minorTickLength			 = 2.0;
    if(title){
        axis.title					 = title;
        axis.titleOffset		     = titleOffset;
    }
}

+ (void)setAxis:(CPTXYAxis *)axis titleFontSize:(CGFloat)titleFontSize labelFontSize:(CGFloat)labelFontSize{
    CPTMutableLineStyle *axisLineStyle = [CPTMutableLineStyle lineStyle];
	axisLineStyle.lineWidth = 1.0;
    axisLineStyle.lineColor = [self plotTextColor];
	axisLineStyle.lineCap	= kCGLineCapRound;
    
	CPTMutableTextStyle *axisTitleTextStyle = [CPTMutableTextStyle textStyle];
	axisTitleTextStyle.fontName = @"STHeitiSC-Medium";
	axisTitleTextStyle.fontSize = titleFontSize;
    axisTitleTextStyle.color = [self plotTextColor];
    
    CPTMutableTextStyle *labelTextStyle = [CPTMutableTextStyle textStyle];
    labelTextStyle.fontName = @"STHeitiSC-Medium";
    labelTextStyle.fontSize = labelFontSize;
    labelTextStyle.color = [HDSUtil plotTextColor];
    
    axis.axisLineStyle				 = axisLineStyle;
	axis.majorTickLineStyle		     = axisLineStyle;
//    axis.majorGridLineStyle          = axisLineStyle;
    axis.labelTextStyle              = labelTextStyle;
    axis.titleTextStyle              = axisTitleTextStyle;
}

// 柱状图动画
+ (CABasicAnimation *)setAnimation:(NSString *)keyPath toLayer:(CALayer *)layer fromValue:(CGFloat) fromValue toValue:(CGFloat)toValue forKey:(NSString *)key{
    CABasicAnimation *anim =[CABasicAnimation animationWithKeyPath:keyPath];
    anim.duration = Animation_Duration;
    // 修改为true 2012-9-28
    anim.removedOnCompletion = true;
    anim.fillMode = kCAFillModeForwards;
    anim.fromValue = [NSNumber numberWithFloat:fromValue];
    anim.toValue = [NSNumber numberWithFloat:toValue]; 
    anim.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseOut];
    
    if([keyPath isEqualToString:@"transform.scale.y"]){
        layer.position = CGPointMake(layer.position.x,0.0);
        layer.anchorPoint = CGPointMake(0.5, 0.0); 
    }else if([keyPath isEqualToString:@"transform.scale.x"]){
        layer.position = CGPointMake(0.0,layer.position.y);
        layer.anchorPoint = CGPointMake(0.0, 0.5); 
    }
    [layer addAnimation:anim forKey:key];
    return anim;
}
+ (void)setLegend:(CPTLegend *)_legend withCorner:(CGFloat)corner swatch:(CGFloat)swatch font:(CGFloat)font rowMargin:(CGFloat)rowMargin numberOfRows:(NSInteger)numberOfRows padding:(CGFloat) padding{
    _legend.cornerRadius = corner;
	_legend.swatchSize	 = CGSizeMake(swatch, swatch);
	_legend.textStyle		= [self plotTextStyle:font]; 
	_legend.rowMargin		= rowMargin;
	_legend.numberOfRows	= numberOfRows;
	_legend.paddingLeft	= padding;
	_legend.paddingTop	= padding;
	_legend.paddingRight= padding;
	_legend.paddingBottom = padding;
}
+ (UIColor *) colorFromString:(NSString *)colorString{
    return [self colorFromString:colorString alpha:1.0f];
}
+ (UIColor *) colorFromString:(NSString *)colorString alpha:(CGFloat) alpha{
    return [UIColor colorWithRed:strtoul([[colorString substringWithRange:NSMakeRange(0, 2)] UTF8String],0,16)/255.0f green:strtoul([[colorString substringWithRange:NSMakeRange(2, 2)] UTF8String],0,16)/255.0f blue:strtoul([[colorString substringWithRange:NSMakeRange(4, 2)] UTF8String],0,16)/255.0f alpha:alpha];
}

+ (UIColor *) lineChartColorAtIndex:(NSInteger)index{
    switch (index%3) {
        case 0: return [self colorFromString:@"fc8f00"];
        case 1: return [self colorFromString:@"00aaea"];
        case 2: return [self colorFromString:@"83c147"];
        default:return nil;
    }
}

+ (UIColor *) lineChartPointColorAtIndex:(NSInteger)index {
    switch (index%3) {
        case 0: return [self colorFromString:@"fc8f00"];
        case 1: return [self colorFromString:@"00aaea"];
        case 2: return [self colorFromString:@"83c147"];
        default:return nil;
    }
}

+ (UIColor *) lineChartBeginColor{
    NSString *sColor = @"2a94f2";
    return [self colorFromString:sColor];
}
+ (UIColor *) lineChartEndColor{
    NSString *sColor = @"bec3bf";
    return [self colorFromString:sColor];
}

+ (UIColor *) barChartBeginColorAtIndex:(NSInteger)index{
    @synchronized(self){
        if(beginColors == nil){
            beginColors = [NSArray arrayWithObjects:@"1c91fc",@"d5fb0d",@"fc182f",@"fecb94",@"fe19ce",@"36fde1",@"c1b2b2",@"fc9217", nil];
        }
    }
    return [self getColorSection:0 AtIndex:index%8];
}

+ (UIColor *) barChartEndColorAtIndex:(NSInteger)index{
    @synchronized(self){
        if(endColors == nil){
            endColors = [NSArray arrayWithObjects:@"115fa6",@"94ae0a",@"a61120",@"ff8809",@"a61187",@"24ad9a",@"7c7474",@"a66111", nil];
        }
    }
    return [self getColorSection:1 AtIndex:index%8];
}

+ (CPTGradient *) barChartGradientAtIndex:(NSInteger)index{
    @synchronized(self){
        if(barGradientColors == nil){
            barGradientColors = [NSArray arrayWithObjects:
                [NSArray arrayWithObjects:@"024667",@"a36015",@"a61120",@"ff8809",@"a61187",@"24ad9a",@"7c7474",@"a66111", nil],
                [NSArray arrayWithObjects:@"3e82a3",@"d69348",@"fc182f",@"fecb94",@"fe19ce",@"36fde1",@"c1b2b2",@"fc9217", nil],
                [NSArray arrayWithObjects:@"024667",@"a36015",@"a61120",@"ff8809",@"a61187",@"24ad9a",@"7c7474",@"a66111", nil]
                ,nil];
        }
    }
    CPTGradient *newInstance = [[CPTGradient alloc] init];
    newInstance = [newInstance addColorStop:[CPTColor colorWithCGColor:[self colorFromString:[[barGradientColors objectAtIndex:0] objectAtIndex:index%8]].CGColor] atPosition:0.0];
    newInstance = [newInstance addColorStop:[CPTColor colorWithCGColor:[self colorFromString:[[barGradientColors objectAtIndex:1] objectAtIndex:index%8]].CGColor] atPosition:0.5];
    newInstance = [newInstance addColorStop:[CPTColor colorWithCGColor:[self colorFromString:[[barGradientColors objectAtIndex:2] objectAtIndex:index%8]].CGColor] atPosition:1.0];
	return newInstance;
}

+ (CPTGradient *) pieChartGradientAtIndex:(NSInteger)index{
    @synchronized(self){
        if(pieGradientColors == nil){
            pieGradientColors = [NSArray arrayWithObjects:
                [NSArray arrayWithObjects:@"024667",@"a36015",@"a61120",@"ff8809",@"a61187",@"24ad9a",@"7c7474",@"a66111", nil],
                [NSArray arrayWithObjects:@"3e82a3",@"d69348",@"fc182f",@"fecb94",@"fe19ce",@"36fde1",@"c1b2b2",@"fc9217", nil]
                ,nil];
        }
    }
    CPTGradient *newInstance = [[CPTGradient alloc] init];
    newInstance = [newInstance addColorStop:[CPTColor colorWithCGColor:[self colorFromString:[[pieGradientColors objectAtIndex:0] objectAtIndex:index%8]].CGColor] atPosition:0.0];
    newInstance = [newInstance addColorStop:[CPTColor colorWithCGColor:[self colorFromString:[[pieGradientColors objectAtIndex:1] objectAtIndex:index%8]].CGColor] atPosition:0.5];
	return newInstance;
}

+ (CPTGradient *) pieChartOverlay{
    CPTGradient *overlayGradient = [[CPTGradient alloc] init];
	overlayGradient.gradientType = CPTGradientTypeRadial;
	overlayGradient				 = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.0] atPosition:0.0];
	overlayGradient				 = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.3] atPosition:0.8];
	overlayGradient				 = [overlayGradient addColorStop:[[CPTColor blackColor] colorWithAlphaComponent:0.7] atPosition:1.0];
    return overlayGradient;
}

+ (UIColor *)getColorSection:(NSInteger)section AtIndex:(NSInteger)index{
    NSString *sColor = section==0?[beginColors objectAtIndex:index]:[endColors objectAtIndex:index];
    return [self colorFromString:sColor];
}

#pragma mark - date util
+ (NSString *)formatDate:(NSDate *) date withFormatter:(HDSDateFormat) format{
    if(dateFormatter == nil){
        dateFormatter = [[NSDateFormatter alloc] init];
    }
    NSString *formatString;
    switch (format) {
        case HDSDateYMD:    formatString = @"yyyy/MM/dd";  break;
        case HDSDateMD:     formatString = @"MM/dd";  break;  
        case HDSDateYMDHM:  formatString = @"yyyy/MM/dd HH:mm";  break;  
        case HDSDateMDHM:   formatString = @"MM/dd HH:mm";  break;  
        default:    break;
    }
    [dateFormatter setDateFormat:formatString];
    return [dateFormatter stringFromDate:date];
}
+ (NSDate *)formatString:(NSString *)date withFormatter:(HDSDateFormat) format{
    if(dateFormatter == nil){
        dateFormatter = [[NSDateFormatter alloc] init];
    }
    NSString *formatString;
    switch (format) {
        case HDSDateYMD:    formatString = @"yyyy/MM/dd";  break;
        case HDSDateMD:     formatString = @"MM/dd";  break;  
        case HDSDateYMDHM:  formatString = @"yyyy/MM/dd HH:mm";  break;  
        case HDSDateMDHM:   formatString = @"MM/dd HH:mm";  break;  
        default:    break;
    }
    [dateFormatter setDateFormat:formatString];
    return [dateFormatter dateFromString:date];
}

+ (NSString *) formatChartDateLabel:(NSString *)xLabel{
    if(xLabel.length == 6){
        return [NSString stringWithFormat:@"%@/%i",[xLabel substringWithRange:NSMakeRange(2,2)],[[xLabel substringWithRange:NSMakeRange(4,2)] intValue]];
    }else if(xLabel.length == 13){
        return [NSString stringWithFormat:@"%@/%i-%@/%i",[xLabel substringWithRange:NSMakeRange(2,2)],[[xLabel substringWithRange:NSMakeRange(4,2)] intValue],[xLabel substringWithRange:NSMakeRange(9,2)],[[xLabel substringWithRange:NSMakeRange(11,2)] intValue]];
    }else{
        return @"yyyyMMdd";
    }
}

#pragma mark - else
+ (HDSPlotDelegate *)getPlotDelegate{
    if(plotDelegate == nil){
        plotDelegate = [[HDSPlotDelegate alloc] init];
    }
    return plotDelegate;
}

+ (NSString *) convertDataToString:(NSObject *)data label:(UILabel *)label{
    if([data isKindOfClass:[NSNumber class]]){
        if(label) label.textAlignment = UITextAlignmentRight;
//        return [(NSNumber *)data stringValue];
        return [NSNumberFormatter localizedStringFromNumber:(NSNumber *)data numberStyle:NSNumberFormatterDecimalStyle];
    }else if([data isKindOfClass:[NSString class]]){
        if(label) label.textAlignment = UITextAlignmentLeft;
        return (NSString *)data;
    }else{
//        NSLog(@"未知的数据类型");
        return @"";
    }
}

+ (NSString *) convertDataToString:(NSObject *)data{
    return [self convertDataToString:data label:nil];
}

#pragma mark - 配置文件
+ (NSString *)settingFilePath {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:kFilename];
}

+ (BOOL)isOffline{
    if(setting == nil){
        setting = [[NSMutableDictionary alloc] initWithContentsOfFile:[self settingFilePath]];
    }
    NSString *userName = [setting objectForKey:@"userName"];
    if ([userName isEqualToString:Offline_Test_User]) {
        return true;
    }
    NSString *offlineKey = [userName stringByAppendingString:@"-offline"];
    return [(NSNumber *)[setting objectForKey:offlineKey] boolValue];
}

+ (HDSTableView *) addTableViewInContainer:(UIView *)tableContainer smallView:(BOOL)isSmallView{
//    CGRect frame = isSmallView?tableContainer.bounds:CGRectInset(tableContainer.bounds,5.0f,5.0f);
    CGRect frame = tableContainer.bounds;
    HDSTableView *tableView = [[HDSTableView alloc] initWithFrame:frame];
    tableView.boldSeperatorLineColor = [UIColor blackColor];
    tableView.normalSeperatorLineColor = [UIColor blackColor];
    tableView.boldSeperatorLineWidth = 2.0f;
    tableView.normalSeperatorLineWidth = 1.0f;
    tableView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    tableView.titleFont = isSmallView?[HDSUtil getFontBySize:HDSFontSizeSmall]:[HDSUtil getFontBySize:HDSFontSizeNormal];
    tableView.normalFont = isSmallView?[HDSUtil getFontBySize:HDSFontSizeVerySmall]:[HDSUtil getFontBySize:HDSFontSizeSmall];
    [tableContainer addSubview:tableView];
    tableContainer.layer.masksToBounds = YES;
    if(isSmallView){
        tableView.scrlView.bounces = false; // 主页的抖动会反映在GMGridView层，不知道为什么暂时关闭
        tableView.cellHeight = HDSTable_SmallCellHeight;
        tableView.layer.cornerRadius = Table_Corner_Small; 
        tableContainer.layer.cornerRadius = Table_Corner_Small;
    }else{
        tableView.cellHeight = HDSTable_DefaultCellHeight;
        tableView.layer.cornerRadius = Table_Corner; 
        tableContainer.layer.cornerRadius = Table_Corner;
    }
    return  tableView;
}

+ (void) setButtonBackground:(NSArray *)btns{
    UIImage *normal     = [UIImage imageNamed:@"select_normal.png"];
    UIImage *highlight  = [UIImage imageNamed:@"select_highlight.png"];
    
    for(UIButton *btn in btns){
//        if( [normal respondsToSelector:@selector(resizableImageWithCapInsets:)] ){
//            [btn setBackgroundImage:[normal resizableImageWithCapInsets:UIEdgeInsetsMake(0, x, 0, x)] forState:UIControlStateNormal];
//            [btn setBackgroundImage:[highlight resizableImageWithCapInsets:UIEdgeInsetsMake(0, x, 0, x)] forState:UIControlStateHighlighted];
//        } else {
            [btn setBackgroundImage:[normal stretchableImageWithLeftCapWidth:140 topCapHeight:0] forState:UIControlStateNormal];
            [btn setBackgroundImage:[highlight stretchableImageWithLeftCapWidth:140 topCapHeight:0] forState:UIControlStateHighlighted];
//        }
    }
}

// 加载所有代码表
+ (void) loadAllCode{
    @synchronized(self){
        [HDSCompanyViewController loadCompanys];
        [HDSCargoViewController loadCargos];
    }
}

+ (HDSSkinType) skinType{
    if(setting == nil){
        setting = [[NSMutableDictionary alloc] initWithContentsOfFile:[self settingFilePath]];
    }
    NSNumber *theme = (NSNumber *)[setting objectForKey:@"skin"];
    if(theme == nil){
        theme = [NSNumber numberWithInt:0];
        [setting setObject:theme  forKey:@"skin"];
        [setting writeToFile:[HDSUtil settingFilePath] atomically:YES];
    }
    switch ([theme intValue]) {
        case 0: return HDSSkinBlue;
        default:return HDSSkinBlack;
    }
}

// setting使用单态模式
+ (NSMutableDictionary *) getSetting{
    if(setting == nil){
        NSString *filePath = [HDSUtil settingFilePath];
        if ([[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            setting = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
        }else{
            setting = [[NSMutableDictionary alloc] initWithCapacity:10];
        }
    }
    return setting;
}

+ (void)clearSetting{
    setting = nil;
}

+ (UIImage *)loadImageSkin:(HDSSkinType)skin imageName:(NSString *)imageName{
    UIImage *image;
    NSString *themePath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:skin == HDSSkinBlue ? @"Theme/blue":@"Theme/black"] stringByAppendingPathComponent:imageName];
    image = [UIImage imageWithContentsOfFile:themePath ];
    if( image )
        return image;
    
    NSString *newThemePath ;
    // 图片名称有～ipad或者@2x~ipad的后缀
    if([[UIScreen mainScreen] scale] == 1){
        newThemePath = [[themePath substringToIndex: [themePath rangeOfString:@".png"].location] stringByAppendingString:@"~ipad.png"];
        image = [UIImage imageWithContentsOfFile:newThemePath ];
        if(image)
            return image;
    }
    newThemePath = [[themePath substringToIndex: [themePath rangeOfString:@".png"].location] stringByAppendingString:@"@2x~ipad.png"];
    return image = [UIImage imageWithContentsOfFile:newThemePath ];

}

@end
