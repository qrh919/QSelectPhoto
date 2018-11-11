#import "ViewController.h"
#import "SelectRootViewController.h"

@interface ViewController ()
@property (nonatomic, strong) UIButton *selectBtn;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializePageSubviews];
}

-(void)selectAction:(UIButton *)sender{
    SelectRootViewController *nextVC = [[SelectRootViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:nextVC];
    [self presentViewController:nav animated:YES completion:nil];
}

#pragma mark - page subviews
- (void)initializePageSubviews{
    self.navigationItem.title = @"Test";
    [self.view addSubview:self.selectBtn];
    [_selectBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.center.equalTo(self.view);
        make.size.mas_equalTo(CGSizeMake(100, 100));
    }];
}

-(UIButton *)selectBtn{
    if(!_selectBtn){
        _selectBtn = [UIButton buttonWithType:(UIButtonTypeCustom)];
        [_selectBtn setTitle:@"选择" forState:(UIControlStateNormal)];
        [_selectBtn setTitleColor:[UIColor blueColor] forState:(UIControlStateNormal)];
        [_selectBtn addTarget:self action:@selector(selectAction:) forControlEvents:(UIControlEventTouchUpInside)];
    }
    return _selectBtn;
}
@end
