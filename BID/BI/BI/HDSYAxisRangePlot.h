//
//  HDSYAxisRangePlot.h
//  HDBI
//
//  Created by 毅 张 on 12-7-9.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//
#import "CorePlot-CocoaTouch.h"
#import "NSCoderExtensions.h"
#import <Foundation/Foundation.h>

///	@file

@class CPTLineStyle;
@class CPTMutableNumericData;
@class CPTNumericData;
@class CPTTradingRangePlot;
@class CPTFill;

///	@ingroup plotBindingsTradingRangePlot
/// @{
extern NSString *const CPTTradingRangePlotBindingXValues;
extern NSString *const CPTTradingRangePlotBindingOpenValues;
extern NSString *const CPTTradingRangePlotBindingHighValues;
extern NSString *const CPTTradingRangePlotBindingLowValues;
extern NSString *const CPTTradingRangePlotBindingCloseValues;
///	@}

/**
 *	@brief Enumeration of Quote plot render style types.
 **/
typedef enum HDSTradingRangePlotStyle {
    HDSTradingRangePlotStyleOHLC,       ///< Open-High-Low-Close (OHLC) plot.
    HDSTradingRangePlotStyleCandleStick ///< Candlestick plot.
}
HDSTradingRangePlotStyle;

/**
 *	@brief Enumeration of Quote plot data source field types.
 **/
typedef enum HDSTradingRangePlotField {
    HDSTradingRangePlotFieldX,    ///< X values.
    HDSTradingRangePlotFieldOpen, ///< Open values.
    HDSTradingRangePlotFieldHigh, ///< High values.
    HDSTradingRangePlotFieldLow,  ///< Low values.
    HDSTradingRangePlotFieldClose ///< Close values.
}
HDSTradingRangePlotField;

#pragma mark -

@interface HDSYAxisRangePlot : CPTPlot {
@private
	CPTLineStyle *lineStyle;
	CPTLineStyle *increaseLineStyle;
	CPTLineStyle *decreaseLineStyle;
	CPTFill *increaseFill;
	CPTFill *decreaseFill;
    
	HDSTradingRangePlotStyle plotStyle;
    
	CGFloat barWidth;
	CGFloat stickLength;
	CGFloat barCornerRadius;
}

@property (nonatomic, readwrite, copy) CPTLineStyle *lineStyle;
@property (nonatomic, readwrite, copy) CPTLineStyle *increaseLineStyle;
@property (nonatomic, readwrite, copy) CPTLineStyle *decreaseLineStyle;
@property (nonatomic, readwrite, copy) CPTFill *increaseFill;
@property (nonatomic, readwrite, copy) CPTFill *decreaseFill;
@property (nonatomic, readwrite, assign) HDSTradingRangePlotStyle plotStyle;
@property (nonatomic, readwrite, assign) CGFloat barWidth;    // In view coordinates
@property (nonatomic, readwrite, assign) CGFloat stickLength; // In view coordinates
@property (nonatomic, readwrite, assign) CGFloat barCornerRadius;

@property (nonatomic, readwrite, copy) CPTMutableNumericData *xValues;
@property (nonatomic, readwrite, copy) CPTMutableNumericData *openValues;
@property (nonatomic, readwrite, copy) CPTMutableNumericData *highValues;
@property (nonatomic, readwrite, copy) CPTMutableNumericData *lowValues;
@property (nonatomic, readwrite, copy) CPTMutableNumericData *closeValues;

-(void)drawCandleStickInContext:(CGContextRef)context y:(CGFloat)y open:(CGFloat)open close:(CGFloat)close high:(CGFloat)high low:(CGFloat)low alignPoints:(BOOL)alignPoints;
-(void)drawOHLCInContext:(CGContextRef)context y:(CGFloat)y open:(CGFloat)open close:(CGFloat)close high:(CGFloat)high low:(CGFloat)low alignPoints:(BOOL)alignPoints;

@end

