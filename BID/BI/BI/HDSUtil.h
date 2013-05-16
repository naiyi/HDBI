//
//  HDSUtil.h
//  BI
//
//  Created by 毅 张 on 12-5-31.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "HDSTreeNode.h"
#import "CorePlot-CocoaTouch.h"
#import "HDSPlotDelegate.h"
#import "HDSTableView.h"
#import "HDSGradientView.h"

typedef enum{
    HDSFontSizeBig,
    HDSFontSizeNormal,
    HDSFontSizeSmall,
    HDSFontSizeVerySmall
}HDSFontSize;

typedef enum{
    HDSDateYMD,
    HDSDateMD,
    HDSDateYMDHM,
    HDSDateMDHM
}HDSDateFormat;

typedef enum{
    HDSPieChart,
    HDSLineChart,
    HDSBarChart
}HDSChartTpye;

typedef enum{
    HDSSkinBlue,
    HDSSkinBlack
}HDSSkinType;

#define Animation_Duration 1
#define kFilename @"setting.plist"
#define Legend_Switch_Tag 999
#define Http_Request_Timeout 15.0
#define Offline_Test_User @"offline"
#define Offline_Test_Pass @"a"

@interface HDSUtil : NSObject

+ (NSString *) serverURL;
+ (void) checkDeviceOrientation:(UIDeviceOrientation) deviceOrientation;
+ (void) checkInterfaceOrientation:(UIInterfaceOrientation) interfaceOrientation;
+ (UIInterfaceOrientation) getInterfaceOrientationFromDeviceOrientation:(UIDeviceOrientation)deviceOrientation;
+ (void) showFrameDetail:(UIView *)view;
+ (void) showBoundsDetail:(UIView *)view;
+ (void) changeUIControlFont:(UIView *) aView toSize:(HDSFontSize)size height:(CGFloat) height;
+ (void) changeUIControlFont:(UIView *) aView toSize:(HDSFontSize)size;
+ (UIFont *) getFontBySize:(HDSFontSize) size;
+ (NSMutableArray *)loadPlainDataByColumns:(NSArray *) colNames;
+ (NSMutableArray *)loadTreeDataByColumns:(NSArray *) colNames;
+ (HDSTreeNode *) newTreeNodeWithParent:(HDSTreeNode *)parent colNames:(NSArray *) colNames;
+ (void)setTitle:(NSString *)title forGraph:(CPTGraph *)graph withFontSize:(CGFloat)fontSize;
+ (void)setPadding:(CGFloat)padding forGraph:(CPTGraph *)graph withBounds:(CGRect)bounds;
+ (void)setInnerPaddingTop:(CGFloat)top right:(CGFloat)right bottom:(CGFloat)bottom left:(CGFloat)left forGraph:(CPTGraph *)graph;
+ (CPTFill *)plotBackgroundFill;
+ (CPTColor *)plotTextColor;
+ (CPTTextStyle *)plotTextStyle:(CGFloat)fontSize;
+ (UIColor *)plotBorderColor;
+ (CPTLineStyle *)plotBorderStyle;
+ (void)setAxis:(CPTXYAxis *)axis titleFontSize:(CGFloat)titleFontSize labelFontSize:(CGFloat)labelFontSize;
+ (void) setAxis:(CPTXYAxis *)axis majorIntervalLength:(CGFloat)majorIntervalLength minorTicksPerInterval:(NSInteger)minorTicksPerInterval title:(NSString *)title titleOffset:(CGFloat)titleOffset titleFontSize:(CGFloat)titleFontSize labelFontSize:(CGFloat)labelFontSize;
+ (CABasicAnimation *)setAnimation:(NSString *)keyPath toLayer:(CALayer *)layer fromValue:(CGFloat) fromValue toValue:(CGFloat)toValue forKey:(NSString *)key;
+ (NSString *)formatDate:(NSDate *) date withFormatter:(HDSDateFormat) format;
+ (NSDate *)formatString:(NSString *)date withFormatter:(HDSDateFormat) format;
+ (void)setLegend:(CPTLegend *)_legend withCorner:(CGFloat)corner swatch:(CGFloat)swatch font:(CGFloat)font rowMargin:(CGFloat)rowMargin numberOfRows:(NSInteger)numberOfRows padding:(CGFloat) padding;
+ (HDSPlotDelegate *)getPlotDelegate;
+ (NSString *) convertDataToString:(NSObject *)data label:(UILabel *)label;
+ (NSString *) convertDataToString:(NSObject *)data;
+ (NSString *) settingFilePath;
+ (BOOL)isOffline;
+ (NSString *) formatChartDateLabel:(NSString *)xLabel;
+ (UIColor *) colorFromString:(NSString *)colorString;
+ (UIColor *) colorFromString:(NSString *)colorString alpha:(CGFloat) alpha;
+ (UIColor *) lineChartColorAtIndex:(NSInteger)index;
+ (UIColor *) lineChartPointColorAtIndex:(NSInteger)index;
+ (UIColor *) lineChartBeginColor;
+ (UIColor *) lineChartEndColor;
+ (UIColor *) barChartBeginColorAtIndex:(NSInteger)index;
+ (UIColor *) barChartEndColorAtIndex:(NSInteger)index;
+ (CPTGradient *) barChartGradientAtIndex:(NSInteger)index;
+ (CPTGradient *) pieChartGradientAtIndex:(NSInteger)index;
+ (CPTGradient *) pieChartOverlay;
+ (HDSTableView *) addTableViewInContainer:(UIView *)container smallView:(BOOL)isSmallView;
+ (HDSGradientView *)getTableViewMultiHeaderBackgroundView;
+ (HDSGradientView *)getTableViewSelectedRowBackgroundView;
+ (UIColor *)getTableViewSelectedRowPureColor;
+ (HDSGradientView *)getMenuSelectedBackgroundView;
+ (void) setButtonBackground:(NSArray *)btns;
+ (void) loadAllCode;
+ (HDSSkinType) skinType;
+ (NSMutableDictionary *) getSetting;
+ (void) clearSetting;
+ (UIImage *)loadImageSkin:(HDSSkinType)skin imageName:(NSString *)imageName;
+ (void) setSegmentSkin:(HDSSkinType)skin;
+ (void) changeSegment:(UISegmentedControl *)seg textAttributeBySkin:(HDSSkinType)skin;
@end
