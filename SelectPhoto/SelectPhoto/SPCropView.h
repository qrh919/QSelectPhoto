//
//  SPCropView.h
//  SelectPhoto
//
//  Created by qrh on 2018/11/8.
//  Copyright © 2018年 applee. All rights reserved.
//

#import <UIKit/UIKit.h>

@class SPPhotoPreviewView,SPAssetModel;

@interface SPCropView : UIView

@property (nonatomic, strong) SPAssetModel *model;
@property (nonatomic, copy) void (^singleTapGestureBlock)(void);

@property (nonatomic, copy) void (^imageProgressUpdateBlock)(double progress);

@property (nonatomic, strong) SPPhotoPreviewView *previewView;

@property (nonatomic, assign) BOOL allowCrop;
@property (nonatomic, assign) CGRect cropRect;
@property (nonatomic, assign) BOOL isSquare;//是否为正方形裁剪 默认YES
@property (nonatomic, assign) CGFloat scale;//比例 正方形为1
- (void)recoverSubviews;
- (void)configSubviews;

@end
