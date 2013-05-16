//
//  HDSLoginViewController.h
//  BI
//
//  Created by 毅 张 on 12-5-24.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "SBJson.h"

@interface HDSLoginViewController : UIViewController <SBJsonStreamParserAdapterDelegate>
@property (unsafe_unretained, nonatomic) IBOutlet UIImageView *backgroundImageView;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *userName;
@property (unsafe_unretained, nonatomic) IBOutlet UITextField *userPassword;

@property (unsafe_unretained, nonatomic) IBOutlet UISwitch *rememberMe;
@property (unsafe_unretained, nonatomic) IBOutlet UISwitch *autoLogin;
@property (unsafe_unretained, nonatomic) IBOutlet UIButton *loginButton;
@property (assign, nonatomic) BOOL isChangeUser;
@property (retain, nonatomic) NSString *loginUserId;
@property (retain, nonatomic) NSArray *allFunctions;

- (IBAction)switchChanged:(UISwitch *)sender;
- (IBAction)loginButtonTaped:(UIButton *)sender;
@property (unsafe_unretained, nonatomic) IBOutlet UIView *popup;

@end
