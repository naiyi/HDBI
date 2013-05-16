//
//  HDSDetailViewController.m
//  BI
//
//  Created by 毅 张 on 12-5-23.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSDetailViewController.h"
#import "HDSAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "HDSUtil.h"

@interface HDSDetailViewController ()
@end

@implementation HDSDetailViewController

@synthesize detailItem = _detailItem;

#pragma mark - Managing the detail item
-(void)updateTheme:(NSNotification*)notification{
    if([HDSUtil skinType] == HDSSkinBlue){
        self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    }else{
        self.view.backgroundColor = [UIColor colorWithPatternImage:[HDSUtil loadImageSkin:HDSSkinBlack imageName:@"index_bg_2048_right.png"]];
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self){
        
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    [self updateTheme:nil];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}


@end
