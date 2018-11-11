//
//  SPBottomView.h
//  SelectPhoto
//
//  Created by qrh on 2018/11/9.
//  Copyright © 2018年 applee. All rights reserved.
//  底部选择

#import <UIKit/UIKit.h>

@interface SPBottomView : UIView

@property (nonatomic, copy) void(^selectBlock)(NSInteger index);
/// 当前选择的位置
@property (nonatomic, assign) NSInteger selectIndex;

@end
