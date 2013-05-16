//
//  HDSYearMonthPicker.m
//  BI
//
//  Created by 毅 张 on 12-6-21.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSYearMonthPicker.h"
#define BEGIN_YEAR 2000

@interface HDSYearMonthPicker (){
    NSInteger yearLength;
    NSInteger monthLength;
    NSInteger dayLength;
    BOOL isChanged;
}

@end

@implementation HDSYearMonthPicker
@synthesize picker;
@synthesize delegate;
@synthesize popupBtn = _popupBtn;
@synthesize dateFormat = _dateFormat;
@synthesize scrollToDate;
@synthesize nowDate;

- (id)initWithDateFormat:(HDSPickerFormat)dateFormat popupBtn:(UIButton *)popupBtn{
    _dateFormat = dateFormat;
    _popupBtn = popupBtn;
    return [self init];
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        NSCalendar *calendar = [NSCalendar currentCalendar];
        // 默认选中当前年月日
        scrollToDate = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
        nowDate = [calendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit fromDate:[NSDate date]];
        isChanged = false;
    }
    return self;
}

- (void)viewDidLoad{
    [super viewDidLoad];
    float pickerWidth = 0.0f;
    switch (_dateFormat) {
        case HDSYearPickerFormat:   pickerWidth = 100.0f;   break;
        case HDSYearMonthPickerFormat:   pickerWidth = 200.0f;   break;
        case HDSYearMonthDayPickerFormat:   pickerWidth = 300.0f;   break;
    }
    CGRect f = self.view.frame;
    f.size.width = pickerWidth;
    self.view.frame = f;
    
    yearLength = [nowDate year]-BEGIN_YEAR+1;
    monthLength = [nowDate month];//不能选择当前时间之后的月份
    
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSRange range = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:[NSDate date]];
    dayLength = range.length;
}

-(void)viewDidAppear:(BOOL)animated{
    switch (_dateFormat) {
        case HDSYearMonthDayPickerFormat:
            [picker selectRow:[scrollToDate day]-1 inComponent:2 animated:YES];
        case HDSYearMonthPickerFormat:
            [picker selectRow:[scrollToDate month]-1 inComponent:1 animated:YES];
        case HDSYearPickerFormat:
            [picker selectRow:[scrollToDate year]-BEGIN_YEAR inComponent:0 animated:YES];
        default:
            break;
    }
}

- (void)viewDidUnload{
    [self setPicker:nil];
    [super viewDidUnload];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation{
    return YES;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView{
    switch (_dateFormat) {
        case HDSYearPickerFormat: return 1;
        case HDSYearMonthPickerFormat: return 2;
        case HDSYearMonthDayPickerFormat: return 3;
        default:    return 0;
    }
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component{
    switch (component) {
        case 0: return yearLength;
        case 1: return monthLength;    
        case 2: return dayLength;
        default:    return 0;
    }
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component{
    if(component == 0){
        return [NSString stringWithFormat:@"%d年",BEGIN_YEAR+row];
    }else if(component == 1){
        return [NSString stringWithFormat:@"%2d月",row+1];
    }else{
        return [NSString stringWithFormat:@"%2d日",row+1];
    }
    
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component{
    if(component == 0){
        [scrollToDate setYear:BEGIN_YEAR+row];
        // 处理2月29日的情况
        if([scrollToDate month] == 2 && _dateFormat == HDSYearMonthDayPickerFormat){
            [self refreshDayComponent];
        }
        // 月份不超过当前年月
        if(_dateFormat == HDSYearMonthDayPickerFormat || _dateFormat == HDSYearMonthPickerFormat){
            if(BEGIN_YEAR+row != [nowDate year]){
                monthLength = 12;
            }else{
                monthLength = [nowDate month];
            }
            [picker reloadComponent:1];
            if ([scrollToDate month] > monthLength) {
                scrollToDate.month = monthLength;
            }
        }
    }else if(component == 1){
        [scrollToDate setMonth:row+1];
        if(_dateFormat == HDSYearMonthDayPickerFormat){
            [self refreshDayComponent];
        }
    }else{
        [scrollToDate setDay:row+1];
    }
    if([delegate respondsToSelector:@selector(refreshByDates:fromPopupBtn:)]){
        [delegate refreshByDates:scrollToDate fromPopupBtn:_popupBtn];
    }
    isChanged = true;
}

- (void)refreshDayComponent{
    NSInteger tempDay = [scrollToDate day];
    [scrollToDate setDay:1];
    NSCalendar *calendar = [NSCalendar currentCalendar];
    NSRange range = [calendar rangeOfUnit:NSDayCalendarUnit inUnit:NSMonthCalendarUnit forDate:[calendar dateFromComponents:scrollToDate]];
    if(tempDay <= range.length){
        [scrollToDate setDay:tempDay];
    }else{
        [scrollToDate setDay:range.length];
    }
    dayLength = range.length;
    [picker reloadComponent:2];
    [picker selectRow:[scrollToDate day]-1 inComponent:2 animated:YES];
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController{
    if(isChanged && [delegate respondsToSelector:@selector(loadDataByDate)]){
        [delegate loadDataByDate];
    }
    isChanged = false;
}

@end
