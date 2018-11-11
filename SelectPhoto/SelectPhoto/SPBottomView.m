//
//  SPBottomView.m
//  SelectPhoto
//
//  Created by qrh on 2018/11/9.
//  Copyright © 2018年 applee. All rights reserved.
//

#import "SPBottomView.h"
#import "UIView+SPLayout.h"

@interface SPBottomView()
@property (nonatomic, strong) UIButton *leftBtn;
@property (nonatomic, strong) UIButton *rightBtn;
@property (nonatomic, strong) UILabel *lineLab;

@property (nonatomic, strong) UIButton *oldSeletBtn;

@end

@implementation SPBottomView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        self.backgroundColor = [UIColor whiteColor];
        [self configSubViews];
        _selectIndex = 0;
    }
    return self;
}

-(void)setSelectIndex:(NSInteger)selectIndex{
    _selectIndex = selectIndex;
    
    _oldSeletBtn.selected = NO;
    if(selectIndex == 0){
        _leftBtn.selected = YES;
        _oldSeletBtn = _leftBtn;
    }else{
        _rightBtn.selected = YES;
        _oldSeletBtn = _rightBtn;
    }
    [UIView animateWithDuration:0.3 animations:^{
        self.lineLab.sp_centerX = self.oldSeletBtn.sp_centerX;
    }];
}

#pragma mark - event
-(void)buttonAction:(UIButton *)sender{
    if(sender.selected){
        return;
    }
    self.selectIndex = sender.tag;
    if(self.selectBlock){
        self.selectBlock(sender.tag);
    }
}

#pragma mark - subviews
-(void)configSubViews{
    [self addSubview:self.leftBtn];
    [self addSubview:self.rightBtn];
    [self addSubview:self.lineLab];
    NSArray *array = @[_leftBtn,_rightBtn];
    [array mas_distributeViewsAlongAxis:(MASAxisTypeHorizontal) withFixedSpacing:15 leadSpacing:15 tailSpacing:15];
    [array mas_makeConstraints:^(MASConstraintMaker *make) {
        make.height.equalTo(self);
        make.top.equalTo(self);
    }];
    [_lineLab mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.leftBtn);
        make.bottom.equalTo(self).offset(-2);
        make.size.mas_equalTo(CGSizeMake(50, 3));
    }];
    self.oldSeletBtn = self.leftBtn;
}

-(UIButton *)leftBtn{
    if(!_leftBtn){
        _leftBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_leftBtn setTitle:@"相册" forState:(UIControlStateNormal)];
        [_leftBtn setTitleColor:[UIColor grayColor] forState:(UIControlStateNormal)];
        [_leftBtn setTitleColor:[UIColor blackColor] forState:(UIControlStateHighlighted)];
        [_leftBtn setTitleColor:[UIColor blackColor] forState:(UIControlStateSelected)];
        _leftBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _leftBtn.tag = 0;
        [_leftBtn addTarget:self action:@selector(buttonAction:) forControlEvents:(UIControlEventTouchUpInside)];
        _leftBtn.selected = YES;
    }
    return _leftBtn;
}

-(UIButton *)rightBtn{
    if(!_rightBtn){
        _rightBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_rightBtn setTitle:@"拍照" forState:(UIControlStateNormal)];
        [_rightBtn setTitleColor:[UIColor grayColor] forState:(UIControlStateNormal)];
        [_rightBtn setTitleColor:[UIColor blackColor] forState:(UIControlStateHighlighted)];
        [_rightBtn setTitleColor:[UIColor blackColor] forState:(UIControlStateSelected)];
        _rightBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
        _rightBtn.tag = 1;
        [_rightBtn addTarget:self action:@selector(buttonAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _rightBtn;
}

-(UILabel *)lineLab{
    if(!_lineLab){
        _lineLab = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 50, 3)];
        _lineLab.backgroundColor = [UIColor blackColor];
    }
    return _lineLab;
}




@end
