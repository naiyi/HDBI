//
//  HDS_S_ShipInfo.h
//  BI
//
//  Created by 毅 张 on 12-6-15.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface HDS_S_ShipInfo : UIViewController
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *eShipName;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *shipCompany;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *nation;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *totalWeight;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *shipLength;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *shipHeight;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *cShipName;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *shipOwner;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *shipType;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *grossWeight;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *shipWidth;
@property (unsafe_unretained, nonatomic) IBOutlet UILabel *shipSpeed;

@end
