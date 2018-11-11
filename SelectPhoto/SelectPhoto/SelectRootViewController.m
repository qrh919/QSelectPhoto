#import "SelectRootViewController.h"
#import "SPImagePickerController.h"
#import "SelectSuccessViewController.h"
#import "SPAssetModel.h"
#import "SPCropView.h"
#import "UIView+SPLayout.h"
#import "SPNavToolBar.h"
#import "SPImageCropManager.h"
#import "SPBottomView.h"


#define kNavHeigth ([SPCommonTools sp_statusBarHeight] + 44)

@interface SelectRootViewController ()<SPImagePickerControllerDelegate,UIImagePickerControllerDelegate,UINavigationControllerDelegate>
@property (nonatomic, strong) SPImagePickerController *pickerVc;
@property (nonatomic, copy) NSString  *isPullAndDownStr;//是上滑还是下滑 1 上滑 2 下滑
@property (nonatomic, strong) UIView *topView;
@property (nonatomic, strong) SPNavToolBar *toolBar;
@property (nonatomic, strong) SPBottomView *bottomView;
@property (nonatomic, strong) NSMutableArray *photos;//选择后的图片对象组
@property (nonatomic, strong) NSMutableArray *cropViews;//可进行裁剪视的图组
@property (nonatomic, strong) NSMutableArray *images;//裁剪好的图片组
@property (strong, nonatomic) CLLocation *location;
@end

@implementation SelectRootViewController

-(void)dealloc{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    self.photos = [NSMutableArray array];
    self.cropViews = [NSMutableArray array];
    self.images = [NSMutableArray array];
    [self initializePageSubviews];
    if(_number == 0){
        _number = 9;
    }
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(headerHeightAnimation:) name:@"isUpAndDown" object:nil];
    //重新布局
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(resetSelectLayout:) name:@"resetSelectLayout" object:nil];
    self.isPullAndDownStr = @"2";//判断页面是上拉还是下拉，刚进入页面默认下拉
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = YES;
}

-(void)viewWillDisappear:(BOOL)animated{
    [super viewWillDisappear:animated];
    
}
#pragma mark - notification
-(void)headerHeightAnimation:(NSNotification*)infoNotification{
    NSString *str = [infoNotification object];
    if ([self.isPullAndDownStr isEqualToString:str]) {
        return;
    }
    if ([str isEqualToString:@"1"]) {//上拉
        [UIView animateWithDuration:0.3 animations:^{
            self.topView.frame = CGRectMake(0, -self.view.sp_width, self.view.sp_width, self.view.sp_width + kNavHeigth);
        }];
        
    }else if([str isEqualToString:@"2"]){//下拉
        [UIView animateWithDuration:0.3 animations:^{
            self.topView.frame = CGRectMake(0, 0, self.view.sp_width, self.view.sp_width + kNavHeigth);
        }];
    }
    self.isPullAndDownStr =  str;
}

-(void)resetSelectLayout:(NSNotification*)infoNotification{
    for (SPCropView *view in self.cropViews) {
        if(view.model.mySelect){
            [self.topView bringSubviewToFront:view];
            break;
        }
    }
}

#pragma mark - TZImagePickerControllerDelegate
/// 用户点击了取消
- (void)sp_imagePickerControllerDidCancel:(SPImagePickerController *)picker {
     NSLog(@"cancel");
}

- (void)imagePickerController:(SPImagePickerController *)picker didFinishPickingPhotos:(NSArray<UIImage *> *)photos sourceAssets:(NSArray *)assets isSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto infos:(NSArray<NSDictionary *> *)infos {
}
- (void)imagePickerController:(SPImagePickerController *)picker didFinishPickingVideo:(UIImage *)coverImage sourceAssets:(PHAsset *)asset {
}
// 决定相册显示与否
- (BOOL)isAlbumCanSelect:(NSString *)albumName result:(PHFetchResult *)result {
    return YES;
}
// 决定asset显示与否
- (BOOL)isAssetCanSelect:(PHAsset *)asset {
    return YES;
}
/// 打印图片名字
- (void)printAssetsName:(NSArray *)assets {
    NSString *fileName;
    for (PHAsset *asset in assets) {
        fileName = [asset valueForKey:@"filename"];
        NSLog(@"图片名字:%@",fileName);
    }
}
#pragma mark - 拍照
- (void)takePhoto {
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied) {
        // 无相机权限 做一个友好的提示
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"无法使用相机" message:@"请在iPhone的""设置-隐私-相机""中允许访问相机" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
        [alert show];
    } else if (authStatus == AVAuthorizationStatusNotDetermined) {
        // fix issue 466, 防止用户首次拍照拒绝授权时相机页黑屏
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            if (granted) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    [self takePhoto];
                });
            }
        }];
        // 拍照之前还需要检查相册权限
    } else if ([PHPhotoLibrary authorizationStatus] == 2) { // 已被拒绝，没有相册权限，将无法保存拍的照片
        UIAlertView * alert = [[UIAlertView alloc]initWithTitle:@"无法访问相册" message:@"请在iPhone的""设置-隐私-相册""中允许访问相册" delegate:self cancelButtonTitle:@"取消" otherButtonTitles:@"设置", nil];
        [alert show];
    } else if ([PHPhotoLibrary authorizationStatus] == 0) { // 未请求过相册权限
        [[SPImageManager manager] requestAuthorizationWithCompletion:^{
            [self takePhoto];
        }];
    } else {
        [self pushImagePickerController];
    }
}

// 调用相机
- (void)pushImagePickerController {
    // 提前定位
    __weak typeof(self) weakSelf = self;
    [[SPLocationManager manager] startLocationWithSuccessBlock:^(NSArray<CLLocation *> *locations) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.location = [locations firstObject];
    } failureBlock:^(NSError *error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        strongSelf.location = nil;
    }];
    
    if ([UIImagePickerController isSourceTypeAvailable: UIImagePickerControllerSourceTypeCamera]) {
        UIImagePickerController *imagePickerController = [[UIImagePickerController alloc] init];
        imagePickerController.delegate = self;
        imagePickerController.allowsEditing = YES;
        imagePickerController.sourceType = UIImagePickerControllerSourceTypeCamera;
        [self presentViewController:imagePickerController animated:YES completion:^{}];
    } else {
        NSLog(@"模拟器中无法打开照相机,请在真机中使用");
    }
}

-(void)imagePickerControllerDidCancel:(UIImagePickerController *)picker{
    _bottomView.selectIndex = 0;
    [picker dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(UIImagePickerController*)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    _bottomView.selectIndex = 0;
    [picker dismissViewControllerAnimated:NO completion:nil];
    NSString *type = [info objectForKey:UIImagePickerControllerMediaType];
    [_pickerVc showProgressHUD];
    if ([type isEqualToString:@"public.image"]) {
        UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
        //拍照完成后跳转到完成界面
        SelectSuccessViewController *nextVC = [[SelectSuccessViewController alloc] init];
        nextVC.images = @[image].mutableCopy;
        [self.navigationController pushViewController:nextVC animated:YES];
        /*
         
        //保存图片，获取到asset
        __weak typeof(self) weakSelf = self;
        [[TZImageManager manager] savePhotoWithImage:image location:self.location completion:^(PHAsset *asset, NSError *error){
            [weakSelf.pickerVc hideProgressHUD];
            if (error) {
                NSLog(@"图片保存失败 %@",error);
            } else {
                TZAssetModel *assetModel = [[TZImageManager manager] createModelWithAsset:asset];
                TZImagePickerController *imagePicker = [[TZImagePickerController alloc] initCropTypeWithAsset:assetModel.asset photo:image completion:^(UIImage *cropImage, id asset) {
                }];
                imagePicker.allowPickingImage = YES;
                //imagePicker.cropRect = CGRectMake(0, 0, 100, 100);
                [self presentViewController:imagePicker animated:YES completion:nil];
            }
        }];
         */
    }
}

#pragma mark - event
///顶部事件
-(void)navAction:(NSInteger)index{
    if(index == 0){//取消
        [self dismissViewControllerAnimated:YES completion:nil];
    }else if(index == 1){//选择相册
        
    }else{//进行裁剪
        [self.images removeAllObjects];
        if(self.cropViews.count > 0){
            [_pickerVc showProgressHUD];
            for (SPCropView *view in self.cropViews) {
                UIImage *cropedImage = [SPImageCropManager cropImageView:view.previewView.imageView toRect:view.cropRect zoomScale:view.previewView.scrollView.zoomScale containerView:view.previewView scale:view.scale];
                [self.images addObject:cropedImage];
            }
            [_pickerVc hideProgressHUD];
            SelectSuccessViewController *nextVC = [[SelectSuccessViewController alloc] init];
            nextVC.images = self.images;
            [self.navigationController pushViewController:nextVC animated:YES];
        }
    }
}
///底部事件
-(void)bottomAction:(NSInteger)index{
    if(index == 0){//相册
        
    }else{//拍照
        if([UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
            [self takePhoto];
        }
    }
}

/**
 重新布局topView
 @param isAdd 是否为添加
 @param model 当前添加、删除的对象
 */
-(void)resetTopViewWithFlag:(BOOL)isAdd model:(SPAssetModel *)model{
    if(isAdd){
        [self.photos addObject:model];
        CGRect rect = CGRectMake(0, kNavHeigth, self.topView.sp_width, self.topView.sp_width);
        SPCropView *view = [[SPCropView alloc] initWithFrame:rect];
        view.model = model;
        view.allowCrop = YES;
        [self.topView addSubview:view];
        [self.cropViews addObject:view];
    }else{
        [self.photos removeObject:model];
        for (UIView *view in self.topView.subviews) {
            if([view isKindOfClass:[SPCropView class]]){
                SPCropView *indexView = (SPCropView *)view;
                if([indexView.model.asset.localIdentifier isEqualToString:model.asset.localIdentifier]){
                    [view removeFromSuperview];
                    [self.cropViews removeObject:view];
                    break;
                }
            }
        }
    }
}

#pragma mark - init
-(void)initializePageSubviews{
    //添加头部
    [self.view addSubview:self.topView];
    [_topView addSubview:self.toolBar];
    [_toolBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.right.left.equalTo(self.topView);
        make.height.mas_equalTo(kNavHeigth);
    }];
    
    //添加图片选择子控制器
    [self addChildViewController:self.pickerVc];
    [self.view addSubview:_pickerVc.view];
    [_pickerVc.view mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.topView.mas_bottom);
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view).offset(-44 - ([SPCommonTools sp_isIPhoneX]?34:0));
    }];
    [self.view insertSubview:_topView aboveSubview:_pickerVc.view];
    
    //添加底部
    [self.view addSubview:self.bottomView];
    [_bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.equalTo(self.view);
        make.bottom.equalTo(self.view).offset([SPCommonTools sp_isIPhoneX]?34:0);
        make.height.equalTo(@44);
    }];
}

-(SPImagePickerController *)pickerVc{
    if(!_pickerVc){
        _pickerVc = [[SPImagePickerController alloc] initWithMaxImagesCount:_number columnNumber:4 delegate:self pushPhotoPickerVc:YES];
        _pickerVc.showSelectedIndex = YES;
        _pickerVc.allowPickingVideo = NO;
        _pickerVc.sortAscendingByModificationDate = NO;//按最新排序
        _pickerVc.cropRect = CGRectMake(0, 0, self.view.sp_width, self.view.sp_width);
        [_pickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
            
        }];
        //选择回调
        __weak typeof(self) weakSelf = self;
        [_pickerVc setGetCurrentChangeAsset:^(BOOL isAdd, SPAssetModel *model) {
            [weakSelf resetTopViewWithFlag:isAdd model:model];
        }];
    }
    return _pickerVc;
}

-(UIView *)topView{
    if(!_topView){
        _topView = [[UIView alloc] initWithFrame:CGRectMake(0, 0, self.view.sp_width, self.view.sp_width + kNavHeigth)];
        _topView.backgroundColor = [UIColor whiteColor];
        _topView.layer.shadowOffset = CGSizeMake(0, 4);
        _topView.layer.shadowColor = [[UIColor blackColor] colorWithAlphaComponent:0.3].CGColor;
        _topView.layer.shadowOpacity = 1;
    }
    return _topView;
}

-(SPNavToolBar *)toolBar{
    if(!_toolBar){
        _toolBar = [[SPNavToolBar alloc] initWithFrame:CGRectZero];
        __weak typeof(self) weakSelf = self;
        [_toolBar setToolBarClickBlock:^(NSInteger index) {
            [weakSelf navAction:index];
        }];
    }
    return _toolBar;
}

- (SPBottomView *)bottomView{
    if(!_bottomView){
        _bottomView = [[SPBottomView alloc] initWithFrame:CGRectZero];
        __weak typeof(self) weakSelf = self;
        [_bottomView setSelectBlock:^(NSInteger index) {
            [weakSelf bottomAction:index];
        }];
    }
    return _bottomView;
}
@end
