//
//  GradientView.m
//  ShadowedTableView
//
//  Created by Matt Gallagher on 2009/08/21.
//  Copyright 2009 Matt Gallagher. All rights reserved.
//

#import "MGGradientView.h"
#import <QuartzCore/QuartzCore.h>
#import "HDSUtil.h"

@implementation MGGradientView

//
// layerClass
//
// returns a CAGradientLayer class as the default layer class for this view
//
+ (Class)layerClass
{
	return [CAGradientLayer class];
}

//
// setupGradientLayer
//
// Construct the gradient for either construction method
//
- (void)setupGradientLayer
{
	CAGradientLayer *gradientLayer = (CAGradientLayer *)self.layer;
    if([HDSUtil skinType] == HDSSkinBlue){
        gradientLayer.colors =
            [NSArray arrayWithObjects:
                (id)[HDSUtil colorFromString:@"0055e7"].CGColor,
                (id)[HDSUtil colorFromString:@"2495ed"].CGColor,
                (id)[HDSUtil colorFromString:@"0055e7"].CGColor,
             nil];
        gradientLayer.locations = 
            [NSArray arrayWithObjects:
                [NSNumber numberWithFloat:0],[NSNumber numberWithFloat:0.6],
                [NSNumber numberWithFloat:1],
             nil];
    }else{
        gradientLayer.colors =
            [NSArray arrayWithObjects:
                (id)[HDSUtil colorFromString:@"414149"].CGColor,
                (id)[HDSUtil colorFromString:@"303039"].CGColor,
                (id)[HDSUtil colorFromString:@"2b2b35"].CGColor,
                (id)[HDSUtil colorFromString:@"2d2d37"].CGColor,
             nil];
        gradientLayer.locations = 
            [NSArray arrayWithObjects:
                [NSNumber numberWithFloat:0],[NSNumber numberWithFloat:0.5],
                [NSNumber numberWithFloat:0.5],[NSNumber numberWithFloat:1],
             nil];
    }
	
	self.backgroundColor = [UIColor clearColor];
}

//
// initWithFrame:
//
// Initialise the view.
//
- (id)initWithFrame:(CGRect)frame
{
	self = [super initWithFrame:frame];
	if (self){
        
        [self setupGradientLayer];
	}
	return self;
}

@end
