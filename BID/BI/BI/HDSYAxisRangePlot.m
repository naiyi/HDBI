#import "HDSYAxisRangePlot.h"

#import <stdlib.h>

/**	@defgroup plotAnimationTradingRangePlot Trading Range Plot
 *	@ingroup plotAnimation
 **/

/**	@if MacOnly
 *	@defgroup plotBindingsTradingRangePlot Trading Range Plot Bindings
 *	@ingroup plotBindings
 *	@endif
 **/

NSString *const HDSTradingRangePlotBindingXValues	  = @"xValues";     ///< X values.
NSString *const HDSTradingRangePlotBindingOpenValues  = @"openValues";  ///< Open price values.
NSString *const HDSTradingRangePlotBindingHighValues  = @"highValues";  ///< High price values.
NSString *const HDSTradingRangePlotBindingLowValues	  = @"lowValues";   ///< Low price values.
NSString *const HDSTradingRangePlotBindingCloseValues = @"closeValues"; ///< Close price values.

///	@cond
@interface HDSYAxisRangePlot()



@end

///	@endcond

#pragma mark -

@implementation HDSYAxisRangePlot

@dynamic xValues;
@dynamic openValues;
@dynamic highValues;
@dynamic lowValues;
@dynamic closeValues;

/** @property lineStyle
 *	@brief The line style used to draw candlestick or OHLC symbols.
 **/
@synthesize lineStyle;

/** @property increaseLineStyle
 *	@brief The line style used to outline candlestick symbols when close >= open.
 *	If <code>nil</code>, will use @link HDSTradingRangePlot::lineStyle lineStyle @endlink instead.
 **/
@synthesize increaseLineStyle;

/** @property decreaseLineStyle
 *	@brief The line style used to outline candlestick symbols when close < open.
 *	If <code>nil</code>, will use @link HDSTradingRangePlot::lineStyle lineStyle @endlink instead.
 **/
@synthesize decreaseLineStyle;

/** @property increaseFill
 *	@brief The fill used with a candlestick plot when close >= open.
 **/
@synthesize increaseFill;

/** @property decreaseFill
 *	@brief The fill used with a candlestick plot when close < open.
 **/
@synthesize decreaseFill;

/** @property plotStyle
 *	@brief The style of trading range plot drawn. The default is #HDSTradingRangePlotStyleOHLC.
 **/
@synthesize plotStyle;

/** @property barWidth
 *	@brief The width of bars in candlestick plots (view coordinates).
 *	@ingroup plotAnimationTradingRangePlot
 **/
@synthesize barWidth;

/** @property stickLength
 *	@brief The length of close and open sticks on OHLC plots (view coordinates).
 *	@ingroup plotAnimationTradingRangePlot
 **/
@synthesize stickLength;

/** @property barCornerRadius
 *	@brief The corner radius used for candlestick plots.
 *  Defaults to 0.0.
 *	@ingroup plotAnimationTradingRangePlot
 **/
@synthesize barCornerRadius;

/// @name Initialization
/// @{

/** @brief Initializes a newly allocated HDSTradingRangePlot object with the provided frame rectangle.
 *
 *	This is the designated initializer. The initialized layer will have the following properties:
 *	- @link HDSTradingRangePlot::plotStyle plotStyle @endlink = #HDSTradingRangePlotStyleOHLC
 *	- @link HDSTradingRangePlot::lineStyle lineStyle @endlink = default line style
 *	- @link HDSTradingRangePlot::increaseLineStyle increaseLineStyle @endlink = <code>nil</code>
 *	- @link HDSTradingRangePlot::decreaseLineStyle decreaseLineStyle @endlink = <code>nil</code>
 *	- @link HDSTradingRangePlot::increaseFill increaseFill @endlink = solid white fill
 *	- @link HDSTradingRangePlot::decreaseFill decreaseFill @endlink = solid black fill
 *	- @link HDSTradingRangePlot::barWidth barWidth @endlink = 5.0
 *	- @link HDSTradingRangePlot::stickLength stickLength @endlink = 3.0
 *	- @link HDSTradingRangePlot::barCornerRadius barCornerRadius @endlink = 0.0
 *	- @link CPTPlot::labelField labelField @endlink = #HDSTradingRangePlotFieldClose
 *
 *	@param newFrame The frame rectangle.
 *  @return The initialized HDSTradingRangePlot object.
 **/
-(id)initWithFrame:(CGRect)newFrame
{
	if ( (self = [super initWithFrame:newFrame]) ) {
		plotStyle		  = HDSTradingRangePlotStyleOHLC;
		lineStyle		  = [[CPTLineStyle alloc] init];
		increaseLineStyle = nil;
		decreaseLineStyle = nil;
		increaseFill	  = [(CPTFill *)[CPTFill alloc] initWithColor:[CPTColor whiteColor]];
		decreaseFill	  = [(CPTFill *)[CPTFill alloc] initWithColor:[CPTColor blackColor]];
		barWidth		  = 5.0;
		stickLength		  = 3.0;
		barCornerRadius	  = 0.0;
        
		self.labelField = HDSTradingRangePlotFieldClose;
	}
	return self;
}

///	@}

-(id)initWithLayer:(id)layer
{
	if ( (self = [super initWithLayer:layer]) ) {
		HDSYAxisRangePlot *theLayer = (HDSYAxisRangePlot *)layer;
        
		plotStyle		  = theLayer->plotStyle;
		lineStyle		  = theLayer->lineStyle ;
		increaseLineStyle = theLayer->increaseLineStyle ;
		decreaseLineStyle = theLayer->decreaseLineStyle ;
		increaseFill	  = theLayer->increaseFill ;
		decreaseFill	  = theLayer->decreaseFill ;
		barWidth		  = theLayer->barWidth;
		stickLength		  = theLayer->stickLength;
		barCornerRadius	  = theLayer->barCornerRadius;
	}
	return self;
}

-(void)encodeWithCoder:(NSCoder *)coder
{
	[super encodeWithCoder:coder];
    
	[coder encodeObject:self.lineStyle forKey:@"HDSTradingRangePlot.lineStyle"];
	[coder encodeObject:self.increaseLineStyle forKey:@"HDSTradingRangePlot.increaseLineStyle"];
	[coder encodeObject:self.decreaseLineStyle forKey:@"HDSTradingRangePlot.decreaseLineStyle"];
	[coder encodeObject:self.increaseFill forKey:@"HDSTradingRangePlot.increaseFill"];
	[coder encodeObject:self.decreaseFill forKey:@"HDSTradingRangePlot.decreaseFill"];
	[coder encodeInteger:self.plotStyle forKey:@"HDSTradingRangePlot.plotStyle"];
	[coder encodeCGFloat:self.barWidth forKey:@"HDSTradingRangePlot.barWidth"];
	[coder encodeCGFloat:self.stickLength forKey:@"HDSTradingRangePlot.stickLength"];
	[coder encodeCGFloat:self.barCornerRadius forKey:@"HDSTradingRangePlot.barCornerRadius"];
}

-(id)initWithCoder:(NSCoder *)coder
{
	if ( (self = [super initWithCoder:coder]) ) {
		lineStyle		  = [[coder decodeObjectForKey:@"HDSTradingRangePlot.lineStyle"] copy];
		increaseLineStyle = [[coder decodeObjectForKey:@"HDSTradingRangePlot.increaseLineStyle"] copy];
		decreaseLineStyle = [[coder decodeObjectForKey:@"HDSTradingRangePlot.decreaseLineStyle"] copy];
		increaseFill	  = [[coder decodeObjectForKey:@"HDSTradingRangePlot.increaseFill"] copy];
		decreaseFill	  = [[coder decodeObjectForKey:@"HDSTradingRangePlot.decreaseFill"] copy];
		plotStyle		  = [coder decodeIntegerForKey:@"HDSTradingRangePlot.plotStyle"];
		barWidth		  = [coder decodeCGFloatForKey:@"HDSTradingRangePlot.barWidth"];
		stickLength		  = [coder decodeCGFloatForKey:@"HDSTradingRangePlot.stickLength"];
		barCornerRadius	  = [coder decodeCGFloatForKey:@"HDSTradingRangePlot.barCornerRadius"];
	}
	return self;
}

#pragma mark -
#pragma mark Data Loading

///	@cond

-(void)reloadDataInIndexRange:(NSRange)indexRange
{
	[super reloadDataInIndexRange:indexRange];
    
	if ( self.dataSource ) {
		id newXValues = [self numbersFromDataSourceForField:HDSTradingRangePlotFieldX recordIndexRange:indexRange];
		[self cacheNumbers:newXValues forField:HDSTradingRangePlotFieldX atRecordIndex:indexRange.location];
		id newOpenValues = [self numbersFromDataSourceForField:HDSTradingRangePlotFieldOpen recordIndexRange:indexRange];
		[self cacheNumbers:newOpenValues forField:HDSTradingRangePlotFieldOpen atRecordIndex:indexRange.location];
		id newHighValues = [self numbersFromDataSourceForField:HDSTradingRangePlotFieldHigh recordIndexRange:indexRange];
		[self cacheNumbers:newHighValues forField:HDSTradingRangePlotFieldHigh atRecordIndex:indexRange.location];
		id newLowValues = [self numbersFromDataSourceForField:HDSTradingRangePlotFieldLow recordIndexRange:indexRange];
		[self cacheNumbers:newLowValues forField:HDSTradingRangePlotFieldLow atRecordIndex:indexRange.location];
		id newCloseValues = [self numbersFromDataSourceForField:HDSTradingRangePlotFieldClose recordIndexRange:indexRange];
		[self cacheNumbers:newCloseValues forField:HDSTradingRangePlotFieldClose atRecordIndex:indexRange.location];
	}
	else {
		self.xValues	 = nil;
		self.openValues	 = nil;
		self.highValues	 = nil;
		self.lowValues	 = nil;
		self.closeValues = nil;
	}
}

///	@endcond

#pragma mark -
#pragma mark Drawing

/// @cond

-(void)renderAsVectorInContext:(CGContextRef)theContext
{
	if ( self.hidden ) {
		return;
	}
    
	CPTMutableNumericData *locations = [self cachedNumbersForField:HDSTradingRangePlotFieldX];
	CPTMutableNumericData *opens	 = [self cachedNumbersForField:HDSTradingRangePlotFieldOpen];
	CPTMutableNumericData *highs	 = [self cachedNumbersForField:HDSTradingRangePlotFieldHigh];
	CPTMutableNumericData *lows		 = [self cachedNumbersForField:HDSTradingRangePlotFieldLow];
	CPTMutableNumericData *closes	 = [self cachedNumbersForField:HDSTradingRangePlotFieldClose];
    
	NSUInteger sampleCount = locations.numberOfSamples;
	if ( sampleCount == 0 ) {
		return;
	}
	if ( (opens == nil) || (highs == nil) || (lows == nil) || (closes == nil) ) {
		return;
	}
    
	if ( (opens.numberOfSamples != sampleCount) || (highs.numberOfSamples != sampleCount) || (lows.numberOfSamples != sampleCount) || (closes.numberOfSamples != sampleCount) ) {
		[NSException raise:CPTException format:@"Mismatching number of data values in trading range plot"];
	}
    
	[super renderAsVectorInContext:theContext];
	[self.lineStyle setLineStyleInContext:theContext];
    
	CGPoint openPoint, highPoint, lowPoint, closePoint;
	const CPTCoordinate independentCoord = CPTCoordinateY;
	const CPTCoordinate dependentCoord	 = CPTCoordinateX;
    
	CPTPlotArea *thePlotArea			  = self.plotArea;
	CPTPlotSpace *thePlotSpace			  = self.plotSpace;
	HDSTradingRangePlotStyle thePlotStyle = self.plotStyle;
	CGPoint originTransformed			  = [self convertPoint:self.frame.origin fromLayer:thePlotArea];
    
	CGContextBeginTransparencyLayer(theContext, NULL);
    
	if ( self.doublePrecisionCache ) {
		const double *locationBytes = (const double *)locations.data.bytes;
		const double *openBytes		= (const double *)opens.data.bytes;
		const double *highBytes		= (const double *)highs.data.bytes;
		const double *lowBytes		= (const double *)lows.data.bytes;
		const double *closeBytes	= (const double *)closes.data.bytes;
        
		for ( NSUInteger i = 0; i < sampleCount; i++ ) {
			double plotPoint[2];
			plotPoint[independentCoord] = *locationBytes++;
			if ( isnan(plotPoint[independentCoord]) ) {
				openBytes++;
				highBytes++;
				lowBytes++;
				closeBytes++;
				continue;
			}
            
			// open point
			plotPoint[dependentCoord] = *openBytes++;
			if ( isnan(plotPoint[dependentCoord]) ) {
				openPoint = CGPointMake(NAN, NAN);
			}
			else {
				openPoint = [thePlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:plotPoint];
			}
            
			// high point
			plotPoint[dependentCoord] = *highBytes++;
			if ( isnan(plotPoint[dependentCoord]) ) {
				highPoint = CGPointMake(NAN, NAN);
			}
			else {
				highPoint = [thePlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:plotPoint];
			}
            
			// low point
			plotPoint[dependentCoord] = *lowBytes++;
			if ( isnan(plotPoint[dependentCoord]) ) {
				lowPoint = CGPointMake(NAN, NAN);
			}
			else {
				lowPoint = [thePlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:plotPoint];
			}
            
			// close point
			plotPoint[dependentCoord] = *closeBytes++;
			if ( isnan(plotPoint[dependentCoord]) ) {
				closePoint = CGPointMake(NAN, NAN);
			}
			else {
				closePoint = [thePlotSpace plotAreaViewPointForDoublePrecisionPlotPoint:plotPoint];
			}
            
			CGFloat yCoord = openPoint.y;
			if ( isnan(yCoord) ) {
				yCoord = highPoint.y;
			}
			else if ( isnan(yCoord) ) {
				yCoord = lowPoint.y;
			}
			else if ( isnan(yCoord) ) {
				yCoord = closePoint.y;
			}
            
			if ( !isnan(yCoord) ) {
				// Draw
				switch ( thePlotStyle ) {
					case HDSTradingRangePlotStyleOHLC:
						[self drawOHLCInContext:theContext
											  y:yCoord + originTransformed.y
										   open:openPoint.x + originTransformed.x
										  close:closePoint.x + originTransformed.x
										   high:highPoint.x + originTransformed.x
											low:lowPoint.x + originTransformed.x
									alignPoints:self.alignsPointsToPixels];
						break;
                        
					case HDSTradingRangePlotStyleCandleStick:
						[self drawCandleStickInContext:theContext
													 y:yCoord + originTransformed.y
												  open:openPoint.x + originTransformed.x
												 close:closePoint.x + originTransformed.x
												  high:highPoint.x + originTransformed.x
												   low:lowPoint.x + originTransformed.x
										   alignPoints:self.alignsPointsToPixels];
						break;
                        
					default:
						[NSException raise:CPTException format:@"Invalid plot style in renderAsVectorInContext"];
						break;
				}
			}
		}
	}
	else {
		const NSDecimal *locationBytes = (const NSDecimal *)locations.data.bytes;
		const NSDecimal *openBytes	   = (const NSDecimal *)opens.data.bytes;
		const NSDecimal *highBytes	   = (const NSDecimal *)highs.data.bytes;
		const NSDecimal *lowBytes	   = (const NSDecimal *)lows.data.bytes;
		const NSDecimal *closeBytes	   = (const NSDecimal *)closes.data.bytes;
        
		for ( NSUInteger i = 0; i < sampleCount; i++ ) {
			NSDecimal plotPoint[2];
			plotPoint[independentCoord] = *locationBytes++;
			if ( NSDecimalIsNotANumber(&plotPoint[independentCoord]) ) {
				openBytes++;
				highBytes++;
				lowBytes++;
				closeBytes++;
				continue;
			}
            
			// open point
			plotPoint[dependentCoord] = *openBytes++;
			if ( NSDecimalIsNotANumber(&plotPoint[dependentCoord]) ) {
				openPoint = CGPointMake(NAN, NAN);
			}
			else {
				openPoint = [thePlotSpace plotAreaViewPointForPlotPoint:plotPoint];
			}
            
			// high point
			plotPoint[dependentCoord] = *highBytes++;
			if ( NSDecimalIsNotANumber(&plotPoint[dependentCoord]) ) {
				highPoint = CGPointMake(NAN, NAN);
			}
			else {
				highPoint = [thePlotSpace plotAreaViewPointForPlotPoint:plotPoint];
			}
            
			// low point
			plotPoint[dependentCoord] = *lowBytes++;
			if ( NSDecimalIsNotANumber(&plotPoint[dependentCoord]) ) {
				lowPoint = CGPointMake(NAN, NAN);
			}
			else {
				lowPoint = [thePlotSpace plotAreaViewPointForPlotPoint:plotPoint];
			}
            
			// close point
			plotPoint[dependentCoord] = *closeBytes++;
			if ( NSDecimalIsNotANumber(&plotPoint[dependentCoord]) ) {
				closePoint = CGPointMake(NAN, NAN);
			}
			else {
				closePoint = [thePlotSpace plotAreaViewPointForPlotPoint:plotPoint];
			}
            
			CGFloat yCoord = openPoint.y;
			if ( isnan(yCoord) ) {
				yCoord = highPoint.y;
			}
			else if ( isnan(yCoord) ) {
				yCoord = lowPoint.y;
			}
			else if ( isnan(yCoord) ) {
				yCoord = closePoint.y;
			}
            
			if ( !isnan(yCoord) ) {
				// Draw
				switch ( thePlotStyle ) {
					case HDSTradingRangePlotStyleOHLC:
						[self drawOHLCInContext:theContext
											  y:yCoord + originTransformed.y
										   open:openPoint.x + originTransformed.x
										  close:closePoint.x + originTransformed.x
										   high:highPoint.x + originTransformed.x
											low:lowPoint.x + originTransformed.x
									alignPoints:self.alignsPointsToPixels];
						break;
                        
					case HDSTradingRangePlotStyleCandleStick:
						[self drawCandleStickInContext:theContext
													 y:yCoord + originTransformed.y
												  open:openPoint.x + originTransformed.x
												 close:closePoint.x + originTransformed.x
												  high:highPoint.x + originTransformed.x
												   low:lowPoint.x + originTransformed.x
										   alignPoints:self.alignsPointsToPixels];
						break;
                        
					default:
						[NSException raise:CPTException format:@"Invalid plot style in renderAsVectorInContext"];
						break;
				}
			}
		}
	}
    
	CGContextEndTransparencyLayer(theContext);
}

-(void)drawCandleStickInContext:(CGContextRef)context
							  y:(CGFloat)y
						   open:(CGFloat)open
						  close:(CGFloat)close
						   high:(CGFloat)high
							low:(CGFloat)low
					alignPoints:(BOOL)alignPoints
{
	const CGFloat halfBarWidth		 = (CGFloat)0.5 * self.barWidth;
	CPTFill *currentBarFill			 = nil;
	CPTLineStyle *theBorderLineStyle = nil;
    
	if ( !isnan(open) && !isnan(close) ) {
		if ( open < close ) {
			theBorderLineStyle = self.increaseLineStyle;
			if ( !theBorderLineStyle ) {
				theBorderLineStyle = self.lineStyle;
			}
			currentBarFill = self.increaseFill;
		}
		else if ( open > close ) {
			theBorderLineStyle = self.decreaseLineStyle;
			if ( !theBorderLineStyle ) {
				theBorderLineStyle = self.lineStyle;
			}
			currentBarFill = self.decreaseFill;
		}
		else {
			theBorderLineStyle = self.lineStyle;
			currentBarFill	   = [CPTFill fillWithColor:theBorderLineStyle.lineColor];
		}
	}
	[theBorderLineStyle setLineStyleInContext:context];
	BOOL alignToUserSpace = (self.lineStyle.lineWidth > 0.0);
    
	// high - low only
	if ( !isnan(high) && !isnan(low) && ( isnan(open) || isnan(close) ) ) {
		CGPoint alignedHighPoint = CGPointMake(high,y);
		CGPoint alignedLowPoint	 = CGPointMake(low,y);
		if ( alignPoints ) {
			if ( alignToUserSpace ) {
				alignedHighPoint = CPTAlignPointToUserSpace(context, alignedHighPoint);
				alignedLowPoint	 = CPTAlignPointToUserSpace(context, alignedLowPoint);
			}
			else {
				alignedHighPoint = CPTAlignIntegralPointToUserSpace(context, alignedHighPoint);
				alignedLowPoint	 = CPTAlignIntegralPointToUserSpace(context, alignedLowPoint);
			}
		}
        
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathMoveToPoint(path, NULL, alignedHighPoint.x, alignedHighPoint.y);
		CGPathAddLineToPoint(path, NULL, alignedLowPoint.x, alignedLowPoint.y);
        
		CGContextBeginPath(context);
		CGContextAddPath(context, path);
		CGContextStrokePath(context);
        
		CGPathRelease(path);
	}
    
	// open-close
	if ( !isnan(open) && !isnan(close) ) {
		if ( currentBarFill || theBorderLineStyle ) {
			CGFloat radius = MIN(self.barCornerRadius, halfBarWidth);
			radius = MIN( radius, ABS(close - open) );
            
			CGPoint alignedPoint1 = CGPointMake(open,y + halfBarWidth);
			CGPoint alignedPoint2 = CGPointMake(close,y + halfBarWidth);
			CGPoint alignedPoint3 = CGPointMake(close,y);
			CGPoint alignedPoint4 = CGPointMake(close,y - halfBarWidth);
			CGPoint alignedPoint5 = CGPointMake(open,y - halfBarWidth);
			if ( alignPoints ) {
				if ( alignToUserSpace ) {
					alignedPoint1 = CPTAlignPointToUserSpace(context, alignedPoint1);
					alignedPoint2 = CPTAlignPointToUserSpace(context, alignedPoint2);
					alignedPoint3 = CPTAlignPointToUserSpace(context, alignedPoint3);
					alignedPoint4 = CPTAlignPointToUserSpace(context, alignedPoint4);
					alignedPoint5 = CPTAlignPointToUserSpace(context, alignedPoint5);
				}
				else {
					alignedPoint1 = CPTAlignIntegralPointToUserSpace(context, alignedPoint1);
					alignedPoint2 = CPTAlignIntegralPointToUserSpace(context, alignedPoint2);
					alignedPoint3 = CPTAlignIntegralPointToUserSpace(context, alignedPoint3);
					alignedPoint4 = CPTAlignIntegralPointToUserSpace(context, alignedPoint4);
					alignedPoint5 = CPTAlignIntegralPointToUserSpace(context, alignedPoint5);
				}
			}
            
			if ( open == close ) {
				// #285 Draw a cross with open/close values marked
				const CGFloat halfLineWidth = (CGFloat)0.5 * self.lineStyle.lineWidth;
                
				alignedPoint1.x -= halfLineWidth;
				alignedPoint2.x += halfLineWidth;
				alignedPoint3.x += halfLineWidth;
				alignedPoint4.x += halfLineWidth;
				alignedPoint5.x -= halfLineWidth;
			}
            
			CGMutablePathRef path = CGPathCreateMutable();
			CGPathMoveToPoint(path, NULL, alignedPoint1.x, alignedPoint1.y);
			CGPathAddArcToPoint(path, NULL, alignedPoint2.x, alignedPoint2.y, alignedPoint3.x, alignedPoint3.y, radius);
			CGPathAddArcToPoint(path, NULL, alignedPoint4.x, alignedPoint4.y, alignedPoint5.x, alignedPoint5.y, radius);
			CGPathAddLineToPoint(path, NULL, alignedPoint5.x, alignedPoint5.y);
			CGPathCloseSubpath(path);
            
			if ( currentBarFill ) {
				CGContextBeginPath(context);
				CGContextAddPath(context, path);
				[currentBarFill fillPathInContext:context];
			}
            
			if ( theBorderLineStyle ) {
				if ( !isnan(low) ) {
					if ( low < MIN(open, close) ) {
						CGPoint alignedStartPoint = CGPointMake(MIN(open, close),y );
						CGPoint alignedLowPoint	  = CGPointMake(low,y);
						if ( alignPoints ) {
							if ( alignToUserSpace ) {
								alignedStartPoint = CPTAlignPointToUserSpace(context, alignedStartPoint);
								alignedLowPoint	  = CPTAlignPointToUserSpace(context, alignedLowPoint);
							}
							else {
								alignedStartPoint = CPTAlignIntegralPointToUserSpace(context, alignedStartPoint);
								alignedLowPoint	  = CPTAlignIntegralPointToUserSpace(context, alignedLowPoint);
							}
						}
                        
						CGPathMoveToPoint(path, NULL, alignedStartPoint.x, alignedStartPoint.y);
						CGPathAddLineToPoint(path, NULL, alignedLowPoint.x, alignedLowPoint.y);
					}
				}
				if ( !isnan(high) ) {
					if ( high > MAX(open, close) ) {
						CGPoint alignedStartPoint = CGPointMake(MAX(open, close),y );
						CGPoint alignedHighPoint  = CGPointMake(high,y);
						if ( alignPoints ) {
							if ( alignToUserSpace ) {
								alignedStartPoint = CPTAlignPointToUserSpace(context, alignedStartPoint);
								alignedHighPoint  = CPTAlignPointToUserSpace(context, alignedHighPoint);
							}
							else {
								alignedStartPoint = CPTAlignIntegralPointToUserSpace(context, alignedStartPoint);
								alignedHighPoint  = CPTAlignIntegralPointToUserSpace(context, alignedHighPoint);
							}
						}
                        
						CGPathMoveToPoint(path, NULL, alignedStartPoint.x, alignedStartPoint.y);
						CGPathAddLineToPoint(path, NULL, alignedHighPoint.x, alignedHighPoint.y);
					}
				}
				CGContextBeginPath(context);
				CGContextAddPath(context, path);
				CGContextStrokePath(context);
			}
            
			CGPathRelease(path);
		}
	}
}

-(void)drawOHLCInContext:(CGContextRef)context
					   y:(CGFloat)y
					open:(CGFloat)open
				   close:(CGFloat)close
					high:(CGFloat)high
					 low:(CGFloat)low
			 alignPoints:(BOOL)alignPoints
{
	CGFloat theStickLength = self.stickLength;
	CGMutablePathRef path  = CGPathCreateMutable();
    
	// high-low
	if ( !isnan(high) && !isnan(low) ) {
		CGPoint alignedHighPoint = CGPointMake(high,y);
		CGPoint alignedLowPoint	 = CGPointMake(low,y);
		if ( alignPoints ) {
			alignedHighPoint = CPTAlignPointToUserSpace(context, alignedHighPoint);
			alignedLowPoint	 = CPTAlignPointToUserSpace(context, alignedLowPoint);
		}
		CGPathMoveToPoint(path, NULL, alignedHighPoint.x, alignedHighPoint.y);
		CGPathAddLineToPoint(path, NULL, alignedLowPoint.x, alignedLowPoint.y);
	}
    
	// open
	if ( !isnan(open) ) {
		CGPoint alignedOpenStartPoint = CGPointMake(open,y);
		CGPoint alignedOpenEndPoint	  = CGPointMake(open,y - theStickLength ); // left side
		if ( alignPoints ) {
			alignedOpenStartPoint = CPTAlignPointToUserSpace(context, alignedOpenStartPoint);
			alignedOpenEndPoint	  = CPTAlignPointToUserSpace(context, alignedOpenEndPoint);
		}
		CGPathMoveToPoint(path, NULL, alignedOpenStartPoint.x, alignedOpenStartPoint.y);
		CGPathAddLineToPoint(path, NULL, alignedOpenEndPoint.x, alignedOpenEndPoint.y);
	}
    
	// close
	if ( !isnan(close) ) {
		CGPoint alignedCloseStartPoint = CGPointMake(close,y);
		CGPoint alignedCloseEndPoint   = CGPointMake(close,y + theStickLength); // right side
		if ( alignPoints ) {
			alignedCloseStartPoint = CPTAlignPointToUserSpace(context, alignedCloseStartPoint);
			alignedCloseEndPoint   = CPTAlignPointToUserSpace(context, alignedCloseEndPoint);
		}
		CGPathMoveToPoint(path, NULL, alignedCloseStartPoint.x, alignedCloseStartPoint.y);
		CGPathAddLineToPoint(path, NULL, alignedCloseEndPoint.x, alignedCloseEndPoint.y);
	}
    
	CGContextBeginPath(context);
	CGContextAddPath(context, path);
	CGContextStrokePath(context);
	CGPathRelease(path);
}

-(void)drawSwatchForLegend:(CPTLegend *)legend atIndex:(NSUInteger)index inRect:(CGRect)rect inContext:(CGContextRef)context
{
//	[super drawSwatchForLegend:legend atIndex:index inRect:rect inContext:context];
//	[self.lineStyle setLineStyleInContext:context];
//    
//	switch ( self.plotStyle ) {
//		case HDSTradingRangePlotStyleOHLC:
//			[self drawOHLCInContext:context
//								  x:CGRectGetMidX(rect)
//							   open:CGRectGetMinY(rect) + rect.size.height / (CGFloat)3.0
//							  close:CGRectGetMinY(rect) + rect.size.height * (CGFloat)(2.0 / 3.0)
//							   high:CGRectGetMaxY(rect)
//								low:CGRectGetMinY(rect)
//						alignPoints:YES];
//			break;
//            
//		case HDSTradingRangePlotStyleCandleStick:
//			[self drawCandleStickInContext:context
//										 x:CGRectGetMidX(rect)
//									  open:CGRectGetMinY(rect) + rect.size.height / (CGFloat)3.0
//									 close:CGRectGetMinY(rect) + rect.size.height * (CGFloat)(2.0 / 3.0)
//									  high:CGRectGetMaxY(rect)
//									   low:CGRectGetMinY(rect)
//							   alignPoints:YES];
//			break;
//            
//		default:
//			break;
//	}
}

///	@endcond

#pragma mark -
#pragma mark Animation

+(BOOL)needsDisplayForKey:(NSString *)aKey
{
	static NSArray *keys = nil;
    
	if ( !keys ) {
		keys = [[NSArray alloc] initWithObjects:
				@"barWidth",
				@"stickLength",
				@"barCornerRadius",
				nil];
	}
    
	if ( [keys containsObject:aKey] ) {
		return YES;
	}
	else {
		return [super needsDisplayForKey:aKey];
	}
}

#pragma mark -
#pragma mark Fields

/// @cond

-(NSUInteger)numberOfFields
{
	return 5;
}

-(NSArray *)fieldIdentifiers
{
	return [NSArray arrayWithObjects:
			[NSNumber numberWithUnsignedInt:HDSTradingRangePlotFieldX],
			[NSNumber numberWithUnsignedInt:HDSTradingRangePlotFieldOpen],
			[NSNumber numberWithUnsignedInt:HDSTradingRangePlotFieldClose],
			[NSNumber numberWithUnsignedInt:HDSTradingRangePlotFieldHigh],
			[NSNumber numberWithUnsignedInt:HDSTradingRangePlotFieldLow],
			nil];
}

-(NSArray *)fieldIdentifiersForCoordinate:(CPTCoordinate)coord
{
	NSArray *result = nil;
    
	switch ( coord ) {
		case CPTCoordinateX:
			result = [NSArray arrayWithObject:[NSNumber numberWithUnsignedInt:HDSTradingRangePlotFieldX]];
			break;
            
		case CPTCoordinateY:
			result = [NSArray arrayWithObjects:
					  [NSNumber numberWithUnsignedInt:HDSTradingRangePlotFieldOpen],
					  [NSNumber numberWithUnsignedInt:HDSTradingRangePlotFieldLow],
					  [NSNumber numberWithUnsignedInt:HDSTradingRangePlotFieldHigh],
					  [NSNumber numberWithUnsignedInt:HDSTradingRangePlotFieldClose],
					  nil];
			break;
            
		default:
			[NSException raise:CPTException format:@"Invalid coordinate passed to fieldIdentifiersForCoordinate:"];
			break;
	}
	return result;
}

/// @endcond

#pragma mark -
#pragma mark Data Labels

/// @cond

-(void)positionLabelAnnotation:(CPTPlotSpaceAnnotation *)label forIndex:(NSUInteger)index
{
	BOOL positiveDirection = YES;
	CPTPlotRange *yRange   = [self.plotSpace plotRangeForCoordinate:CPTCoordinateY];
    
	if ( CPTDecimalLessThan( yRange.length, CPTDecimalFromInteger(0) ) ) {
		positiveDirection = !positiveDirection;
	}
    
	NSNumber *xValue = [self cachedNumberForField:HDSTradingRangePlotFieldX recordIndex:index];
	NSNumber *yValue;
	NSArray *yValues = [NSArray arrayWithObjects:[self cachedNumberForField:HDSTradingRangePlotFieldOpen recordIndex:index],
						[self cachedNumberForField:HDSTradingRangePlotFieldClose recordIndex:index],
						[self cachedNumberForField:HDSTradingRangePlotFieldHigh recordIndex:index],
						[self cachedNumberForField:HDSTradingRangePlotFieldLow recordIndex:index], nil];
	NSArray *yValuesSorted = [yValues sortedArrayUsingSelector:@selector(compare:)];
	if ( positiveDirection ) {
		yValue = [yValuesSorted lastObject];
	}
	else {
		yValue = [yValuesSorted objectAtIndex:0];
	}
    
	label.anchorPlotPoint = [NSArray arrayWithObjects:xValue, yValue, nil];
    
	if ( positiveDirection ) {
		label.displacement = CGPointMake(0.0, self.labelOffset);
	}
	else {
		label.displacement = CGPointMake(0.0, -self.labelOffset);
	}
    
	label.contentLayer.hidden = isnan([xValue doubleValue]) || isnan([yValue doubleValue]);
}

/// @endcond

#pragma mark -
#pragma mark Accessors

///	@cond

-(void)setPlotStyle:(HDSTradingRangePlotStyle)newPlotStyle
{
	if ( plotStyle != newPlotStyle ) {
		plotStyle = newPlotStyle;
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setLineStyle:(CPTLineStyle *)newLineStyle
{
	if ( lineStyle != newLineStyle ) {
		lineStyle = [newLineStyle copy];
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setIncreaseLineStyle:(CPTLineStyle *)newLineStyle
{
	if ( increaseLineStyle != newLineStyle ) {
		increaseLineStyle = [newLineStyle copy];
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setDecreaseLineStyle:(CPTLineStyle *)newLineStyle
{
	if ( decreaseLineStyle != newLineStyle ) {
		decreaseLineStyle = [newLineStyle copy];
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setIncreaseFill:(CPTFill *)newFill
{
	if ( increaseFill != newFill ) {
		increaseFill = [newFill copy];
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setDecreaseFill:(CPTFill *)newFill
{
	if ( decreaseFill != newFill ) {
		decreaseFill = [newFill copy];
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setBarWidth:(CGFloat)newWidth
{
	if ( barWidth != newWidth ) {
		barWidth = newWidth;
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setStickLength:(CGFloat)newLength
{
	if ( stickLength != newLength ) {
		stickLength = newLength;
		[self setNeedsDisplay];
		[[NSNotificationCenter defaultCenter] postNotificationName:CPTLegendNeedsRedrawForPlotNotification object:self];
	}
}

-(void)setBarCornerRadius:(CGFloat)newBarCornerRadius
{
	if ( barCornerRadius != newBarCornerRadius ) {
		barCornerRadius = newBarCornerRadius;
		[self setNeedsDisplay];
	}
}

-(void)setXValues:(CPTMutableNumericData *)newValues
{
	[self cacheNumbers:newValues forField:HDSTradingRangePlotFieldX];
}

-(CPTMutableNumericData *)xValues
{
	return [self cachedNumbersForField:HDSTradingRangePlotFieldX];
}

-(CPTMutableNumericData *)openValues
{
	return [self cachedNumbersForField:HDSTradingRangePlotFieldOpen];
}

-(void)setOpenValues:(CPTMutableNumericData *)newValues
{
	[self cacheNumbers:newValues forField:HDSTradingRangePlotFieldOpen];
}

-(CPTMutableNumericData *)highValues
{
	return [self cachedNumbersForField:HDSTradingRangePlotFieldHigh];
}

-(void)setHighValues:(CPTMutableNumericData *)newValues
{
	[self cacheNumbers:newValues forField:HDSTradingRangePlotFieldHigh];
}

-(CPTMutableNumericData *)lowValues
{
	return [self cachedNumbersForField:HDSTradingRangePlotFieldLow];
}

-(void)setLowValues:(CPTMutableNumericData *)newValues
{
	[self cacheNumbers:newValues forField:HDSTradingRangePlotFieldLow];
}

-(CPTMutableNumericData *)closeValues
{
	return [self cachedNumbersForField:HDSTradingRangePlotFieldClose];
}

-(void)setCloseValues:(CPTMutableNumericData *)newValues
{
	[self cacheNumbers:newValues forField:HDSTradingRangePlotFieldClose];
}

///	@endcond

@end
