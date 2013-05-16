//
//  HDSRefreshDelegate.h
//  BI
//
//  Created by 毅 张 on 12-6-15.
//  Copyright (c) 2012年 烟台华东电子. All rights reserved.
//

@class HDSYearMonthPicker;

@protocol HDSRefreshDelegate <NSObject>

@optional
- (void) refreshByComps:(NSArray *) comps;
- (void) loadDataByComp;
- (void) refreshByDates:(NSDateComponents *) dates fromPopupBtn:(UIButton *)popupBtn;
- (void) loadDataByDate;
- (void) refreshByCargos:(NSArray *) cargos;
- (void) loadDataByCargos;

@end
