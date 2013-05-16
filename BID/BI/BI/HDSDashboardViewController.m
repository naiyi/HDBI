//
//  HDSDashboardViewController.m
//  BI
//
//  Created by 毅 张 on 12-5-28.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import "GMGridView.h"
#import "OptionsViewController.h"
#import "GMGridViewLayoutStrategies.h"
#import "HDSDashboardViewController.h"
#import "HDSUtil.h"
#import "HDSAppDelegate.h"
#import "HDSFunctionCache.h"
#import "HDS_S_ShipIOPortPlan.h"
#import "HDS_S_DeviceWorkQuantity.h"
#import "HDSLoginViewController.h"

#define NUMBER_ITEMS_ON_LOAD 3

//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark ViewController (privates methods)
//////////////////////////////////////////////////////////////

@interface HDSDashboardViewController() <GMGridViewDataSource, GMGridViewSortingDelegate, GMGridViewTransformationDelegate, GMGridViewActionDelegate,UINavigationControllerDelegate, UIImagePickerControllerDelegate>{
    __gm_weak GMGridView *_gmGridView;
    UIPopoverController *_optionsPopOver;

    NSInteger _lastDeleteItemIndexAsked;
    UISplitViewController *splitViewController;
}

- (void)refreshItem;
- (void)presentInfo;
- (void)presentOptions:(UIBarButtonItem *)barButton;

@end


//////////////////////////////////////////////////////////////
#pragma mark -
#pragma mark ViewController implementation
//////////////////////////////////////////////////////////////

@implementation HDSDashboardViewController{
    UIButton *switchButton;
    UIButton *optionButton;
    UIButton *infoButton;
    
    UIButton *btn1;
    UIButton *btn2;
    UIImagePickerController *imagepicker;
    UIImageView *imageview;
    UIPopoverController *pop;
}

@synthesize gridViewControllers;
@synthesize currentData = _currentData;
@synthesize layoutChanged;

- (BOOL)saveHomePageModuleLayout{
    if([HDSUtil isOffline])
        return false;
    if(!layoutChanged)
        return false;
    
    [self performSelectorInBackground:@selector(saveHomePageProcess:) withObject:nil];
    return true;
}

- (void)saveHomePageProcess:(id)userInfo{
    HDSAppDelegate *appDelegate = (HDSAppDelegate *)[[UIApplication sharedApplication] delegate];
    HDSLoginViewController *loginVC = [appDelegate sharedLoginVC];
    
    NSMutableArray *homeFuncs = [[NSMutableArray alloc] init];
    for(NSString *_funcVal in _currentData){
        for(NSDictionary *funcDict in loginVC.allFunctions ){
            NSString *funcId = [funcDict objectForKey:@"funcId"];
            NSString *funcVal = [funcDict objectForKey:@"val"];
            if([_funcVal isEqualToString:funcVal]){
                [homeFuncs addObject:funcId];
                break;
            }
        }
    }
    NSString *homeFuncsString = [homeFuncs componentsJoinedByString:@","];
    
    NSString *url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/sys/saveHomeFuncs.json?userId=%@&homeFuncs=%@",[loginVC loginUserId],homeFuncsString];
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
    // 使用同步请求
    NSError *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:nil error:&error];
    if(data == nil){
        NSLog(@"saveHomePage error is: %@",error);
    }else{
        NSLog(@"saveHomePage success");
    }
}

- (void)reloadView{
    
    if([HDSUtil isOffline]){
        _currentData = [[NSMutableArray alloc] init];
        [_currentData addObject:@"HDS_S_ThruputPlanComplete"]; //吞吐量计划完成情况
        [_currentData addObject:@"HDS_S_ShipIOPortPlan"];   //船舶进出港计划
//        [_currentData addObject:@"HDS_S_ShipDayNightPlan"]; //船舶昼夜作业计划
//        [_currentData addObject:@"HDS_S_YardDayNightPlan"]; //库场昼夜作业计划
//        [_currentData addObject:@"HDS_S_IOPortPlanComplete"];  //集疏港计划完成情况
//        
        [_currentData addObject:@"HDS_S_ShipInPortDynamic"];  //船舶在港动态查询
//        [_currentData addObject:@"HDS_S_ShipLoadSchedule"];  //船舶装卸作业进度查询
//        [_currentData addObject:@"HDS_S_ClassWorkSchedule"];  //班次作业进度查询
        [_currentData addObject:@"HDS_S_PortCargoStore"];  //港存货物查询
        [_currentData addObject:@"HDS_S_PortTruckQuery"];  //在港车辆查询
        [_currentData addObject:@"HDS_S_DayIoPortFlow"];  //每日集疏运流量统计
//        [_currentData addObject:@"HDS_S_ShipChargeQuery"];  //船舶计费情况查询
//        [_currentData addObject:@"HDS_S_DeviceWorkQuantity"]; //设备作业量统计
//        
        [_currentData addObject:@"HDS_S_ThruputAnalysis"];  //散杂货吞吐量分析
//        [_currentData addObject:@"HDS_S_ShipLoadEfficiency"];  //单船装卸效率分析
//        [_currentData addObject:@"HDS_S_ShipStopTime"];  //船舶在港停时分析
//        [_currentData addObject:@"HDS_S_ShipLoadIncomeCost"];  //单船装卸收入成本分析
//        [_currentData addObject:@"HDS_S_CargoLoadEfficiency"];  //单货种装卸效率分析
//        [_currentData addObject:@"HDS_S_CargoStopTime"];    //单货种千吨货停时
//        [_currentData addObject:@"HDS_S_CargoIncomeCost"];    //单货种收入成本分析
//        [_currentData addObject:@"HDS_S_ClientIncome"];    //货主贡献度分析
//        [_currentData addObject:@"HDS_S_BerthUseRate"];    //泊位利用率分析
//        [_currentData addObject:@"HDS_S_YardUseRate"];    //库场利用率分析
//        [_currentData addObject:@"HDS_S_DeviceUseRate"];    //设备利用率分析
//        [_currentData addObject:@"HDS_S_MachineWorkRate"];    //机械作业效率分析
//        [_currentData addObject:@"HDS_S_YardWorkKpi"];    //库场作业指标分析
//
//        [_currentData addObject:@"HDS_C_ShipIOPortPlan"];   //船舶进出港计划
//        [_currentData addObject:@"HDS_C_PortShipWork"];   //在港船舶作业监控
//        [_currentData addObject:@"HDS_C_ThruputPlanComplete"];   //吞吐量计划完成情况
//        [_currentData addObject:@"HDS_C_BerthPlan"];  //泊位计划监控
//        [_currentData addObject:@"HDS_C_DeviceStatus"];  //设备状态监控
//
//        
        [_currentData addObject:@"HDS_C_PortContainer"];  //在场箱查询
//        [_currentData addObject:@"HDS_C_YardIoContainer"];  //堆场进出箱统计
        [_currentData addObject:@"HDS_C_ContainerThruput"];  //集装箱吞吐量统计
//        [_currentData addObject:@"HDS_C_ShipCorpThruput"];  //船公司吞吐量统计
//        [_currentData addObject:@"HDS_C_LineThruput"];  //航线吞吐量统计
//        [_currentData addObject:@"HDS_C_GateFlow"];  //闸口流量统计
//        [_currentData addObject:@"HDS_C_ContainerCycle"];  //集装箱周转时间统计
//        [_currentData addObject:@"HDS_C_DeviceWork"];  //设备作业量统计
//        [_currentData addObject:@"HDS_C_ContainerStuff"];  //拆装箱作业统计
//        [_currentData addObject:@"HDS_C_ShipCost"];  //单船费用统计
//
//        [_currentData addObject:@"HDS_C_ShipWorkRate"];  //单船作业效率
//        [_currentData addObject:@"HDS_C_ShipStopTime"];  //船舶停时分析
//        [_currentData addObject:@"HDS_C_ShipOnTimeRate"];  //航线班轮准班率        
//        [_currentData addObject:@"HDS_C_BerthThroughput"];  //泊位通过量分析
//        [_currentData addObject:@"HDS_C_BerthUseRate"];  //泊位利用率
//        [_currentData addObject:@"HDS_C_BerthWorkRate"];  //泊位作业效率
//        [_currentData addObject:@"HDS_C_YardUseRate"];  //堆场利用率分析
//        [_currentData addObject:@"HDS_C_YardUpsetRate"];    //堆场倒箱率分析
//        [_currentData addObject:@"HDS_C_YardStockDensity"];  //堆场堆存密度
//        [_currentData addObject:@"HDS_C_TruckServiceTime"];  //外线拖车服务时间
//        [_currentData addObject:@"HDS_C_DeviceWorkRate"];  //主要设备作业效率
//        [_currentData addObject:@"HDS_C_DeviceGoodRate"];  //设备完好率
//        [_currentData addObject:@"HDS_C_DeviceErrorRate"];  //设备故障率
//        [_currentData addObject:@"HDS_C_DevcieUseRate"];  //设备利用率
//        [_currentData addObject:@"HDS_C_ShipLoadCost"];  //单船装卸成本收入分析
//        [_currentData addObject:@"HDS_C_ContainerCost"];  //单箱成本收入分析
    }else{
        _currentData = [HDSFunctionCache sharedFunctionCache].mainPageFunctions;
    }
    [_gmGridView reloadData];
    _gmGridView.contentOffset = CGPointMake(0, 0);
    layoutChanged = false;
}

-(void)updateTheme:(NSNotification*)notification{
    if([HDSUtil skinType] == HDSSkinBlue){
        self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
        [switchButton setImage:[HDSUtil loadImageSkin:HDSSkinBlue imageName:@"switch_normal_264.png"] forState:UIControlStateNormal];
        [switchButton setImage:[HDSUtil loadImageSkin:HDSSkinBlue imageName:@"switch_highlight_264.png"] forState:UIControlStateHighlighted];
        [optionButton setImage:[HDSUtil loadImageSkin:HDSSkinBlue imageName:@"setting_normal_264.png"] forState:UIControlStateNormal];
        [optionButton setImage:[HDSUtil loadImageSkin:HDSSkinBlue imageName:@"setting_highlight_264.png"] forState:UIControlStateHighlighted];
        _gmGridView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
        infoButton = [UIButton buttonWithType:UIButtonTypeInfoDark];
    }else{
        self.view.backgroundColor = [UIColor colorWithPatternImage:[HDSUtil loadImageSkin:HDSSkinBlack imageName:@"index_bg_2048_right.png"]];
        [switchButton setImage:[HDSUtil loadImageSkin:HDSSkinBlack imageName:@"switch_normal_264.png"] forState:UIControlStateNormal];
        [switchButton setImage:[HDSUtil loadImageSkin:HDSSkinBlack imageName:@"switch_highlight_264.png"] forState:UIControlStateHighlighted];
        [optionButton setImage:[HDSUtil loadImageSkin:HDSSkinBlack imageName:@"setting_normal_264.png"] forState:UIControlStateNormal];
        [optionButton setImage:[HDSUtil loadImageSkin:HDSSkinBlack imageName:@"setting_highlight_264.png"] forState:UIControlStateHighlighted];
        _gmGridView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        infoButton = [UIButton buttonWithType:UIButtonTypeInfoLight];
    }
    infoButton.frame = CGRectMake(self.view.bounds.size.width - 40, 20, 19,19);
    infoButton.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleBottomMargin;
    [infoButton addTarget:self action:@selector(presentInfo) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:infoButton];
}

-(void) switchView{
    CATransition *animation = [CATransition animation];
    animation.delegate = self; 
    animation.duration = 1;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = @"pageCurl"; 
    switch([[UIApplication sharedApplication] statusBarOrientation]){
        case UIInterfaceOrientationPortrait:
            animation.subtype = kCATransitionFromRight;   break;
        case UIInterfaceOrientationPortraitUpsideDown:
            animation.subtype = kCATransitionFromLeft;   break;
        case UIInterfaceOrientationLandscapeLeft: 
            animation.subtype = kCATransitionFromRight;   break;
        case UIInterfaceOrientationLandscapeRight: 
            animation.subtype = kCATransitionFromLeft;   break;
    }
    
    HDSAppDelegate *delegate=(HDSAppDelegate *)[[UIApplication sharedApplication] delegate];
    [self.view removeFromSuperview];
    [delegate.window addSubview:[delegate sharedSplitVC].view];
    [[delegate.window layer] addAnimation:animation forKey:@"animation"];
    
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
}


- (id)init{
    if ((self =[super init])){
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(updateTheme:) name:@"themeNotification" object:nil];
        
//        UIBarButtonItem *addButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(addMoreItem)];
        
        UIBarButtonItem *space = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        space.width = 10;
        
//        UIBarButtonItem *removeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemTrash target:self action:@selector(removeItem)];
        
        UIBarButtonItem *space2 = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:nil action:nil];
        space2.width = 10;
    
//        UIBarButtonItem *refreshButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemRefresh target:self action:@selector(refreshItem)];
        
//        if ([self.navigationItem respondsToSelector:@selector(leftBarButtonItems)]) {
//            self.navigationItem.leftBarButtonItems = [NSArray arrayWithObjects:testButton,addButton, space, removeButton, space2, refreshButton, nil];
//        }else {
//            self.navigationItem.leftBarButtonItem = addButton;
//        }
        
//        UIBarButtonItem *optionsButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCompose target:self action:@selector(presentOptions:)];
        
//        if ([self.navigationItem respondsToSelector:@selector(rightBarButtonItems)]) {
//            self.navigationItem.rightBarButtonItems = [NSArray arrayWithObjects:optionsButton, nil];
//        }else {
//            self.navigationItem.rightBarButtonItem = optionsButton;
//        }

        
        layoutChanged = false;
        gridViewControllers = [[NSMutableArray alloc] init];
    }
    
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark controller events
//////////////////////////////////////////////////////////////

- (void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)loadView 
{
    [super loadView];
    
    NSInteger spacing = 15;
    
    GMGridView *gmGridView = [[GMGridView alloc] initWithFrame:self.view.bounds];
    gmGridView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:gmGridView];
    _gmGridView = gmGridView;
    
    switchButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [switchButton setImage:[UIImage imageNamed:@"switch_normal_264.png"] forState:UIControlStateNormal];
    [switchButton setImage:[UIImage imageNamed:@"switch_highlight_264.png"] forState:UIControlStateHighlighted];
    switchButton.contentMode = UIViewContentModeScaleToFill;
    [switchButton addTarget:self action:@selector(switchView) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:switchButton]; 
    
    optionButton = [UIButton buttonWithType:UIButtonTypeCustom];
    [optionButton setImage:[UIImage imageNamed:@"setting_normal_264.png"] forState:UIControlStateNormal];
    [optionButton setImage:[UIImage imageNamed:@"setting_highlight_264.png"] forState:UIControlStateHighlighted];
    [optionButton addTarget:self action:@selector(presentOptions:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:optionButton];
    
    switchButton.frame = CGRectIntegral(CGRectMake(55, 15, 48, 31));
    optionButton.frame = CGRectIntegral(CGRectMake(115, 15, 48, 31));
    
    _gmGridView.layoutStrategy = [GMGridViewLayoutStrategyFactory strategyFromType:GMGridViewLayoutHorizontalPagedLTR];
    _gmGridView.style = GMGridViewStyleSwap;
    _gmGridView.itemSpacing = spacing;
    _gmGridView.minEdgeInsets = UIEdgeInsetsMake(55, spacing, spacing, spacing);
    _gmGridView.centerGrid = YES;
    _gmGridView.actionDelegate = self;
    _gmGridView.sortingDelegate = self;
    _gmGridView.transformDelegate = self;
    _gmGridView.dataSource = self;
    _gmGridView.backgroundColor = [UIColor clearColor];
//    _gmGridView.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
    // 背景图片平铺效果
//    _gmGridView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"select_highlight.png"]];
    
    // 测试读取图片
//    btn1 = [UIButton buttonWithType: UIButtonTypeRoundedRect];
//    btn1.frame = CGRectMake(150.0, 20.0, 200.0, 32.0);
//    [btn1 setTitle:@"从媒体库中选取图片" forState:UIControlStateNormal];
//    [btn1 addTarget:self action:@selector(picker) forControlEvents:UIControlEventTouchUpInside];
//    btn2 = [UIButton buttonWithType: UIButtonTypeRoundedRect];
//    btn2.frame = CGRectMake(360.0, 20.0, 200.0, 32.0);
//    [btn2 setTitle:@"从相机获取图片" forState:UIControlStateNormal];
//    [btn2 addTarget:self action:@selector(picker1) forControlEvents:UIControlEventTouchUpInside];
//    [self.view addSubview:btn1];
//    [self.view addSubview:btn2];
//    imageview = [[UIImageView alloc] initWithFrame:CGRectMake(600.0, 20.0, 100.0, 100.0)];
//    [self.view addSubview:imageview];
}

/*  测试图片读取相关方法 1:从媒体库中选取  2:从相机获取
-(void)picker{
    imagepicker = [[UIImagePickerController alloc] init];
    imagepicker.delegate = self;
    imagepicker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
    imagepicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    imagepicker.allowsEditing = YES;
    pop = [[UIPopoverController alloc] initWithContentViewController:imagepicker];
    [pop presentPopoverFromRect:btn1.frame inView:[btn1 superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}
// 从相机获取
-(void)picker1{
    imagepicker = [[UIImagePickerController alloc] init];
    imagepicker.delegate = self;
    imagepicker.sourceType = UIImagePickerControllerSourceTypeCamera;
    imagepicker.modalTransitionStyle = UIModalTransitionStyleCoverVertical;
    imagepicker.allowsEditing = YES;
    pop = [[UIPopoverController alloc] initWithContentViewController:imagepicker];
    [pop presentPopoverFromRect:btn1.frame inView:[btn1 superview] permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}
// 初始化选取
- (void)imagePickerController:(UIImagePickerController *)picker
        didFinishPickingImage:(UIImage *)image editingInfo:(NSDictionary *)editingInfo{
    imageview.image = image;
    [[picker parentViewController] dismissModalViewControllerAnimated:YES];
}
// 完成选取
- (void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    [picker dismissModalViewControllerAnimated:YES];
}
*/

- (void)viewDidLoad{
    [super viewDidLoad];
//    _gmGridView.mainSuperView = self.navigationController.view; //[UIApplication sharedApplication].keyWindow.rootViewController.view;
    [self updateTheme:nil];
}


- (void)viewDidUnload{
    [super viewDidUnload];
    _gmGridView = nil;
}

- (void)viewDidAppear:(BOOL)animated{
    [super viewDidAppear:animated];
}


//////////////////////////////////////////////////////////////
#pragma mark memory management
//////////////////////////////////////////////////////////////

//- (void)didReceiveMemoryWarning {
//    [super didReceiveMemoryWarning];
//}

//////////////////////////////////////////////////////////////
#pragma mark orientation management
//////////////////////////////////////////////////////////////

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    if(UIInterfaceOrientationIsLandscape(toInterfaceOrientation)){
        switchButton.frame = CGRectIntegral(CGRectMake(20, 15, 48, 31));
        optionButton.frame = CGRectIntegral(CGRectMake(80, 15, 48, 31));
    }else{
        switchButton.frame = CGRectIntegral(CGRectMake(55, 15, 48, 31));
        optionButton.frame = CGRectIntegral(CGRectMake(115, 15, 48, 31));
    }
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewDataSource
//////////////////////////////////////////////////////////////

- (NSInteger)numberOfItemsInGMGridView:(GMGridView *)gridView
{
    return [_currentData count];
}

- (CGSize)GMGridView:(GMGridView *)gridView sizeForItemsInInterfaceOrientation:(UIInterfaceOrientation)orientation
{
    if (UIInterfaceOrientationIsLandscape(orientation)) 
    {
        _gmGridView.itemSpacing = 15;
        return CGSizeMake(320, 215);
    }
    else
    {
        _gmGridView.itemSpacing = 20;
        return CGSizeMake(320, 215);
    }
}

- (GMGridViewCell *)GMGridView:(GMGridView *)gridView cellForItemAtIndex:(NSInteger)index{
    
    CGSize size = [self GMGridView:gridView sizeForItemsInInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    
    GMGridViewCell *cell = [gridView dequeueReusableCell];
    
    if (!cell) 
    {
        cell = [[GMGridViewCell alloc] init];
        cell.deleteButtonIcon = [UIImage imageNamed:@"close_x.png"];
        cell.deleteButtonOffset = CGPointMake(-15, -15);
        
//        UIView *view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];
//        view.backgroundColor = [UIColor redColor];
//        view.layer.masksToBounds = YES;
//        view.layer.cornerRadius = 8;
//        cell.contentView = view;
        
    }
    
    // cell.contenvView与_vc.view指向同一个对象，不能清空
//    [[cell.contentView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
    
    NSString *functionName = [_currentData objectAtIndex:index];
    NSString *smallNibName = [functionName stringByAppendingString:@"-small"];
    
    UIViewController *_vc = [[HDSFunctionCache sharedFunctionCache] getSmallViewControllerByKey:functionName];
    if(_vc == nil){
        // 动态获取类名
        _vc = [[NSClassFromString(functionName) alloc] initWithNibName:smallNibName bundle:nil];
        _vc.view.frame = CGRectMake(0, 0, size.width, size.height);
        _vc.view.layer.cornerRadius = 8;
        _vc.view.layer.masksToBounds= false; // 必须设置为false，否则view转换动画被边界截断
        _vc.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [[HDSFunctionCache sharedFunctionCache] addSmallViewController:_vc toKey:functionName];
    }
    
    cell.contentView = _vc.view;
    // 只对view产生了引用，没有对_vc引用，则_vc会被自动释放，需要使用集合对其引用，若缓存则不需要此步
//    [gridViewControllers addObject:_vc];
    
    return cell;
}


- (BOOL)GMGridView:(GMGridView *)gridView canDeleteItemAtIndex:(NSInteger)index
{
    return YES; //index % 2 == 0;
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewActionDelegate
//////////////////////////////////////////////////////////////

- (void)GMGridView:(GMGridView *)gridView didTapOnItemAtIndex:(NSInteger)position
{
//    NSLog(@"Did tap at index %d", position);
}

- (void)GMGridViewDidTapOnEmptySpace:(GMGridView *)gridView
{
//    NSLog(@"Tap on empty space");
}

- (void)GMGridView:(GMGridView *)gridView processDeleteActionForItemAtIndex:(NSInteger)index
{
    UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"确认" message:@"确定删除该页面?" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"删除", nil];
    
    [alert show];
    
    _lastDeleteItemIndexAsked = index;
}

- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 1) 
    {
        [_currentData removeObjectAtIndex:_lastDeleteItemIndexAsked];
        [_gmGridView removeObjectAtIndex:_lastDeleteItemIndexAsked withAnimation:GMGridViewItemAnimationFade];
        layoutChanged = true;
    }
}

//////////////////////////////////////////////////////////////
#pragma mark GMGridViewSortingDelegate
//////////////////////////////////////////////////////////////

- (void)GMGridView:(GMGridView *)gridView didStartMovingCell:(GMGridViewCell *)cell
{
    [UIView animateWithDuration:0.3 
                          delay:0 
                        options:UIViewAnimationOptionAllowUserInteraction 
                     animations:^{
                         cell.contentView.backgroundColor = [UIColor orangeColor];
                         cell.contentView.layer.shadowOpacity = 0.7;
                     } 
                     completion:nil
     ];
}

- (void)GMGridView:(GMGridView *)gridView didEndMovingCell:(GMGridViewCell *)cell
{
    [UIView animateWithDuration:0.3 
                          delay:0 
                        options:UIViewAnimationOptionAllowUserInteraction 
                     animations:^{  
                         if([HDSUtil skinType] == HDSSkinBlue){
                             cell.contentView.backgroundColor = [UIColor whiteColor];
                         }else{
                             cell.contentView.backgroundColor = [UIColor clearColor];
                         }
                         cell.contentView.layer.shadowOpacity = 0;
                     }
                     completion:nil
     ];
}

- (BOOL)GMGridView:(GMGridView *)gridView shouldAllowShakingBehaviorWhenMovingCell:(GMGridViewCell *)cell atIndex:(NSInteger)index{
    return YES;
}

- (void)GMGridView:(GMGridView *)gridView moveItemAtIndex:(NSInteger)oldIndex toIndex:(NSInteger)newIndex{
    NSObject *object = [_currentData objectAtIndex:oldIndex];
    [_currentData removeObject:object];
    [_currentData insertObject:object atIndex:newIndex];
    layoutChanged = true;
}

- (void)GMGridView:(GMGridView *)gridView exchangeItemAtIndex:(NSInteger)index1 withItemAtIndex:(NSInteger)index2{
    [_currentData exchangeObjectAtIndex:index1 withObjectAtIndex:index2];
    layoutChanged = true;
}


//////////////////////////////////////////////////////////////
#pragma mark DraggableGridViewTransformingDelegate
//////////////////////////////////////////////////////////////

- (CGSize)GMGridView:(GMGridView *)gridView sizeInFullSizeForCell:(GMGridViewCell *)cell atIndex:(NSInteger)index inInterfaceOrientation:(UIInterfaceOrientation)orientation{
    if (UIInterfaceOrientationIsLandscape(orientation)) {
        return CGSizeMake(703, 748);    //  640 430
    }else{
        return CGSizeMake(703, 748);
    }
}

- (UIView *)GMGridView:(GMGridView *)gridView fullSizeViewForCell:(GMGridViewCell *)cell atIndex:(NSInteger)index{
    UIView *fullView = [[UIView alloc] init];
//    fullView.backgroundColor = [UIColor lightGrayColor];
//    fullView.layer.masksToBounds = NO;
//    fullView.layer.cornerRadius = 8;
    
    CGSize size = [self GMGridView:gridView sizeInFullSizeForCell:cell atIndex:index inInterfaceOrientation:[[UIApplication sharedApplication] statusBarOrientation]];
    fullView.bounds = CGRectMake(0, 0, size.width, size.height);
    
//    UILabel *label = [[UILabel alloc] initWithFrame:fullView.bounds];
//    label.text = [NSString stringWithFormat:@"Fullscreen View for cell at index %d", index];
//    label.textAlignment = UITextAlignmentCenter;
//    label.backgroundColor = [UIColor clearColor];
//    label.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    NSString *functionName = [_currentData objectAtIndex:index];
    HDSViewController *vc = [[HDSFunctionCache sharedFunctionCache] getHomeViewControllerByKey:functionName];
    if(vc == nil){
        // 动态获取类名
        vc = [[NSClassFromString(functionName) alloc] initWithNibName:functionName bundle:nil];
        [[HDSFunctionCache sharedFunctionCache] addHomeViewController:vc toKey:functionName];
    }
    vc.inHomePage = true;
    vc.view.frame = CGRectInset(fullView.bounds, 0.0f, 0.0f);
    [vc.view viewWithTag:SplitPopupBtnTag].hidden = true;
    
    [fullView addSubview:vc.view];
    
    return fullView;
}

- (void)GMGridView:(GMGridView *)gridView didStartTransformingCell:(GMGridViewCell *)cell{
    [UIView animateWithDuration:0.5 
                          delay:0 
                        options:UIViewAnimationOptionAllowUserInteraction 
                     animations:^{
//                         cell.contentView.backgroundColor = [UIColor whiteColor];
                         cell.contentView.layer.shadowOpacity = 0.7;
                     } 
                     completion:nil];
}

- (void)GMGridView:(GMGridView *)gridView didEndTransformingCell:(GMGridViewCell *)cell{
    [UIView animateWithDuration:0.5 
                          delay:0 
                        options:UIViewAnimationOptionAllowUserInteraction 
                     animations:^{
//                         cell.contentView.backgroundColor = [UIColor whiteColor];
                         cell.contentView.layer.shadowOpacity = 0;
                     } 
                     completion:nil];
}

- (void)GMGridView:(GMGridView *)gridView didEnterFullSizeForCell:(UIView *)cell
{
    
}


//////////////////////////////////////////////////////////////
#pragma mark private methods
//////////////////////////////////////////////////////////////

- (void)addItem:(NSString *)functionName{
    [_currentData addObject:functionName];
    [_gmGridView insertObjectAtIndex:[_currentData count] - 1 withAnimation:GMGridViewItemAnimationFade | GMGridViewItemAnimationScroll];
    layoutChanged = true;
}

- (void)removeItem:(NSString *)functionName{
    if ([_currentData count] > 0) {
        NSInteger index = [_currentData indexOfObject:functionName];
        
        [_gmGridView removeObjectAtIndex:index withAnimation:GMGridViewItemAnimationFade | GMGridViewItemAnimationScroll];
        [_currentData removeObjectAtIndex:index];
        layoutChanged = true;
    }
}

- (void)refreshItem
{
    // Example: reloading last item
    if ([_currentData count] > 0) 
    {
        int index = [_currentData count] - 1;
        
        NSString *newMessage = [NSString stringWithFormat:@"%d", (arc4random() % 1000)];
        
        [_currentData replaceObjectAtIndex:index withObject:newMessage];
        [_gmGridView reloadObjectAtIndex:index withAnimation:GMGridViewItemAnimationFade | GMGridViewItemAnimationScroll];
    }
}

- (void)presentInfo
{
    NSString *info = @"华东港口决策平台\nV1.0版";
    
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"系统信息" 
                                                        message:info 
                                                       delegate:nil 
                                              cancelButtonTitle:@"关闭" 
                                              otherButtonTitles:nil];
    
    [alertView show];
}

- (void)presentOptions:(UIButton *)barButton{
    
    OptionsViewController *optionsController = [OptionsViewController sharedOptionViewController];
    _optionsPopOver = [OptionsViewController sharedOptionPopoverController];
    _optionsPopOver.popoverContentSize = CGSizeMake(320, 640);
    optionsController.gridView = _gmGridView;
//    optionsController.contentSizeForViewInPopover = CGSizeMake(320, 640);
    optionsController.popoverController = _optionsPopOver;
    
    [_optionsPopOver presentPopoverFromRect:barButton.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}

@end
