//
//  HDS_S_ShipInfo.m
//  船舶资料
//
//  Created by 毅 张 on 12-6-15.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDS_S_ShipInfo.h"

@interface HDS_S_ShipInfo ()

@end

@implementation HDS_S_ShipInfo
@synthesize eShipName;
@synthesize shipCompany;
@synthesize nation;
@synthesize totalWeight;
@synthesize shipLength;
@synthesize shipHeight;
@synthesize cShipName;
@synthesize shipOwner;
@synthesize shipType;
@synthesize grossWeight;
@synthesize shipWidth;
@synthesize shipSpeed;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {

    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
}

- (void)viewDidUnload
{
    [self setEShipName:nil];
    [self setShipCompany:nil];
    [self setNation:nil];
    [self setTotalWeight:nil];
    [self setShipLength:nil];
    [self setShipHeight:nil];
    [self setCShipName:nil];
    [self setShipOwner:nil];
    [self setShipType:nil];
    [self setGrossWeight:nil];
    [self setShipWidth:nil];
    [self setShipSpeed:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

@end
