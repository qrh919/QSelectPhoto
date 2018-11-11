//
//  SPNavToolBar.h
//  SelectPhoto
//
//  Created by qrh on 2018/11/8.
//  Copyright © 2018年 applee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SPNavToolBar : UIView

@property (nonatomic, copy) void(^toolBarClickBlock)(NSInteger index);

@end
