//
//  HDSMasterViewController.m
//  BI
//
//  Created by 毅 张 on 12-5-23.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSMasterViewController.h"

#import "HDSDetailViewController.h"
#import "HDSFunctionCache.h"
#import "HDSUtil.h"
#import "HDSAppDelegate.h"
#import "HDSDashboardViewController.h"
#import "OptionsViewController.h"

@interface HDSMasterViewController () {
    NSMutableArray *_objects;
    NSArray *_sectionHeaders;
    NSIndexPath *lastSelected;
    NSInteger segmentIndex;
    NSArray *fc0key,*fc1key,*fc2key,*fc0val,*fc1val,*fc2val,
            *fs0key,*fs1key,*fs2key,*fs0val,*fs1val,*fs2val;
}
@property (strong, nonatomic) UIButton *popoverBtn;
@property (strong, nonatomic) UIPopoverController *masterPopoverController;

@end

@implementation HDSMasterViewController{
    HDSDashboardViewController *dash;
    BOOL hasPopoverBtn;
    
    UIPopoverController *_optionsPopOver;
}
@synthesize tableView =_tableView;
@synthesize segButton;
@synthesize switchButton;
@synthesize settingButton;

@synthesize detailViewController = _detailViewController;
@synthesize popoverBtn;
@synthesize masterPopoverController;

@synthesize showedInSetting;    // 在设置菜单中显示
@synthesize lastSelected;

-(void)updateTheme:(NSNotification*)notification{
    HDSSkinType skinType = [HDSUtil skinType];
    
    if(skinType == HDSSkinBlue){
        self.view.backgroundColor = [UIColor scrollViewTexturedBackgroundColor];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
        _tableView.separatorColor = [UIColor grayColor];
        _tableView.indicatorStyle = UIScrollViewIndicatorStyleBlack;
        _tableView.backgroundColor = [UIColor whiteColor];
        _tableView.layer.borderColor = [UIColor blackColor].CGColor;
        _tableView.layer.borderWidth = 1;
        _tableView.layer.cornerRadius = 5;
    }else{
        self.view.backgroundColor = [UIColor colorWithPatternImage:[HDSUtil loadImageSkin:HDSSkinBlack imageName:@"index_bg_2048_left.png"]];
        _tableView.separatorStyle = UITableViewCellSeparatorStyleNone;
        _tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        _tableView.backgroundColor = [UIColor clearColor];
        _tableView.layer.borderColor = [UIColor colorWithWhite:1.0f alpha:0.4f].CGColor;
        _tableView.layer.borderWidth = 1;
        _tableView.layer.cornerRadius = 5;
        
    }
    [switchButton setImage:[HDSUtil loadImageSkin:skinType imageName:@"switch_normal_264.png"] forState:UIControlStateNormal];
    [switchButton setImage:[HDSUtil loadImageSkin:skinType imageName:@"switch_highlight_264.png"] forState:UIControlStateHighlighted];
    [settingButton setImage:[HDSUtil loadImageSkin:skinType imageName:@"setting_normal_264.png"] forState:UIControlStateNormal];
    [settingButton setImage:[HDSUtil loadImageSkin:skinType imageName:@"setting_highlight_264.png"] forState:UIControlStateHighlighted];
    
    [_tableView reloadData];
    [HDSUtil changeSegment:segButton textAttributeBySkin:[HDSUtil skinType]];
    
    if(popoverBtn){
        UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
        [popoverBtn setTitleColor:color forState:UIControlStateNormal];
        [popoverBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal.png"] forState:UIControlStateNormal];
        [popoverBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight.png"] forState:UIControlStateHighlighted];
    }
}

- (id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self){
        showedInSetting = false;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self){
       showedInSetting = false; 
    }
    return self;
}

- (void)awakeFromNib{
//    self.clearsSelectionOnViewWillAppear = NO;
    [super awakeFromNib];
}

- (void)reloadMenuData{
    HDSFunctionCache *fc = [HDSFunctionCache sharedFunctionCache];
    if([HDSUtil isOffline]){
        fc0key = [NSArray arrayWithObjects:
                  @"船舶进出港计划",@"在港船舶作业监控",@"吞吐量计划完成情况",@"泊位计划监控",@"设备状态监控",nil];
        fc1key = [NSArray arrayWithObjects:
                  @"在场箱查询",@"堆场进出场箱统计",@"集装箱吞吐量统计",@"分船公司吞吐量统计",@"分航线吞吐量统计",
                  @"闸口流量统计",@"集装箱周转时间统计",@"设备作业量统计",@"拆装箱作业统计",@"单船费用统计",nil];
        fc2key = [NSArray arrayWithObjects:
                  @"单船作业效率",@"船舶停时分析",@"航线班轮准班率",@"泊位通过量分析",@"泊位利用率统计",
                  @"泊位作业效率",@"堆场利用率分析",@"堆场倒箱率分析",@"堆场堆存密度分析",@"外线拖车服务时间",
                  @"主要设备作业效率",@"设备完好率",@"设备故障率",@"设备利用率",@"单船装卸成本收入分析",
                  @"单箱成本收入分析",nil ]; 
        
        fs0key = [NSArray arrayWithObjects:
                  @"吞吐量计划完成情况",@"船舶进出港计划",@"船舶昼夜作业计划",@"库场昼夜作业计划",@"集疏港计划完成情况",nil];
        fs1key = [NSArray arrayWithObjects:
                  @"船舶在港动态查询",@"船舶装卸作业进度查询",@"班次作业进度查询",@"港存货物查询",@"在港车辆查询",
                  @"每日集疏运流量统计",@"船舶计费情况查询",@"设备作业量统计",nil];
        fs2key = [NSArray arrayWithObjects:
                  @"散杂货吞吐量分析",@"单船装卸效率分析",@"船舶在港停时分析",@"单船装卸收入成本分析",@"单货种装卸效率分析",
                  @"单货种千吨货停时分析",@"单货种收入成本分析",@"货主贡献度分析",@"泊位利用率分析",@"库场利用率分析",
                  @"设备利用率分析",@"机械作业效率分析",@"库场作业指标分析",nil ]; 
        
        fc0val = [NSArray arrayWithObjects:
                  @"HDS_C_ShipIOPortPlan",@"HDS_C_PortShipWork",@"HDS_C_ThruputPlanComplete",@"HDS_C_BerthPlan",@"HDS_C_DeviceStatus",
                  nil];
        fc1val = [NSArray arrayWithObjects:
                  @"HDS_C_PortContainer",@"HDS_C_YardIoContainer",@"HDS_C_ContainerThruput",@"HDS_C_ShipCorpThruput",@"HDS_C_LineThruput",
                  @"HDS_C_GateFlow",@"HDS_C_ContainerCycle",@"HDS_C_DeviceWork",@"HDS_C_ContainerStuff",@"HDS_C_ShipCost",
                  nil];
        fc2val = [NSArray arrayWithObjects:
                  @"HDS_C_ShipWorkRate",@"HDS_C_ShipStopTime",@"HDS_C_ShipOnTimeRate",@"HDS_C_BerthThroughput",@"HDS_C_BerthUseRate",
                  @"HDS_C_BerthWorkRate",@"HDS_C_YardUseRate",@"HDS_C_YardUpsetRate",@"HDS_C_YardStockDensity",@"HDS_C_TruckServiceTime",
                  @"HDS_C_DeviceWorkRate",@"HDS_C_DeviceGoodRate",@"HDS_C_DeviceErrorRate",@"HDS_C_DevcieUseRate",@"HDS_C_ShipLoadCost",
                  @"HDS_C_ContainerCost",nil];
        
        fs0val = [NSArray arrayWithObjects:
                  @"HDS_S_ThruputPlanComplete",@"HDS_S_ShipIOPortPlan",@"HDS_S_ShipDayNightPlan",@"HDS_S_YardDayNightPlan",@"HDS_S_IOPortPlanComplete",
                  nil];
        fs1val = [NSArray arrayWithObjects:
                  @"HDS_S_ShipInPortDynamic",@"HDS_S_ShipLoadSchedule",@"HDS_S_ClassWorkSchedule",@"HDS_S_PortCargoStore",@"HDS_S_PortTruckQuery",
                  @"HDS_S_DayIoPortFlow",@"HDS_S_ShipChargeQuery",@"HDS_S_DeviceWorkQuantity", nil];
        fs2val = [NSArray arrayWithObjects:
                  @"HDS_S_ThruputAnalysis",@"HDS_S_ShipLoadEfficiency",@"HDS_S_ShipStopTime",@"HDS_S_ShipLoadIncomeCost",@"HDS_S_CargoLoadEfficiency",
                  @"HDS_S_CargoStopTime",@"HDS_S_CargoIncomeCost",@"HDS_S_ClientIncome",@"HDS_S_BerthUseRate",@"HDS_S_YardUseRate",
                  @"HDS_S_DeviceUseRate",@"HDS_S_MachineWorkRate",@"HDS_S_YardWorkKpi",nil];
    }else{
        fc0key = fc.fc0key;     fc1key = fc.fc1key;     fc2key = fc.fc2key;
        fc0val = fc.fc0val;     fc1val = fc.fc1val;     fc2val = fc.fc2val;
        fs0key = fc.fs0key;     fs1key = fc.fs1key;     fs2key = fc.fs2key;
        fs0val = fc.fs0val;     fs1val = fc.fs1val;     fs2val = fc.fs2val;
    }
}

- (void)viewDidLoad{
    [super viewDidLoad];
    self.detailViewController = [self.splitViewController.viewControllers lastObject];
    
    if(showedInSetting){
        // 在主页功能设置菜单中需要对splitView中的菜单做部分调整
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 560.0);
        [self.view viewWithTag:101].hidden = YES;
        [self.view viewWithTag:102].hidden = YES;
        [segButton removeFromSuperview];
        self.navigationItem.titleView = segButton;
        CGRect tf = _tableView.frame;
        tf.origin = CGPointMake(20, 20);
        tf.size.height += 44; 
        _tableView.frame = tf;
        [HDSUtil changeUIControlFont:segButton toSize:HDSFontSizeBig height:28];
        // 在主页功能菜单中master view会延迟加载，所以在第一次login完成时optionViewController中的master view还未加载，在其上调用reloadMenuData不起作用，针对该情况应该在首次加载的时候执行一次reloadMenuData
        if(showedInSetting){
            [self reloadMenuData];
        }
    }else{
        [HDSUtil changeUIControlFont:segButton toSize:HDSFontSizeBig];
    }
    
    _sectionHeaders = [NSArray arrayWithObjects:@"实时监控",@"查询统计",@"指标分析", nil];


    [self segButtonChanged:segButton];
    [self updateTheme:nil];
}

- (void)viewDidUnload{
    [self setSegButton:nil];
    [self setTableView:nil];
    [self setSwitchButton:nil];
    [self setSettingButton:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return YES;
}

#pragma mark - Table View

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    switch (segmentIndex) {
        case 0: {
            int i = 0;
            if( fc0key.count >0 )   i++;
            if( fc1key.count >0 )   i++;
            if( fc2key.count >0 )   i++;
            return i; 
        }   
        case 1: {
            int i = 0;
            if( fs0key.count >0 )   i++;
            if( fs1key.count >0 )   i++;
            if( fs2key.count >0 )   i++;
            return i; 
        } 
        default:return 1;
    }
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (segmentIndex) {
        case 0: 
            return [(NSArray *)[self valueForKey:[NSString stringWithFormat:@"fc%ikey",section]] count];
        case 1: 
            return [(NSArray *)[self valueForKey:[NSString stringWithFormat:@"fs%ikey",section]] count];   
        default:
            return [(NSArray *)[self valueForKey:[NSString stringWithFormat:@"fs%ikey",section]] count];
    }
    
}

- (UITableViewCell *)tableView:(UITableView *)aTableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    NSString *cellID;
    if([HDSUtil skinType] == HDSSkinBlue){
        cellID = @"titleCellBlue";
    }else{
        cellID = @"titleCellBlack";
    }
    UITableViewCell *cell = [aTableView dequeueReusableCellWithIdentifier:cellID];
    
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellID];
        if([HDSUtil skinType] == HDSSkinBlue){
            cell.selectedBackgroundView = [HDSUtil getTableViewMultiHeaderBackgroundView];
        }else{
            cell.backgroundView = [[UIImageView alloc] initWithImage:[HDSUtil loadImageSkin:HDSSkinBlack imageName:@"leftmenu_bg.png"]];
            cell.selectedBackgroundView = [[UIImageView alloc] initWithImage:[HDSUtil loadImageSkin:HDSSkinBlack imageName:@"leftmenu_bg1.png"]];
        }
        UIImageView *image = [[UIImageView alloc] initWithFrame:CGRectMake(20, 7, 30, 30)];
        // 设置阴影效果
//        [image.layer setShadowOffset:CGSizeMake(0.0f, 0.0f)];
//        [image.layer setShadowColor:[UIColor whiteColor].CGColor];
//        [image.layer setShadowOpacity:1.0f];
//        [image.layer setShadowRadius:5.0f];
//        [image.layer setCornerRadius:20.0f];
        image.clipsToBounds = NO;
        image.tag = 1;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(69, 11, 211, 21)];
        label.tag = 2;
        label.font = [HDSUtil getFontBySize:HDSFontSizeBig];
        label.backgroundColor = [UIColor clearColor];
        label.textColor = [HDSUtil skinType] == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8];
        [label setHighlightedTextColor:[UIColor whiteColor]];
        [cell.contentView addSubview:image];
        [cell.contentView addSubview:label];
    }

    NSArray *fkey,*fval;
    switch (segmentIndex) {
        case 0: 
            fkey=(NSArray *)[self valueForKey:[NSString stringWithFormat:@"fc%ikey",indexPath.section]];
            fval=(NSArray *)[self valueForKey:[NSString stringWithFormat:@"fc%ival",indexPath.section]];
            break;
        case 1: 
            fkey=(NSArray *)[self valueForKey:[NSString stringWithFormat:@"fs%ikey",indexPath.section]];
            fval=(NSArray *)[self valueForKey:[NSString stringWithFormat:@"fs%ival",indexPath.section]];
            break;
        default:
            break;
    }
    
    UIImageView *imageView = (UIImageView *)[cell viewWithTag:1];
    NSString *sectionName;
    switch (indexPath.section) {
        case 0: sectionName = @"plan";  break;
        case 1: sectionName = @"statistics";  break;
        case 2: sectionName = @"analysis";  break;
        default:break;
    }
    
    UIImage *image = [UIImage imageNamed:[NSString stringWithFormat:@"%@_%@%i.png",segButton.selectedSegmentIndex == 0?@"c":@"s",sectionName,indexPath.row+1]];
    imageView.image = image;
        
    UILabel *label = (UILabel *) [cell viewWithTag:2];
    label.text = [fkey objectAtIndex:indexPath.row];
    
    if(showedInSetting){
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        HDSAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        HDSDashboardViewController *dashVC = [delegate sharedDashVC];
        NSString *functionName = [fval objectAtIndex:indexPath.row];
        if([dashVC.currentData containsObject:functionName]){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }else{
            cell.accessoryType = UITableViewCellAccessoryNone;
        }
    }else{
        cell.selectionStyle = UITableViewCellSelectionStyleBlue;
    }
    
    return cell;
}

- (UIView *)tableView:(UITableView *)aTableView viewForHeaderInSection:(NSInteger)section {
    if([HDSUtil skinType] == HDSSkinBlue){
        return nil;
    }
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(15, 0, 100, 22);
    label.backgroundColor = [UIColor clearColor];
//    label.shadowOffset = CGSizeMake(1.5, 1.5);
    label.textColor = [UIColor colorWithWhite:1.0f alpha:0.8];
//    label.shadowColor = [UIColor lightGrayColor];
    label.font = [HDSUtil getFontBySize:HDSFontSizeBig];
    label.text = [self tableView:aTableView titleForHeaderInSection:section];
    
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, aTableView.bounds.size.width, 22)];
    if([HDSUtil skinType] == HDSSkinBlack){
        UIImageView *backgroundImage = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, aTableView.bounds.size.width, 22)]; 
        backgroundImage.image = [HDSUtil loadImageSkin:HDSSkinBlack imageName:@"leftmenu_title_bg.png"];
        [sectionView addSubview:backgroundImage];
    }
    [sectionView addSubview:label];
    return sectionView;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{

    return [_sectionHeaders objectAtIndex:section];
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 44.0;
}


- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return NO;
}

- (void)tableView:(UITableView *)aTableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [_objects removeObjectAtIndex:indexPath.row];
        [aTableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view.
    }
}

//- (UIImage *)scaleImage:(UIImage *)image toScale:(float)scaleSize
//{
//    UIGraphicsBeginImageContext(CGSizeMake(image.size.width*scaleSize,image.size.height*scaleSize));
//    [image drawInRect:CGRectMake(0, 0, image.size.width * scaleSize, image.size.height *scaleSize)];
//    UIImage *scaledImage = UIGraphicsGetImageFromCurrentImageContext();
//    UIGraphicsEndImageContext();
//    return scaledImage;
//}

-(NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(showedInSetting) {
        return indexPath;
    }
    if(lastSelected !=nil && lastSelected.row == indexPath.row && 
       lastSelected.section == indexPath.section){
        return nil;
    }
    lastSelected = indexPath;
    return indexPath;
}

- (void)tableView:(UITableView *)aTableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSArray *f; 
    switch (segmentIndex) {
        case 0: 
            f=(NSArray *)[self valueForKey:[NSString stringWithFormat:@"fc%ival",indexPath.section]];
            break;
        case 1: 
            f=(NSArray *)[self valueForKey:[NSString stringWithFormat:@"fs%ival",indexPath.section]];
            break;
        default:
            break;
    }
    NSString *functionName = [f objectAtIndex:indexPath.row];
    
    // 功能名称为空时返回
    if ([functionName isEqualToString:@""]) {
        return;
    }
    
    if(showedInSetting){
        HDSAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
        HDSDashboardViewController *dashVC = [delegate sharedDashVC];
        
        UITableViewCell *cell = [aTableView cellForRowAtIndexPath:indexPath];
        if(cell.accessoryType == UITableViewCellAccessoryNone){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [dashVC addItem:functionName];
        }else{
            cell.accessoryType = UITableViewCellAccessoryNone;
            [dashVC removeItem:functionName];
        }
    }else{
        HDSViewController *vc = [[HDSFunctionCache sharedFunctionCache] getViewControllerByKey:functionName];
        if(vc == nil){
            // 动态获取类名
            vc = [[NSClassFromString(functionName) alloc] initWithNibName:functionName bundle:nil];
            [[HDSFunctionCache sharedFunctionCache] addViewController:vc toKey:functionName];
        }
        vc.inHomePage = false;
        [vc.view viewWithTag:SplitPopupBtnTag].hidden = false;
        
        NSMutableArray *viewControllers = (NSMutableArray *)[self.splitViewController.viewControllers mutableCopy];
        [viewControllers removeLastObject];
        [viewControllers addObject:vc];
        self.splitViewController.viewControllers = viewControllers;
        
        self.detailViewController = vc;
        
        if (self.masterPopoverController != nil) {
            [self.masterPopoverController dismissPopoverAnimated:NO];
        } 
        
        if(hasPopoverBtn){
            [self.detailViewController.view addSubview:popoverBtn];
        }
    }
    
}

- (IBAction)segButtonChanged:(UISegmentedControl *)sender {
    segmentIndex = sender.selectedSegmentIndex;
    lastSelected = nil;
    [_tableView reloadData];
}

#pragma mark - Split view

- (void)splitViewController:(UISplitViewController *)splitController willHideViewController:(UIViewController *)viewController withBarButtonItem:(UIBarButtonItem *)barButtonItem forPopoverController:(UIPopoverController *)popoverController{
    hasPopoverBtn = true;
    if(popoverBtn == nil){
        popoverBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [popoverBtn setFrame:CGRectMake(648, 20, 100, 31)];
        [popoverBtn setTitle:@"   功能列表" forState:UIControlStateNormal];
        [popoverBtn.titleLabel setFont:[UIFont fontWithName:@"Helvetica" size:16.0f]];
        [popoverBtn setContentHorizontalAlignment:UIControlContentHorizontalAlignmentLeft];
        popoverBtn.tag = SplitPopupBtnTag;
        [popoverBtn addTarget:self action:@selector(onBtnTaped) forControlEvents:UIControlEventTouchUpInside];
        // 样式相关
        HDSSkinType skinType = [HDSUtil skinType];
        UIColor *color = skinType == HDSSkinBlue?[UIColor blackColor]:[UIColor colorWithWhite:1.0f alpha:0.8f];
        [popoverBtn setTitleColor:color forState:UIControlStateNormal];
        [popoverBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_normal.png"] forState:UIControlStateNormal];
        [popoverBtn setBackgroundImage:[HDSUtil loadImageSkin:skinType imageName:@"select_highlight.png"] forState:UIControlStateHighlighted];
    }
    
    [[[splitController.viewControllers lastObject] view] addSubview:popoverBtn];
    //    [self.navigationItem setLeftBarButtonItem:barButtonItem animated:YES];
    self.masterPopoverController = popoverController;
}

- (void)splitViewController:(UISplitViewController *)splitController willShowViewController:(UIViewController *)viewController invalidatingBarButtonItem:(UIBarButtonItem *)barButtonItem{
    hasPopoverBtn = false;
    [popoverBtn removeFromSuperview];
    self.masterPopoverController = nil;
}
//-(BOOL)splitViewController:(UISplitViewController *)svc shouldHideViewController:(UIViewController *)vc inOrientation:(UIInterfaceOrientation)orientation{
//    return true;
//}


-(void)onBtnTaped{
//    [HDSUtil showFrameDetail:popoverBtn];
//    [HDSUtil showFrameDetail:self.detailViewController.view];
    // 在sdk5.1.1中与位置无关固定从左侧弹出
    [self.masterPopoverController presentPopoverFromRect:popoverBtn.frame inView:self.detailViewController.view permittedArrowDirections:UIPopoverArrowDirectionUp animated:YES];
}

- (IBAction)switchButtonTaped:(UIButton *)sender {
    CATransition *animation = [CATransition animation];
    animation.delegate = self; 
    animation.duration = 1;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    animation.type = @"pageUnCurl"; 
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
    
    [self.masterPopoverController dismissPopoverAnimated:NO];
    
    HDSAppDelegate *delegate = (HDSAppDelegate *)[[UIApplication sharedApplication] delegate];
    [[delegate sharedSplitVC].view removeFromSuperview];
    [delegate.window addSubview:[delegate sharedDashVC].view];
    [[delegate.window layer] addAnimation:animation forKey:@"animation"];
}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
    
}

- (IBAction)settingButtonTaped:(UIButton *)sender {
    OptionsViewController *optionsController = [OptionsViewController sharedOptionViewController];
    
    _optionsPopOver = [OptionsViewController sharedOptionPopoverController];
    _optionsPopOver.popoverContentSize = CGSizeMake(320, 640);
    optionsController.gridView = nil;
    optionsController.contentSizeForViewInPopover = CGSizeMake(320, 640);
    optionsController.popoverController = _optionsPopOver;
    
    [_optionsPopOver presentPopoverFromRect:sender.frame inView:self.view permittedArrowDirections:UIPopoverArrowDirectionAny animated:YES];
}
@end
