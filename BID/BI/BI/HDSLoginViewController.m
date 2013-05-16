//
//  HDSLoginViewController.m
//  BI
//
//  Created by 毅 张 on 12-5-24.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSLoginViewController.h"
#import "HDSAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#import "HDSDashboardViewController.h"
#import "HDSUtil.h"
#import "HDSFunctionCache.h"
#import "HDSMasterViewController.h"
#import "HDSDetailViewController.h"
#import "OptionsViewController.h"

@implementation HDSLoginViewController{
    UIActivityIndicatorView *_indicator;
    UILabel *_errorLine;
    BOOL _isHinting ;
    UITabBarController *tabBarController;
    UIDeviceOrientation _deviceOrientation;
    
    BOOL loginSucceed;
    NSString *loginErrorInfo;
}
@synthesize popup;

@synthesize backgroundImageView;
@synthesize userName;
@synthesize userPassword;
@synthesize rememberMe;
@synthesize autoLogin;
@synthesize loginButton;
@synthesize isChangeUser;
@synthesize loginUserId;
@synthesize allFunctions;

// 使用故事板创建会调用该初始化方法
-(id)initWithCoder:(NSCoder *)aDecoder{
    self = [super initWithCoder:aDecoder];
    if(self){
        isChangeUser = false;
    }
    return self;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if(self){
        isChangeUser = false;
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    
    // 自定义登陆按钮样式
    UIImage *loginButtoneNormal = [UIImage imageNamed:@"login_button"];
    [loginButton setBackgroundImage:loginButtoneNormal forState:UIControlStateNormal];
    UIImage *loginButtonPressed = [UIImage imageNamed:@"login_button1"];
    [loginButton setBackgroundImage:loginButtonPressed forState:UIControlStateHighlighted];
    rememberMe.on = NO;
    autoLogin.on = NO;
    
    popup.layer.cornerRadius = 8;
    popup.layer.masksToBounds = YES;
    //给图层添加一个有色边框
//    popup.layer.borderWidth = 5;
//    popup.layer.borderColor = [[UIColor grayColor] CGColor];
    popup.alpha = 0.0;
    
    _indicator = (UIActivityIndicatorView *)[popup viewWithTag:1];
    _errorLine = (UILabel *)[popup viewWithTag:2]; 
}

-(void)viewWillAppear:(BOOL)animated{
    // 读取设置文件
    NSMutableDictionary *setting = [HDSUtil getSetting];
    
    userName.text = [setting objectForKey:@"userName"];
    if([setting objectForKey:@"rememberMe"]){
        rememberMe.on = [(NSNumber *)[setting objectForKey:@"rememberMe"] boolValue];
        if (rememberMe.on) {
            userPassword.text = [setting objectForKey:@"userPassword"];
        }
    }else{
        rememberMe.on = NO;
    }
    if([setting objectForKey:@"autoLogin"]){
        autoLogin.on = [(NSNumber *)[setting objectForKey:@"autoLogin"] boolValue];
        if(autoLogin.isOn && !isChangeUser){ // 自动跳过登陆页面
            [self loginButtonTaped:nil];
        }
    }else{
        autoLogin.on = NO;
    }
}

-(void)viewDidAppear:(BOOL)animated{
}

- (void)viewDidUnload {
    [self setBackgroundImageView:nil];
    [self setUserName:nil];
    [self setUserPassword:nil];
    [self setRememberMe:nil];
    [self setAutoLogin:nil];
    [self setLoginButton:nil];
    [self setPopup:nil];
    [super viewDidUnload];
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation{
//    return toInterfaceOrientation == UIInterfaceOrientationPortrait;
//    return toInterfaceOrientation == UIInterfaceOrientationLandscapeRight;
    return YES;
}

- (void)willAnimateRotationToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation duration:(NSTimeInterval)duration{
    if(UIInterfaceOrientationIsPortrait(toInterfaceOrientation)){
        backgroundImageView.image = [UIImage imageNamed:@"login_y2"];
        userName.frame = CGRectMake(324, 409, 252, 31);
        userPassword.frame = CGRectMake(324, 460, 252, 31);
        rememberMe.frame = CGRectMake(325, 510, 79, 27);
        autoLogin.frame = CGRectMake(498, 510, 79, 27);
        loginButton.frame = CGRectMake(392, 552, 118, 34);
        popup.frame = CGRectMake(279, 357, 256, 44);
    }else{
        backgroundImageView.image = [UIImage imageNamed:@"login_y1"];
        userName.frame = CGRectMake(456, 285, 252, 31);
        userPassword.frame = CGRectMake(456, 336, 252, 31);
        rememberMe.frame = CGRectMake(456, 388, 79, 27);
        autoLogin.frame = CGRectMake(629, 388, 79, 27);
        loginButton.frame = CGRectMake(523, 435, 118, 34);
        popup.frame = CGRectMake(408, 234, 256, 44);
    }
}

- (IBAction)switchChanged:(UISwitch *)sender {
    popup.alpha = 0.8;
    _errorLine.textColor = [UIColor blackColor];
    if(rememberMe == sender){
        if(rememberMe.isOn){
            _errorLine.text = @"[记住密码] 已经开启";
        }else{
            _errorLine.text = @"[记住密码] 已经关闭";
            [autoLogin setOn:NO animated:YES];
        }
    }else {
        if(autoLogin.isOn){
            // 自动登陆的前提必须记住密码
            [rememberMe setOn:YES animated:YES];
            _errorLine.text = @"[自动登录] 已经开启";
        }else{
            _errorLine.text = @"[自动登录] 已经关闭";
        }
    }
    [self performSelector:@selector(fadeOutPopup) withObject:nil afterDelay:1.0];
}

- (void)sendLoginRequest:(id)userInfo {
	// 这里进行数据的处理，比如向网络请求、大量计算等等
    NSString *url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/sys/login.json?username=%@&pwd=%@",userName.text,userPassword.text];
    NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
    // 使用同步请求
    NSError *error;
    NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:nil error:&error];
    if(data == nil){
        NSLog(@"login error is: %@",error);
        loginErrorInfo = @"远程服务器无响应";
        loginSucceed = false;
    }else{
        SBJsonStreamParserAdapter *adapter = [[SBJsonStreamParserAdapter alloc] init];
        adapter.delegate = self;
        SBJsonStreamParser *parser = [[SBJsonStreamParser alloc] init];
        parser.delegate = adapter;
        SBJsonStreamParserStatus status = [parser parse:data];
        if (status == SBJsonStreamParserError) {
            NSLog(@"The parser encountered an error: %@ in %@", parser.error,@"用户登陆");
            loginErrorInfo = @"解析用户信息错误";
            loginSucceed = false;
        } else if (status == SBJsonStreamParserWaitingForData) {
            NSLog(@"Parser waiting for more data in %@",@"用户登陆");
        }
    }
	[self performSelectorOnMainThread:@selector(endLoading) withObject:nil waitUntilDone:NO];
}

- (void)parser:(SBJsonStreamParser *)parser foundArray:(NSArray *)array {
    
}

- (void)parser:(SBJsonStreamParser*)parser foundObject:(NSDictionary*)dict{
    NSString *success = [dict objectForKey:@"success"];
    if([success isEqualToString:@"true"]){
        loginSucceed = true;
        loginUserId = [dict objectForKey:@"userId"];
        // 将所有功能按funcId分类并填充到不同的数组中
        NSMutableArray *fc0key = [[NSMutableArray alloc] initWithCapacity:16];
        NSMutableArray *fc1key = [[NSMutableArray alloc] initWithCapacity:16];
        NSMutableArray *fc2key = [[NSMutableArray alloc] initWithCapacity:16];
        NSMutableArray *fc0val = [[NSMutableArray alloc] initWithCapacity:16];
        NSMutableArray *fc1val = [[NSMutableArray alloc] initWithCapacity:16];
        NSMutableArray *fc2val = [[NSMutableArray alloc] initWithCapacity:16];
        NSMutableArray *fs0key = [[NSMutableArray alloc] initWithCapacity:16];
        NSMutableArray *fs1key = [[NSMutableArray alloc] initWithCapacity:16];
        NSMutableArray *fs2key = [[NSMutableArray alloc] initWithCapacity:16];
        NSMutableArray *fs0val = [[NSMutableArray alloc] initWithCapacity:16];
        NSMutableArray *fs1val = [[NSMutableArray alloc] initWithCapacity:16];
        NSMutableArray *fs2val = [[NSMutableArray alloc] initWithCapacity:16];
        
        allFunctions = [dict objectForKey:@"func"];
        for(NSDictionary *func in allFunctions){
            NSString *funcId = [func objectForKey:@"funcId"];
            NSString *funcNam = [func objectForKey:@"name"];
            NSString *funcVal = [func objectForKey:@"val"];
            if([funcId hasPrefix:@"C001"]){
                [fc0key addObject:funcNam];
                [fc0val addObject:funcVal];
            }else if([funcId hasPrefix:@"C002"]){
                [fc1key addObject:funcNam];
                [fc1val addObject:funcVal];
            }else if([funcId hasPrefix:@"C003"]){
                [fc2key addObject:funcNam];
                [fc2val addObject:funcVal];
            }else if([funcId hasPrefix:@"S001"]){
                [fs0key addObject:funcNam];
                [fs0val addObject:funcVal];
            }else if([funcId hasPrefix:@"S002"]){
                [fs1key addObject:funcNam];
                [fs1val addObject:funcVal];
            }else if([funcId hasPrefix:@"S003"]){
                [fs2key addObject:funcNam];
                [fs2val addObject:funcVal];
            }
        }
        
        HDSFunctionCache *fc = [HDSFunctionCache sharedFunctionCache];
        fc.fc0key = fc0key;     fc.fc1key = fc1key;     fc.fc2key = fc2key;
        fc.fc0val = fc0val;     fc.fc1val = fc1val;     fc.fc2val = fc2val;
        fc.fs0key = fs0key;     fc.fs1key = fs1key;     fc.fs2key = fs2key;
        fc.fs0val = fs0val;     fc.fs1val = fs1val;     fc.fs2val = fs2val;
        
        // 主页功能列表
        NSArray *homeFunctions = [dict objectForKey:@"homeFunc"];
        NSMutableArray *mainPageFunctions = [[NSMutableArray alloc] initWithCapacity:9];
        for(NSDictionary *func in homeFunctions){
            NSString *funcVal = [func objectForKey:@"val"];
            [mainPageFunctions addObject:funcVal];
        }
        fc.mainPageFunctions = mainPageFunctions;
        
    }else{
        loginSucceed = false;
        loginErrorInfo = @"用户名或密码错误";
    }
}

- (void)endLoading {
	[_indicator stopAnimating];
    
    if( loginSucceed ){
        popup.alpha = 0;
        _isHinting = false;
        [self finishLogin];
    }else{
        _errorLine.textColor = [UIColor redColor];
        _errorLine.text = loginErrorInfo;
        [self performSelector:@selector(fadeOutPopup) withObject:nil afterDelay:1.0];
    }
}

- (void) finishLogin{
    
    NSMutableDictionary *setting = [HDSUtil getSetting];
    
    // 在文件中纪录用户名
    [setting setObject:userName.text forKey:@"userName"];
    [setting setObject:userPassword.text forKey:@"userPassword"];
    [setting setObject:[NSNumber numberWithBool:rememberMe.isOn] forKey:@"rememberMe"];
    [setting setObject:[NSNumber numberWithBool:autoLogin.isOn] forKey:@"autoLogin"];
    [setting writeToFile:[HDSUtil settingFilePath] atomically:YES];
    
    // 加载所有代码表，因为离线选项要从setting文件中读取，故在保存完setting之后执行
    [HDSUtil loadAllCode];
    
    // 每次重新登陆完毕都需要更新dashboard和split,同时还应该清除所有功能viewController的缓存,否则仍停留在上次登陆时的数据
    [[HDSFunctionCache sharedFunctionCache] clearFunctionCache];
    HDSAppDelegate *delegate = (HDSAppDelegate *)[[UIApplication sharedApplication] delegate];
    [[delegate sharedDashVC] reloadView];
    
    // 更新master view的菜单
    HDSMasterViewController *mvc = (HDSMasterViewController *)[[delegate sharedSplitVC].viewControllers objectAtIndex:0];
    [mvc reloadMenuData];
    [mvc.tableView reloadData];
    [mvc.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:false];
    mvc.lastSelected = nil;
    
    // 更新option中的master view的菜单
    HDSMasterViewController *menuMvc= [OptionsViewController sharedOptionViewController].masterVC;
    [menuMvc reloadMenuData];
    [menuMvc.tableView reloadData];
    [menuMvc.tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:0 inSection:0] atScrollPosition:UITableViewScrollPositionTop animated:false];
    
    // 将detail view重置回初始空页面
    NSMutableArray *viewControllers = (NSMutableArray *)[[delegate sharedSplitVC].viewControllers mutableCopy];
    HDSDetailViewController *dvc = [[HDSDetailViewController alloc] initWithNibName:@"HDSDetailViewController" bundle:nil];
    [viewControllers removeLastObject];
    [viewControllers addObject:dvc];
    [delegate sharedSplitVC].viewControllers = viewControllers;
    mvc.detailViewController = dvc;
    
    //  CA动画实现
    CATransition *animation = [CATransition animation];
    animation.delegate = self; 
    animation.duration = 2;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    // 设定动画类型
    //kCATransitionFade 淡化 kCATransitionPush 推挤 kCATransitionReveal 揭开 kCATransitionMoveIn 覆盖
    //@"cube" 立方体 @"suckEffect" 吸收 @"oglFlip" 翻转 @"rippleEffect" 波纹 @"pageCurl" 翻页 
    //@"pageUnCurl" 反翻页 @"cameraIrisHollowOpen" 镜头开 @"cameraIrisHollowClose" 镜头关
    animation.type = @"rippleEffect"; 

    // 页面跳转
    [self.view removeFromSuperview];
    [delegate.window addSubview:[delegate sharedDashVC].view];
    [[delegate.window layer] addAnimation:animation forKey:@"animation"];

}

-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag {
     
}

- (void)fadeOutPopup{
    [UIView animateWithDuration:2.0 animations:^{   
        popup.alpha = 0.0;
    }   completion:^(BOOL finished){
        _isHinting = false;
    }];
}

- (IBAction)loginButtonTaped:(UIButton *)sender {
    if(_isHinting)  return;
    // 验证非空
    if([userName.text isEqualToString:@""] || [userPassword.text isEqualToString:@""]){
        //TODO 可以用红色X代替indicator的位置，分三种：信息、错误、读取
        popup.alpha = 0.8;
        _errorLine.textColor = [UIColor redColor];
        _errorLine.text = @"用户名和密码不能为空";
        _isHinting = true;
        [self performSelector:@selector(fadeOutPopup) withObject:nil afterDelay:1.0];
    
        return;
    }
    
    // 校验用户名和密码
//    indicator = [[UIActivityIndicatorView alloc] initWithFrame:CGRectMake(0.0, 0.0, 64, 64)];
//    [indicator setCenter:CGPointMake(self.view.center.x, self.view.center.y)];
//    _indicator.activityIndicatorViewStyle = UIActivityIndicatorViewStyleWhite;
    popup.alpha = 0.8;
    _errorLine.textColor = [UIColor blackColor];
    _errorLine.text = @"     登陆中,请稍后...";
    _isHinting = true;
    [_indicator startAnimating];
    
    // 离线测试用户
    if([userName.text isEqualToString:Offline_Test_User] && [userPassword.text isEqualToString:Offline_Test_Pass]){
        loginSucceed = true;
        [self performSelectorOnMainThread:@selector(endLoading) withObject:nil waitUntilDone:NO];
    }else{  // 访问应用服务器校验用户名和密码并获得权限功能列表
//        [NSThread detachNewThreadSelector:@selector(loadingInfo:) toTarget:self withObject:nil];
        [self performSelectorInBackground:@selector(sendLoginRequest:) withObject:nil]; 
    }

}


@end
