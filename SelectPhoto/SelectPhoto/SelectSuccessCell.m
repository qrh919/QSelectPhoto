//
//  SelectSuccessCell.m
//  SelectPhoto
//
//  Created by qrh on 2018/11/8.
//  Copyright © 2018年 applee. All rights reserved.
//

#import "SelectSuccessCell.h"

@interface SelectSuccessCell()
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIButton *deleteBtn;
@end

@implementation SelectSuccessCell

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self configSubViews];
    }
    return self;
}

-(void)setImage:(UIImage *)image{
    _image = image;
    _imageView.image = image;
}

-(void)setHideDelete:(BOOL)hideDelete{
    _hideDelete = hideDelete;
    _deleteBtn.hidden = hideDelete;
}

-(void)deleteAction:(UIButton *)sender{
    if(self.deleteBlock){
        self.deleteBlock(_image);
    }
}

#pragma mark - subviews
-(void)configSubViews{
    [self.contentView addSubview:self.imageView];
    [self.contentView addSubview:self.deleteBtn];
    [_imageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.contentView);
    }];
    [_deleteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.equalTo(self.contentView);
        make.size.mas_equalTo(CGSizeMake(40, 40));
    }];
}

-(UIImageView *)imageView{
    if(!_imageView){
        _imageView = [[UIImageView alloc] init];
//        _imageView.contentMode = UIViewContentModeScaleAspectFill;
        _imageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _imageView;
}

-(UIButton *)deleteBtn{
    if(!_deleteBtn){
        _deleteBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        _deleteBtn.titleLabel.font = [UIFont boldSystemFontOfSize:15];
        [_deleteBtn setTitle:@"X" forState:(UIControlStateNormal)];
        [_deleteBtn setTitleColor:[UIColor whiteColor] forState:(UIControlStateNormal)];
        [_deleteBtn setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5]];
        [_deleteBtn addTarget:self action:@selector(deleteAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _deleteBtn;
}

- (UIView *)snapshotView {
    UIView *snapshotView = [[UIView alloc]init];
    
    UIView *cellSnapshotView = nil;
    
    if ([self respondsToSelector:@selector(snapshotViewAfterScreenUpdates:)]) {
        cellSnapshotView = [self snapshotViewAfterScreenUpdates:NO];
    } else {
        CGSize size = CGSizeMake(self.bounds.size.width + 20, self.bounds.size.height + 20);
        UIGraphicsBeginImageContextWithOptions(size, self.opaque, 0);
        [self.layer renderInContext:UIGraphicsGetCurrentContext()];
        UIImage * cellSnapshotImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        cellSnapshotView = [[UIImageView alloc]initWithImage:cellSnapshotImage];
    }
    
    snapshotView.frame = CGRectMake(0, 0, cellSnapshotView.frame.size.width, cellSnapshotView.frame.size.height);
    cellSnapshotView.frame = CGRectMake(0, 0, cellSnapshotView.frame.size.width, cellSnapshotView.frame.size.height);
    
    [snapshotView addSubview:cellSnapshotView];
    return snapshotView;
}
@end
