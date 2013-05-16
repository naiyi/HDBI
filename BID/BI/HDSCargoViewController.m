//
//  HDSCargoViewController.m
//  BI
//
//  Created by 毅 张 on 12-6-14.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSCargoViewController.h"
#import "HDSUtil.h"
#import "HDSCargoDelegate.h"

@interface HDSCargoViewController (){
    BOOL isAllSelected;
    BOOL isChanged;
}

@end

@implementation HDSCargoViewController

@synthesize checkedIndex;
@synthesize delegate;
//@synthesize cargoLabel,cargoValue;

static NSArray *cargos;

+ (NSArray *) cargos{
    if(cargos == nil){
        [self loadCargos];
        return nil;
    }else{
        return cargos;
    }
}

+ (void) setCargos:(NSArray *)_cargos{
    cargos = _cargos;
}

+ (void) loadCargos{
    if (cargos == nil ) {
        HDSCargoDelegate *delegate  = [[HDSCargoDelegate alloc] init];
        if([HDSUtil isOffline]){    // 离线数据
            [delegate.parser parse:[[NSData alloc] initWithContentsOfURL:[[NSBundle mainBundle] URLForResource:@"HDSCargos" withExtension:@"json"]]];
        }else{
            NSString *url = [[HDSUtil serverURL] stringByAppendingFormat: @"/bi_pad/qc/listCargoKind.json"];
            NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:url] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:Http_Request_Timeout];
            // 为保证公司数据首先被加载，应使用同步请求
            NSError *error;
            NSData *data = [NSURLConnection sendSynchronousRequest:theRequest returningResponse:nil error:&error];
            if(data == nil){
                NSLog(@"load cargos error is: %@",error);
            }else{
                [delegate parseData:data];
            }
        }
    }
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        if(cargos == nil){
            [self.class loadCargos];
        }
        checkedIndex = [[NSMutableArray alloc] initWithCapacity:cargos.count];
        for (int i=0; i<cargos.count; i++) {
            [checkedIndex addObject:[NSNumber numberWithInt:1]]; 
        }
        isAllSelected = true;
        isChanged = false;
    }
    return self;
}


- (void)viewDidLoad
{
    [super viewDidLoad];
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    return YES;
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return cargos.count+1 /* 1:全选项目 */;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *CellIdentifier = @"CompanyCell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    
    if(cell == nil){
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
    }
    if(indexPath.row == 0){ // 全选
        cell.textLabel.text = @"全选";
        cell.accessoryType = isAllSelected ? UITableViewCellAccessoryCheckmark :UITableViewCellAccessoryNone; 
    }else{
        cell.textLabel.text = [[cargos objectAtIndex:indexPath.row-1] objectForKey:@"name"];
        if([checkedIndex objectAtIndex:indexPath.row-1] == [NSNumber numberWithInt:1]){
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
        }else{
            cell.accessoryType = UITableViewCellAccessoryNone;
        } 
    }
    return cell;
}

/*
 // Override to support conditional editing of the table view.
 - (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the specified item to be editable.
 return YES;
 }
 */

/*
 // Override to support editing the table view.
 - (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
 {
 if (editingStyle == UITableViewCellEditingStyleDelete) {
 // Delete the row from the data source
 [tableView deleteRowsAtIndexPaths:[NSArray arrayWithObject:indexPath] withRowAnimation:UITableViewRowAnimationFade];
 }   
 else if (editingStyle == UITableViewCellEditingStyleInsert) {
 // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
 }   
 }
 */

/*
 // Override to support rearranging the table view.
 - (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath
 {
 }
 */

/*
 // Override to support conditional rearranging of the table view.
 - (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath
 {
 // Return NO if you do not want the item to be re-orderable.
 return YES;
 }
 */

#pragma mark - Table view delegate

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    if(indexPath.row == 0){
        isAllSelected = !isAllSelected;
        cell.accessoryType = isAllSelected ? UITableViewCellAccessoryCheckmark :UITableViewCellAccessoryNone; 
        for(int i=1;i<cargos.count+1;i++){
            UITableViewCell *otherCell  = [tableView cellForRowAtIndexPath:[NSIndexPath indexPathForRow:i inSection:0]];
            otherCell.accessoryType = isAllSelected ? UITableViewCellAccessoryCheckmark :UITableViewCellAccessoryNone;
            [checkedIndex replaceObjectAtIndex:i-1 withObject:isAllSelected ? [NSNumber numberWithInt:1] : [NSNumber numberWithInt:0]];
        }
    }else{
        if([checkedIndex objectAtIndex:indexPath.row-1] == [NSNumber numberWithInt:1]){
            cell.accessoryType = UITableViewCellAccessoryNone;
            [checkedIndex replaceObjectAtIndex:indexPath.row-1 withObject:[NSNumber numberWithInt:0]];
        }else{
            cell.accessoryType = UITableViewCellAccessoryCheckmark;
            [checkedIndex replaceObjectAtIndex:indexPath.row-1 withObject:[NSNumber numberWithInt:1]];
        }
    }
    
    NSMutableArray *comps = [[NSMutableArray alloc] initWithCapacity:checkedIndex.count];
    for(int i=0;i<checkedIndex.count;i++){
        if ([(NSNumber *)[checkedIndex objectAtIndex:i] intValue] == 1) {
            [comps addObject:[cargos objectAtIndex:i]];
        }
    }
    if([delegate respondsToSelector:@selector(refreshByCargos:)]){
        [delegate refreshByCargos:comps];
    }
    isChanged = true;
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController{
    // 至少选择一个项目
    for(int i=0;i<checkedIndex.count;i++){
        if ([(NSNumber *)[checkedIndex objectAtIndex:i] intValue] == 1) {
            return true;
        }
    }
    return false;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    if(isChanged && [delegate respondsToSelector:@selector(loadDataByCargos)]){
        [delegate loadDataByCargos];
    }
    isChanged = false;
}

@end
