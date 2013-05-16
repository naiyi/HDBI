//
//  HDSPlotDelegate.m
//  BI
//
//  Created by 毅 张 on 12-6-18.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSPlotDelegate.h"

@implementation HDSPlotDelegate

//TODO 未实现双轴线的情况，该情况需要区分space
- (CPTPlotRange *)plotSpace:(CPTPlotSpace *)space
      willChangePlotRangeTo:(CPTPlotRange *)newRange
              forCoordinate:(CPTCoordinate)coordinate {
    
    CPTPlotRange *updatedRange = nil;
    
    switch ( coordinate ) {
        case CPTCoordinateX:
            if (newRange.locationDouble < 0.0F) {
                CPTMutablePlotRange *mutableRange = [newRange mutableCopy];
                mutableRange.location = CPTDecimalFromFloat(0.0);
                updatedRange = mutableRange;
            }
            else {
                updatedRange = newRange;
            }
            break;
        case CPTCoordinateY:
            updatedRange = ((CPTXYPlotSpace *)space).yRange;
            break;
        default:
            break;
    }
    return updatedRange;
}

@end
