//
//  SelectSuccessCell.h
//  SelectPhoto
//
//  Created by qrh on 2018/11/8.
//  Copyright © 2018年 applee. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SelectSuccessCell : UICollectionViewCell

@property (nonatomic, strong) UIImage *image;

@property (nonatomic, assign) BOOL hideDelete;

@property (nonatomic, copy) void (^deleteBlock)(UIImage *image);

- (UIView *)snapshotView;

@end
