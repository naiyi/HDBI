//
//  OptionsViewController.m
//  GMGridView
//
//  Created by Gulam Moledina on 11-11-01.
//  Copyright (c) 2011 GMoledina.ca. All rights reserved.
//

#import "OptionsViewController.h"
#import "GMGridView.h"
#import "HDSUtil.h"
#import "HDSAppDelegate.h"
#import "HDSMasterViewController.h"
#import "HDSLoginViewController.h"
#import "HDSDashboardViewController.h"

// Sections
typedef enum {
    OptionSectionLogin = 0, // 记住密码，自动登陆，切换用户
    OptionSectionDashboard, // 新增列表，删除开关，重新加载
    OptionSectionData,      // 离线数据，在线地址
    OptionSectionSkin,      // 蓝白主题，深色主题
    
    OptionSectionsCount
} OptionsTypeSections;

typedef enum {
    OptionRememberMe = 0,
    OptionAutoLogin,
    OptionChangeUser,
    
    OptionLoginCount
} OptionsTypeLogin;

typedef enum {
    OptionAddTile = 0,
    OptionDeleteTile,
    OptionReloadTile,
    
    OptionDashboardCount
} OptionsTypeDashboard;

typedef enum {
    OptionOffline = 0,
    OptionDataUrl,
    
    OptionDataCount
} OptionsTypeData;

typedef enum {
    OptionSkinBlue = 0,
    OptionSkinBlack,
    
    OptionSkinCount
} OptionsTypeSkin;

@interface OptionsViewController () <UITableViewDelegate, UITableViewDataSource> {
    __gm_weak UITableView *_tableView;
    NSMutableDictionary *setting;
    UISwitch *rememberMeSwitch;
    UISwitch *autoLoginSwitch;
    UISwitch *deleteTileSwitch;
    UIButton *changeUserButton;
    UIButton *reloadButton;
    UISwitch *offlineSwitch;
    UITextField *offlineURL;
    NSInteger selectedSkin;
}

@end

//////////////////////////////////////////////////////////////
#pragma mark - Implementation
//////////////////////////////////////////////////////////////

@implementation OptionsViewController

@synthesize gridView;
@synthesize popoverController;
@synthesize masterVC;
static OptionsViewController *_optionViewController;
static UIPopoverController *_optionPopoverController;

//////////////////////////////////////////////////////////////
#pragma mark Constructor
//////////////////////////////////////////////////////////////

+ (OptionsViewController *) sharedOptionViewController{
    if( _optionViewController == nil){
        _optionViewController = [[self alloc] init];
    }
    return _optionViewController;
}
+ (UIPopoverController *) sharedOptionPopoverController{
    if(_optionPopoverController == nil){
        _optionPopoverController =[[UIPopoverController alloc] initWithContentViewController:[[UINavigationController alloc] initWithRootViewController:[self sharedOptionViewController]]];
    }
    return _optionPopoverController;
}

- (id)init{
    if ((self = [super init])){
        self.title = @"选项";
    }
    return self;
}

//////////////////////////////////////////////////////////////
#pragma mark View lifecycle
//////////////////////////////////////////////////////////////

- (void)loadView{
    UITableView *tableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
    tableView.dataSource = self;
    tableView.delegate   = self;
    self.view = tableView;
    _tableView = tableView;
    rememberMeSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    autoLoginSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    deleteTileSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    [rememberMeSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [autoLoginSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    [deleteTileSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    changeUserButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [changeUserButton setTitle:@"切换用户" forState:UIControlStateNormal];
    changeUserButton.titleLabel.font = [HDSUtil getFontBySize:HDSFontSizeNormal];
    changeUserButton.frame = CGRectMake(0, 0, 85, 30);
    reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    [reloadButton setTitle:@"重新加载" forState:UIControlStateNormal];
    reloadButton.titleLabel.font = [HDSUtil getFontBySize:HDSFontSizeNormal];
    reloadButton.frame = CGRectMake(0, 0, 85, 30);
    [changeUserButton addTarget:self action:@selector(buttonTaped:) forControlEvents:UIControlEventTouchUpInside];
    [reloadButton addTarget:self action:@selector(buttonTaped:) forControlEvents:UIControlEventTouchUpInside];
    
    // 离线数据
    offlineSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
    [offlineSwitch addTarget:self action:@selector(switchChanged:) forControlEvents:UIControlEventValueChanged];
    offlineURL = [[UITextField alloc] initWithFrame:CGRectMake(0, 0, 200, 30)];
    offlineURL.borderStyle = UITextBorderStyleRoundedRect;
}
- (void)viewDidLoad{
    [super viewDidLoad];
}
- (void)viewDidUnload{
    [super viewDidUnload];
}

-(void)viewWillAppear:(BOOL)animated{
    // 读取设置文件
//    NSString *filePath = [HDSUtil settingFilePath];
//    setting = [[NSMutableDictionary alloc] initWithContentsOfFile:filePath];
    setting = [HDSUtil getSetting];
    
    rememberMeSwitch.on = [(NSNumber *)[setting objectForKey:@"rememberMe"] boolValue];
    autoLoginSwitch.on = [(NSNumber *)[setting objectForKey:@"autoLogin"] boolValue];
    NSString *userName = [setting objectForKey:@"userName"];
    if( [userName isEqualToString:Offline_Test_User] ){
        offlineSwitch.on = true;
        offlineSwitch.enabled = false;
    }else{
        NSString *offlineKey = [userName stringByAppendingString:@"-offline"];
        offlineSwitch.on = [(NSNumber *)[setting objectForKey:offlineKey] boolValue];
        offlineSwitch.enabled = true;
    }
    selectedSkin = [(NSNumber *)[setting objectForKey:@"skin"] integerValue];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return YES;
}


//////////////////////////////////////////////////////////////
#pragma mark UITableView datasource & delegates
//////////////////////////////////////////////////////////////
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section{
    return 32;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
    return 42;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return OptionSectionsCount;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section{
    switch (section) {
        case OptionSectionLogin:    return @"登录设置";
        case OptionSectionDashboard:return @"主页设置";
        case OptionSectionData:     return @"数据设置";
        case OptionSectionSkin:     return @"主题设置";
    }
    return @"Unknown";
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *label = [[UILabel alloc] init];
    label.frame = CGRectMake(15, 0, 100, 35);
    label.backgroundColor = [UIColor clearColor];
    label.shadowOffset = CGSizeMake(1.5, 1.5);
    label.textColor = [UIColor darkGrayColor];
    label.shadowColor = [UIColor lightGrayColor];
    label.font = [HDSUtil getFontBySize:HDSFontSizeBig];
    label.text = [self tableView:tableView titleForHeaderInSection:section];
    
    UIView *sectionView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, tableView.bounds.size.width, 35)];
    [sectionView addSubview:label];
    return sectionView;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    switch (section) {
        case OptionSectionLogin:    return OptionLoginCount;
        case OptionSectionDashboard:return OptionDashboardCount;
        case OptionSectionData:     return OptionDataCount;
        case OptionSectionSkin:     return OptionSkinCount;
    }
    return 0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"SettingCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    
    if (!cell) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.font = [HDSUtil getFontBySize:HDSFontSizeNormal];
    }
    
    if ([indexPath section] == OptionSectionLogin){
        switch ([indexPath row]) {
            case OptionRememberMe:{
                cell.textLabel.text = @"记住密码";
                rememberMeSwitch.on = [(NSNumber *)[setting objectForKey:@"rememberMe"] boolValue];
                cell.accessoryView = rememberMeSwitch;
                cell.accessoryType = UITableViewCellAccessoryNone;
                break;
            }
            case OptionAutoLogin:{
                cell.textLabel.text = @"自动登录";
                autoLoginSwitch.on = [(NSNumber *)[setting objectForKey:@"rememberMe"] boolValue];
                cell.accessoryView = autoLoginSwitch;
                cell.accessoryType = UITableViewCellAccessoryNone;
                break;
            }
            case OptionChangeUser:{
                cell.textLabel.text = @"切换用户";
                cell.accessoryView = changeUserButton;
                cell.accessoryType = UITableViewCellAccessoryNone;
                break;
            }
        }
    }else if ([indexPath section] == OptionSectionDashboard) {
        switch ([indexPath row]) {
            case OptionAddTile:
                cell.textLabel.text = @"添加页面";
                cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                cell.accessoryView = nil;
                break;
            case OptionDeleteTile:{
                cell.textLabel.text = @"删除页面";
                cell.accessoryView = deleteTileSwitch;
                cell.accessoryType = UITableViewCellAccessoryNone;
                break;
            }
            case OptionReloadTile:{
                cell.textLabel.text = @"重新加载";
                cell.accessoryView = reloadButton;
                cell.accessoryType = UITableViewCellAccessoryNone;
                break;
            }
        }
    }else if ([indexPath section] == OptionSectionData) {
        switch ([indexPath row]) {
            case OptionOffline:
                cell.textLabel.text = @"离线数据";
                cell.accessoryView = offlineSwitch;
                cell.accessoryType = UITableViewCellAccessoryNone;
                break;
            case OptionDataUrl:
                cell.textLabel.text = @"数据来源";
                cell.accessoryView = offlineURL;
                cell.accessoryType = UITableViewCellAccessoryNone;
                break;
        }
    }else if ([indexPath section] == OptionSectionSkin) {
        switch ([indexPath row]) {
            case OptionSkinBlue:
                cell.textLabel.text = @"梦幻蓝";
                if(selectedSkin == [indexPath row]){
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;  
                }else{
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
                cell.accessoryView = nil;
                break;
            case OptionSkinBlack:
                cell.textLabel.text = @"经典黑";
                if(selectedSkin == [indexPath row]){
                    cell.accessoryType = UITableViewCellAccessoryCheckmark;  
                }else{
                    cell.accessoryType = UITableViewCellAccessoryNone;
                }
                cell.accessoryView = nil;
                break;
        }
    }
//    else if ([indexPath section] == OptionSectionSorting)
//    {
//        switch ([indexPath row]) 
//        {
//            case OptionTypeSortingStyle:
//            {
//                cell.detailTextLabel.text = @"Style";
//                
//                UISegmentedControl *segmentedControl = [[UISegmentedControl alloc] initWithItems:[NSArray arrayWithObjects:@"Swap", @"Push", nil]];
//                segmentedControl.frame = CGRectMake(0, 0, 150, 30);
//                [segmentedControl addTarget:self action:@selector(sortStyleSegmentedControlChanged:) forControlEvents:UIControlEventValueChanged];
//                segmentedControl.selectedSegmentIndex = (self.gridView.style == GMGridViewStylePush) ? 1 : 0;
//                
//                cell.accessoryView = segmentedControl;
//                
//                break;
//            }
//        }
//    }
//    else if ([indexPath section] == OptionSectionGestures)
//    {
//        switch ([indexPath row]) 
//        {
//            case OptionTypeGesturesEditOnTap:
//            {
//                cell.detailTextLabel.text = @"Edit on Long Tap";
//                
//				UISwitch *editOnTapSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
//                [editOnTapSwitch addTarget:self action:@selector(editOnTapSwitchChanged:) forControlEvents:UIControlEventValueChanged];
//                editOnTapSwitch.on = self.gridView.enableEditOnLongPress;
//                
//                cell.accessoryView = editOnTapSwitch;
//                
//                break;
//            }
//            case OptionTypeGesturesDisableEditOnEmptySpaceTap:
//            {
//                cell.detailTextLabel.text = @"Disable edit on empty tap";
//                
//				UISwitch *disableEditOnEmptyTapSwitch = [[UISwitch alloc] initWithFrame:CGRectMake(0, 0, 100, 30)];
//                [disableEditOnEmptyTapSwitch addTarget:self action:@selector(disableEditOnEmptySpaceTapSwitchChanged:) forControlEvents:UIControlEventValueChanged];
//                disableEditOnEmptyTapSwitch.on = self.gridView.enableEditOnLongPress;
//                
//                cell.accessoryView = disableEditOnEmptyTapSwitch;
//                
//                break;
//            }
//        }
//    }
//    else if ([indexPath section] == OptionSectionDebug)
//    {
//        switch ([indexPath row]) 
//        {
//            case OptionTypeDebugGridBackground:
//            {
//                cell.detailTextLabel.text = @"Grid background color";
//                
//                UISwitch *backgroundSwitch = [[UISwitch alloc] init];
//                [backgroundSwitch addTarget:self action:@selector(debugGridBackgroundSwitchChanged:) forControlEvents:UIControlEventValueChanged];
//                backgroundSwitch.on = (self.gridView.backgroundColor != [UIColor clearColor]);
//                [backgroundSwitch sizeToFit];
//                
//                cell.accessoryView = backgroundSwitch;
//                
//                break;
//            }
//            case OptionTypeDebugReload:
//            {
//                cell.detailTextLabel.text = @"Reload from Datasource";
//                
//                UIButton *reloadButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
//                [reloadButton setReversesTitleShadowWhenHighlighted:YES];
//                [reloadButton setTitleColor:[UIColor redColor] forState:UIControlEventTouchUpInside];
//                [reloadButton setTitle:@"Reload" forState:UIControlStateNormal];
//                [reloadButton addTarget:self action:@selector(debugReloadButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
//                [reloadButton sizeToFit];
//                
//                cell.accessoryView = reloadButton;
//                
//                break;
//            }
//        }
//    }

    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath{
    return NO;
}


//////////////////////////////////////////////////////////////
#pragma mark Control callbacks
//////////////////////////////////////////////////////////////

- (void)switchChanged:(UISwitch *)control{
    if(control == rememberMeSwitch){
        if(!control.isOn){
            [autoLoginSwitch setOn:NO animated:YES]; 
            [self switchChanged:autoLoginSwitch];
        }
        [setting setObject:[NSNumber numberWithBool:control.on]  forKey:@"rememberMe"];
        [setting writeToFile:[HDSUtil settingFilePath] atomically:YES];
    }else if(control == autoLoginSwitch){
        if(control.isOn){
            [rememberMeSwitch setOn:YES animated:YES];
            [self switchChanged:rememberMeSwitch];
        }
        [setting setObject:[NSNumber numberWithBool:control.on]  forKey:@"autoLogin"];
        [setting writeToFile:[HDSUtil settingFilePath] atomically:YES];
    }else if(control == deleteTileSwitch){
        self.gridView.editing = control.on;
        control.on = self.gridView.isEditing;
        [self.gridView layoutSubviewsWithAnimation:GMGridViewItemAnimationFade];
        if(control.on){
            [self.popoverController dismissPopoverAnimated:YES];
        }
    }else if(control == offlineSwitch){
        if(control.on){
            //TODO 用离线数据刷新所有功能
        }else{
            //TODO 用数据库数据刷新所有功能
        }
        NSString *userName = [setting objectForKey:@"userName"];
        NSString *offlineKey = [userName stringByAppendingString:@"-offline"];
        [setting setObject:[NSNumber numberWithBool:control.on]  forKey:offlineKey];
        [setting writeToFile:[HDSUtil settingFilePath] atomically:YES];
    }
    
}

- (void) buttonTaped:(UIButton *)button{
    if(button == changeUserButton){
        [self.popoverController dismissPopoverAnimated:NO];
        
        HDSAppDelegate *delegate = (HDSAppDelegate *)[[UIApplication sharedApplication] delegate];
        // 切换用户或退出程序之前保存主页的模块布局配置
        [[delegate sharedDashVC] saveHomePageModuleLayout];
        
        CATransition *animation = [CATransition animation];
        animation.duration = 1;
        animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
        animation.type = kCATransitionFade; 
        // 页面跳转
        [[[delegate.window subviews] objectAtIndex:0] removeFromSuperview];
        [delegate sharedLoginVC].isChangeUser = YES;
        [delegate.window addSubview:[delegate sharedLoginVC].view];
        [[delegate.window layer] addAnimation:animation forKey:@"animation"];
        
        //TODO 清空与用户相关的数据
        
    }else if(button == reloadButton){
        [self.gridView reloadData];
    }
}

-(void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == OptionSectionDashboard && indexPath.row == OptionAddTile){
//        HDSAppDelegate *delegate = [[UIApplication sharedApplication] delegate];
//        HDSMasterViewController *masterVC = [delegate.storyboard instantiateViewControllerWithIdentifier:@"functionList"];
        if(self.masterVC == nil){
            self.masterVC = [[HDSMasterViewController alloc] initWithNibName:@"HDSMasterViewController" bundle:nil];
            self.masterVC.showedInSetting = true;
        }
        [[self navigationController] pushViewController:self.masterVC animated:YES];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    if(indexPath.section == OptionSectionSkin){
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
        if(cell.accessoryType == UITableViewCellAccessoryCheckmark)
            return ;
        cell.accessoryType = UITableViewCellAccessoryCheckmark;
        for(int i=0;i<[tableView numberOfRowsInSection:indexPath.section];i++){
            if(i != indexPath.row){
                [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:indexPath.section]].accessoryType = UITableViewCellAccessoryNone;
            }
        }
        [setting setObject:[NSNumber numberWithInteger:indexPath.row] forKey:@"skin"];
        [setting writeToFile:[HDSUtil settingFilePath] atomically:true];
        
        // 清空setting在HDSUtil中的缓存，使其他界面可以读取新修改的skinType
//        [HDSUtil clearSetting];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"themeNotification" 
            object:nil userInfo:nil];
        // 设置各种控件的外观
        [HDSUtil setSegmentSkin:[HDSUtil skinType]];
    }
}

//- (void)editOnTapSwitchChanged:(UISwitch *)control
//{
//    self.gridView.enableEditOnLongPress = control.on;
//}
//
//- (void)disableEditOnEmptySpaceTapSwitchChanged:(UISwitch *)control;
//{
//    self.gridView.disableEditOnEmptySpaceTap = control.on;
//}

@end
