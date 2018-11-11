//
//  SPCropView.m
//  SelectPhoto
//
//  Created by qrh on 2018/11/8.
//  Copyright © 2018年 applee. All rights reserved.
//

#import "SPCropView.h"
#import "SPPhotoPreviewCell.h"
#import "SPAssetModel.h"
#import <Photos/Photos.h>
@interface SPCropView()
@property (nonatomic, strong) UIButton *scaleBtn;
@end

@implementation SPCropView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self configSubviews];
        self.isSquare = YES;//默认正方形裁剪
        self.scale = 1;
    }
    return self;
}
//改变裁剪尺寸 750x750 750x900
-(void)scaleAction:(UIButton *)sender{
    CGFloat assetW = self.model.asset.pixelWidth;
    CGFloat assetH = self.model.asset.pixelHeight;
    if(assetW >= assetH){//宽图 本身是正方形不处理
        if(self.previewView.scrollView.zoomScale != 1.0){
            [self.previewView.scrollView setZoomScale:1.0 animated:YES];
        }else{
            if(assetW > assetH){
                CGFloat scale = self.model.asset.pixelWidth/self.bounds.size.width;
                CGFloat rescale = self.bounds.size.height / (self.model.asset.pixelHeight/scale);
                [self.previewView.scrollView setZoomScale:rescale animated:YES];
            }
        }
        _scale = 1;
        _isSquare = YES;
        self.cropRect = self.bounds;
    }else{
        if(self.previewView.scrollView.zoomScale != 1.0){
            [self.previewView.scrollView setZoomScale:1.0 animated:YES];
        }else{
            if(_isSquare){
                _scale = 750/900.0;//裁剪长宽比
                CGFloat margin = (self.bounds.size.width - self.bounds.size.height*_scale)/2;
                [UIView animateWithDuration:0.2 animations:^{
                    self.previewView.frame = CGRectMake(margin, 0, self.bounds.size.height*self.scale, self.bounds.size.height);
                    [self layoutIfNeeded];
                }];
                _isSquare = NO;
                self.cropRect = self.previewView.frame;//CGRectMake(0, 0, self.bounds.size.width, self.bounds.size.height/_scale);
            }else{
                _scale = 1;
                [UIView animateWithDuration:0.2 animations:^{
                    self.previewView.frame = self.bounds;
                    [self layoutIfNeeded];
                }];
                _isSquare = YES;
                self.cropRect = self.bounds;
            }
        }
    }
}

- (void)configSubviews {
    self.previewView = [[SPPhotoPreviewView alloc] initWithFrame:self.bounds];
    __weak typeof(self) weakSelf = self;
    [self.previewView setSingleTapGestureBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.singleTapGestureBlock) {
            strongSelf.singleTapGestureBlock();
        }
    }];
    [self.previewView setImageProgressUpdateBlock:^(double progress) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.imageProgressUpdateBlock) {
            strongSelf.imageProgressUpdateBlock(progress);
        }
    }];
    [self addSubview:self.previewView];
    [self addSubview:self.scaleBtn];
    self.cropRect = self.bounds;
}

- (void)setModel:(SPAssetModel *)model {
    _model = model;
    _previewView.asset = model.asset;
}

- (void)recoverSubviews {
    [_previewView recoverSubviews];
}

- (void)setAllowCrop:(BOOL)allowCrop {
    _allowCrop = allowCrop;
    _previewView.allowCrop = allowCrop;
}

- (void)setCropRect:(CGRect)cropRect {
    _cropRect = cropRect;
    _previewView.cropRect = cropRect;
}

- (void)layoutSubviews {
    [super layoutSubviews];
//    self.previewView.frame = self.bounds;
}

-(UIButton *)scaleBtn{
    if(!_scaleBtn){
        _scaleBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        _scaleBtn.frame = CGRectMake(10, self.bounds.size.height-40, 40, 40);
        [_scaleBtn setImage:[UIImage imageNamed:@"ic_publish_narrow"] forState:UIControlStateNormal];
        [_scaleBtn addTarget:self action:@selector(scaleAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _scaleBtn;
}

@end
