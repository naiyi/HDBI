//
//  HDSYearMonthPicker.h
//  BI
//
//  Created by 毅 张 on 12-6-21.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

#import "HDSRefreshDelegate.h"

typedef enum{
    HDSYearPickerFormat = 0,
    HDSYearMonthPickerFormat,
    HDSYearMonthDayPickerFormat
}HDSPickerFormat;

@interface HDSYearMonthPicker : UIViewController <UIPickerViewDelegate,UIPickerViewDataSource,UIPopoverControllerDelegate>

@property (unsafe_unretained, nonatomic) IBOutlet UIPickerView *picker;
@property (unsafe_unretained,nonatomic) id<HDSRefreshDelegate> delegate;
@property (unsafe_unretained,nonatomic) UIButton *popupBtn;
@property (assign,nonatomic,readwrite) HDSPickerFormat dateFormat;
@property (strong,nonatomic) NSDateComponents *scrollToDate;
@property (strong,nonatomic) NSDateComponents *nowDate;

- (id)initWithDateFormat:(HDSPickerFormat) dateFormat popupBtn:(UIButton *)popupBtn;

@end
