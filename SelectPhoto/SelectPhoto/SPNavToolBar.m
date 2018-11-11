//
//  SPNavToolBar.m
//  SelectPhoto
//
//  Created by qrh on 2018/11/8.
//  Copyright © 2018年 applee. All rights reserved.
//

#import "SPNavToolBar.h"

@interface SPNavToolBar()
@property (nonatomic, strong) UIButton *leftBtn;
@property (nonatomic, strong) UIButton *middleBtn;
@property (nonatomic, strong) UIButton *rightBtn;
@end

@implementation SPNavToolBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self configSubViews];
    }
    return self;
}

#pragma mark - event
-(void)buttonAction:(UIButton *)sender{
    if(self.toolBarClickBlock){
        self.toolBarClickBlock(sender.tag);
    }
}

#pragma mark - subviews
-(void)configSubViews{
    [self addSubview:self.leftBtn];
    [self addSubview:self.middleBtn];
    [self addSubview:self.rightBtn];
    [_leftBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.mas_equalTo(10);
        make.bottom.mas_equalTo(-10);
        make.size.mas_equalTo(CGSizeMake(40, 24));
    }];
    [_middleBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.bottom.mas_equalTo(-10);
        make.size.mas_equalTo(CGSizeMake(120, 24));
    }];
    [_rightBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.mas_equalTo(-10);
        make.bottom.mas_equalTo(-10);
        make.size.mas_equalTo(CGSizeMake(40, 24));
    }];
}

-(UIButton *)leftBtn{
    if(!_leftBtn){
        _leftBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_leftBtn setTitle:@"取消" forState:(UIControlStateNormal)];
        [_leftBtn setTitleColor:[UIColor blackColor] forState:(UIControlStateNormal)];
        [_leftBtn setTitleColor:[[UIColor blackColor] colorWithAlphaComponent:0.5] forState:(UIControlStateHighlighted)];
        _leftBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _leftBtn.tag = 0;
        [_leftBtn addTarget:self action:@selector(buttonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _leftBtn;
}
-(UIButton *)middleBtn{
    if(!_middleBtn){
        _middleBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_middleBtn setTitle:@"选择图片" forState:(UIControlStateNormal)];
        [_middleBtn setTitleColor:[UIColor blackColor] forState:(UIControlStateNormal)];
        _middleBtn.titleLabel.font = [UIFont boldSystemFontOfSize:16];
        _middleBtn.tag = 1;
        [_middleBtn addTarget:self action:@selector(buttonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _middleBtn;
}
-(UIButton *)rightBtn{
    if(!_rightBtn){
        _rightBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_rightBtn setTitle:@"继续" forState:(UIControlStateNormal)];
        [_rightBtn setTitleColor:[UIColor redColor] forState:(UIControlStateNormal)];
        [_rightBtn setTitleColor:[[UIColor redColor] colorWithAlphaComponent:0.5] forState:(UIControlStateHighlighted)];
        _rightBtn.titleLabel.font = [UIFont systemFontOfSize:14];
        _rightBtn.tag = 2;
        [_rightBtn addTarget:self action:@selector(buttonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _rightBtn;
}
@end
