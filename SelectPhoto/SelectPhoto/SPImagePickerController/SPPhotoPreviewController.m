//
//  TZPhotoPreviewController.m
//  TZImagePickerController
//
//  Created by 谭真 on 15/12/24.
//  Copyright © 2015年 谭真. All rights reserved.
//

#import "SPPhotoPreviewController.h"
#import "SPPhotoPreviewCell.h"
#import "SPAssetModel.h"
#import "UIView+SPLayout.h"
#import "SPImagePickerController.h"
#import "SPImageManager.h"
#import "SPImageCropManager.h"

@interface SPPhotoPreviewController ()<UICollectionViewDataSource,UICollectionViewDelegate,UIScrollViewDelegate> {
    UICollectionView *_collectionView;
    UICollectionViewFlowLayout *_layout;
    NSArray *_photosTemp;
    NSArray *_assetsTemp;
    
    UIView *_naviBar;
    UIButton *_backButton;
    UIButton *_selectButton;
    UILabel *_indexLabel;
    
    UIView *_toolBar;
    UIButton *_doneButton;
    UIImageView *_numberImageView;
    UILabel *_numberLabel;
    UIButton *_originalPhotoButton;
    UILabel *_originalPhotoLabel;
    
    CGFloat _offsetItemCount;
    
    BOOL _didSetIsSelectOriginalPhoto;
}
@property (nonatomic, assign) BOOL isHideNaviBar;
@property (nonatomic, strong) UIView *cropBgView;
@property (nonatomic, strong) UIView *cropView;

@property (nonatomic, assign) double progress;
@property (strong, nonatomic) UIAlertController *alertView;
@end

@implementation SPPhotoPreviewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [SPImageManager manager].shouldFixOrientation = YES;
    SPImagePickerController *_tzImagePickerVc = (SPImagePickerController *)self.navigationController;
    if (!_didSetIsSelectOriginalPhoto) {
        _isSelectOriginalPhoto = _tzImagePickerVc.isSelectOriginalPhoto;
    }
    if (!self.models.count) {
        self.models = [NSMutableArray arrayWithArray:_tzImagePickerVc.selectedModels];
        _assetsTemp = [NSMutableArray arrayWithArray:_tzImagePickerVc.selectedAssets];
    }
    [self configCollectionView];
    [self configCustomNaviBar];
    [self configBottomToolBar];
    self.view.clipsToBounds = YES;
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeStatusBarOrientationNotification:) name:UIApplicationDidChangeStatusBarOrientationNotification object:nil];
}

- (void)setIsSelectOriginalPhoto:(BOOL)isSelectOriginalPhoto {
    _isSelectOriginalPhoto = isSelectOriginalPhoto;
    _didSetIsSelectOriginalPhoto = YES;
}

- (void)setPhotos:(NSMutableArray *)photos {
    _photos = photos;
    _photosTemp = [NSArray arrayWithArray:photos];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
    [UIApplication sharedApplication].statusBarHidden = YES;
    if (_currentIndex) {
        [_collectionView setContentOffset:CGPointMake((self.view.sp_width + 20) * self.currentIndex, 0) animated:NO];
    }
    [self refreshNaviBarAndBottomBarState];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
    SPImagePickerController *tzImagePickerVc = (SPImagePickerController *)self.navigationController;
    if (tzImagePickerVc.needShowStatusBar) {
        [UIApplication sharedApplication].statusBarHidden = NO;
    }
    [SPImageManager manager].shouldFixOrientation = NO;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)configCustomNaviBar {
    SPImagePickerController *tzImagePickerVc = (SPImagePickerController *)self.navigationController;
    
    _naviBar = [[UIView alloc] initWithFrame:CGRectZero];
    _naviBar.backgroundColor = [UIColor colorWithRed:(34/255.0) green:(34/255.0)  blue:(34/255.0) alpha:0.7];
    
    _backButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_backButton setImage:[UIImage sp_imageNamedFromMyBundle:@"navi_back"] forState:UIControlStateNormal];
    [_backButton setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    [_backButton addTarget:self action:@selector(backButtonClick) forControlEvents:UIControlEventTouchUpInside];
    
    _selectButton = [[UIButton alloc] initWithFrame:CGRectZero];
    [_selectButton setImage:tzImagePickerVc.photoDefImage forState:UIControlStateNormal];
    [_selectButton setImage:tzImagePickerVc.photoSelImage forState:UIControlStateSelected];
    _selectButton.imageView.clipsToBounds = YES;
    _selectButton.imageEdgeInsets = UIEdgeInsetsMake(10, 0, 10, 0);
    _selectButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [_selectButton addTarget:self action:@selector(select:) forControlEvents:UIControlEventTouchUpInside];
    _selectButton.hidden = !tzImagePickerVc.showSelectBtn;
    
    _indexLabel = [[UILabel alloc] init];
    _indexLabel.font = [UIFont systemFontOfSize:14];
    _indexLabel.textColor = [UIColor whiteColor];
    _indexLabel.textAlignment = NSTextAlignmentCenter;
    
    [_naviBar addSubview:_selectButton];
    [_naviBar addSubview:_indexLabel];
    [_naviBar addSubview:_backButton];
    [self.view addSubview:_naviBar];
}

- (void)configBottomToolBar {
    _toolBar = [[UIView alloc] initWithFrame:CGRectZero];
    static CGFloat rgb = 34 / 255.0;
    _toolBar.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:0.7];
    
    SPImagePickerController *_tzImagePickerVc = (SPImagePickerController *)self.navigationController;
    if (_tzImagePickerVc.allowPickingOriginalPhoto) {
        _originalPhotoButton = [UIButton buttonWithType:UIButtonTypeCustom];
        _originalPhotoButton.imageEdgeInsets = UIEdgeInsetsMake(0, [SPCommonTools sp_isRightToLeftLayout] ? 10 : -10, 0, 0);
        _originalPhotoButton.backgroundColor = [UIColor clearColor];
        [_originalPhotoButton addTarget:self action:@selector(originalPhotoButtonClick) forControlEvents:UIControlEventTouchUpInside];
        _originalPhotoButton.titleLabel.font = [UIFont systemFontOfSize:13];
        [_originalPhotoButton setTitle:_tzImagePickerVc.fullImageBtnTitleStr forState:UIControlStateNormal];
        [_originalPhotoButton setTitle:_tzImagePickerVc.fullImageBtnTitleStr forState:UIControlStateSelected];
        [_originalPhotoButton setTitleColor:[UIColor lightGrayColor] forState:UIControlStateNormal];
        [_originalPhotoButton setTitleColor:[UIColor whiteColor] forState:UIControlStateSelected];
        [_originalPhotoButton setImage:_tzImagePickerVc.photoPreviewOriginDefImage forState:UIControlStateNormal];
        [_originalPhotoButton setImage:_tzImagePickerVc.photoOriginSelImage forState:UIControlStateSelected];
        
        _originalPhotoLabel = [[UILabel alloc] init];
        _originalPhotoLabel.textAlignment = NSTextAlignmentLeft;
        _originalPhotoLabel.font = [UIFont systemFontOfSize:13];
        _originalPhotoLabel.textColor = [UIColor whiteColor];
        _originalPhotoLabel.backgroundColor = [UIColor clearColor];
        if (_isSelectOriginalPhoto) [self showPhotoBytes];
    }
    
    _doneButton = [UIButton buttonWithType:UIButtonTypeCustom];
    _doneButton.titleLabel.font = [UIFont systemFontOfSize:16];
    [_doneButton addTarget:self action:@selector(doneButtonClick) forControlEvents:UIControlEventTouchUpInside];
    [_doneButton setTitle:_tzImagePickerVc.doneBtnTitleStr forState:UIControlStateNormal];
    [_doneButton setTitleColor:_tzImagePickerVc.oKButtonTitleColorNormal forState:UIControlStateNormal];
    
    _numberImageView = [[UIImageView alloc] initWithImage:_tzImagePickerVc.photoNumberIconImage];
    _numberImageView.backgroundColor = [UIColor clearColor];
    _numberImageView.clipsToBounds = YES;
    _numberImageView.contentMode = UIViewContentModeScaleAspectFit;
    _numberImageView.hidden = _tzImagePickerVc.selectedModels.count <= 0;
    
    _numberLabel = [[UILabel alloc] init];
    _numberLabel.font = [UIFont systemFontOfSize:15];
    _numberLabel.textColor = [UIColor whiteColor];
    _numberLabel.textAlignment = NSTextAlignmentCenter;
    _numberLabel.text = [NSString stringWithFormat:@"%zd",_tzImagePickerVc.selectedModels.count];
    _numberLabel.hidden = _tzImagePickerVc.selectedModels.count <= 0;
    _numberLabel.backgroundColor = [UIColor clearColor];
    
    [_originalPhotoButton addSubview:_originalPhotoLabel];
    [_toolBar addSubview:_doneButton];
    [_toolBar addSubview:_originalPhotoButton];
    [_toolBar addSubview:_numberImageView];
    [_toolBar addSubview:_numberLabel];
    [self.view addSubview:_toolBar];
    
    if (_tzImagePickerVc.photoPreviewPageUIConfigBlock) {
        _tzImagePickerVc.photoPreviewPageUIConfigBlock(_collectionView, _naviBar, _backButton, _selectButton, _indexLabel, _toolBar, _originalPhotoButton, _originalPhotoLabel, _doneButton, _numberImageView, _numberLabel);
    }
}

- (void)configCollectionView {
    _layout = [[UICollectionViewFlowLayout alloc] init];
    _layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:_layout];
    _collectionView.backgroundColor = [UIColor blackColor];
    _collectionView.dataSource = self;
    _collectionView.delegate = self;
    _collectionView.pagingEnabled = YES;
    _collectionView.scrollsToTop = NO;
    _collectionView.showsHorizontalScrollIndicator = NO;
    _collectionView.contentOffset = CGPointMake(0, 0);
    _collectionView.contentSize = CGSizeMake(self.models.count * (self.view.sp_width + 20), 0);
    [self.view addSubview:_collectionView];
    [_collectionView registerClass:[SPPhotoPreviewCell class] forCellWithReuseIdentifier:@"TZPhotoPreviewCell"];
    [_collectionView registerClass:[SPVideoPreviewCell class] forCellWithReuseIdentifier:@"TZVideoPreviewCell"];
    [_collectionView registerClass:[SPGifPreviewCell class] forCellWithReuseIdentifier:@"TZGifPreviewCell"];
}

- (void)configCropView {
    SPImagePickerController *_tzImagePickerVc = (SPImagePickerController *)self.navigationController;
    if (_tzImagePickerVc.maxImagesCount <= 1 && _tzImagePickerVc.allowCrop && _tzImagePickerVc.allowPickingImage) {
        [_cropView removeFromSuperview];
        [_cropBgView removeFromSuperview];
        
        _cropBgView = [UIView new];
        _cropBgView.userInteractionEnabled = NO;
        _cropBgView.frame = self.view.bounds;
        _cropBgView.backgroundColor = [UIColor clearColor];
        [self.view addSubview:_cropBgView];
        [SPImageCropManager overlayClippingWithView:_cropBgView cropRect:_tzImagePickerVc.cropRect containerView:self.view needCircleCrop:_tzImagePickerVc.needCircleCrop];
        
        _cropView = [UIView new];
        _cropView.userInteractionEnabled = NO;
        _cropView.frame = _tzImagePickerVc.cropRect;
        _cropView.backgroundColor = [UIColor clearColor];
        _cropView.layer.borderColor = [UIColor whiteColor].CGColor;
        _cropView.layer.borderWidth = 1.0;
        if (_tzImagePickerVc.needCircleCrop) {
            _cropView.layer.cornerRadius = _tzImagePickerVc.cropRect.size.width / 2;
            _cropView.clipsToBounds = YES;
        }
        [self.view addSubview:_cropView];
        if (_tzImagePickerVc.cropViewSettingBlock) {
            _tzImagePickerVc.cropViewSettingBlock(_cropView);
        }
        
        [self.view bringSubviewToFront:_naviBar];
        [self.view bringSubviewToFront:_toolBar];
    }
}

#pragma mark - Layout

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    SPImagePickerController *_tzImagePickerVc = (SPImagePickerController *)self.navigationController;
    
    CGFloat statusBarHeight = [SPCommonTools sp_statusBarHeight];
    CGFloat statusBarHeightInterval = statusBarHeight - 20;
    CGFloat naviBarHeight = statusBarHeight + _tzImagePickerVc.navigationBar.sp_height;
    _naviBar.frame = CGRectMake(0, 0, self.view.sp_width, naviBarHeight);
    _backButton.frame = CGRectMake(10, 10 + statusBarHeightInterval, 44, 44);
    _selectButton.frame = CGRectMake(self.view.sp_width - 56, 10 + statusBarHeightInterval, 44, 44);
    _indexLabel.frame = _selectButton.frame;
    
    _layout.itemSize = CGSizeMake(self.view.sp_width + 20, self.view.sp_height);
    _layout.minimumInteritemSpacing = 0;
    _layout.minimumLineSpacing = 0;
    _collectionView.frame = CGRectMake(-10, 0, self.view.sp_width + 20, self.view.sp_height);
    [_collectionView setCollectionViewLayout:_layout];
    if (_offsetItemCount > 0) {
        CGFloat offsetX = _offsetItemCount * _layout.itemSize.width;
        [_collectionView setContentOffset:CGPointMake(offsetX, 0)];
    }
    if (_tzImagePickerVc.allowCrop) {
        [_collectionView reloadData];
    }
    
    CGFloat toolBarHeight = [SPCommonTools sp_isIPhoneX] ? 44 + (83 - 49) : 44;
    CGFloat toolBarTop = self.view.sp_height - toolBarHeight;
    _toolBar.frame = CGRectMake(0, toolBarTop, self.view.sp_width, toolBarHeight);
    if (_tzImagePickerVc.allowPickingOriginalPhoto) {
        CGFloat fullImageWidth = [_tzImagePickerVc.fullImageBtnTitleStr boundingRectWithSize:CGSizeMake(CGFLOAT_MAX, CGFLOAT_MAX) options:NSStringDrawingUsesFontLeading attributes:@{NSFontAttributeName:[UIFont systemFontOfSize:13]} context:nil].size.width;
        _originalPhotoButton.frame = CGRectMake(0, 0, fullImageWidth + 56, 44);
        _originalPhotoLabel.frame = CGRectMake(fullImageWidth + 42, 0, 80, 44);
    }
    [_doneButton sizeToFit];
    _doneButton.frame = CGRectMake(self.view.sp_width - _doneButton.sp_width - 12, 0, _doneButton.sp_width, 44);
    _numberImageView.frame = CGRectMake(_doneButton.sp_left - 24 - 5, 10, 24, 24);
    _numberLabel.frame = _numberImageView.frame;
    
    [self configCropView];
    
    if (_tzImagePickerVc.photoPreviewPageDidLayoutSubviewsBlock) {
        _tzImagePickerVc.photoPreviewPageDidLayoutSubviewsBlock(_collectionView, _naviBar, _backButton, _selectButton, _indexLabel, _toolBar, _originalPhotoButton, _originalPhotoLabel, _doneButton, _numberImageView, _numberLabel);
    }
}

#pragma mark - Notification

- (void)didChangeStatusBarOrientationNotification:(NSNotification *)noti {
    _offsetItemCount = _collectionView.contentOffset.x / _layout.itemSize.width;
}

#pragma mark - Click Event

- (void)select:(UIButton *)selectButton {
    SPImagePickerController *_tzImagePickerVc = (SPImagePickerController *)self.navigationController;
    SPAssetModel *model = _models[self.currentIndex];
    if (!selectButton.isSelected) {
        // 1. select:check if over the maxImagesCount / 选择照片,检查是否超过了最大个数的限制
        if (_tzImagePickerVc.selectedModels.count >= _tzImagePickerVc.maxImagesCount) {
            NSString *title = [NSString stringWithFormat:[NSBundle sp_localizedStringForKey:@"Select a maximum of %zd photos"], _tzImagePickerVc.maxImagesCount];
            [_tzImagePickerVc showAlertWithTitle:title];
            return;
            // 2. if not over the maxImagesCount / 如果没有超过最大个数限制
        } else {
            [_tzImagePickerVc addSelectedModel:model];
            if (self.photos) {
                [_tzImagePickerVc.selectedAssets addObject:_assetsTemp[self.currentIndex]];
                [self.photos addObject:_photosTemp[self.currentIndex]];
            }
            if (model.type == SPAssetModelMediaTypeVideo && !_tzImagePickerVc.allowPickingMultipleVideo) {
                [_tzImagePickerVc showAlertWithTitle:[NSBundle sp_localizedStringForKey:@"Select the video when in multi state, we will handle the video as a photo"]];
            }
        }
    } else {
        NSArray *selectedModels = [NSArray arrayWithArray:_tzImagePickerVc.selectedModels];
        for (SPAssetModel *model_item in selectedModels) {
            if ([model.asset.localIdentifier isEqualToString:model_item.asset.localIdentifier]) {
                // 1.6.7版本更新:防止有多个一样的model,一次性被移除了
                NSArray *selectedModelsTmp = [NSArray arrayWithArray:_tzImagePickerVc.selectedModels];
                for (NSInteger i = 0; i < selectedModelsTmp.count; i++) {
                    SPAssetModel *model = selectedModelsTmp[i];
                    if ([model isEqual:model_item]) {
                        [_tzImagePickerVc removeSelectedModel:model];
                        // [_tzImagePickerVc.selectedModels removeObjectAtIndex:i];
                        break;
                    }
                }
                if (self.photos) {
                    // 1.6.7版本更新:防止有多个一样的asset,一次性被移除了
                    NSArray *selectedAssetsTmp = [NSArray arrayWithArray:_tzImagePickerVc.selectedAssets];
                    for (NSInteger i = 0; i < selectedAssetsTmp.count; i++) {
                        id asset = selectedAssetsTmp[i];
                        if ([asset isEqual:_assetsTemp[self.currentIndex]]) {
                            [_tzImagePickerVc.selectedAssets removeObjectAtIndex:i];
                            break;
                        }
                    }
                    // [_tzImagePickerVc.selectedAssets removeObject:_assetsTemp[self.currentIndex]];
                    [self.photos removeObject:_photosTemp[self.currentIndex]];
                }
                break;
            }
        }
    }
    model.isSelected = !selectButton.isSelected;
    [self refreshNaviBarAndBottomBarState];
    if (model.isSelected) {
        [UIView showOscillatoryAnimationWithLayer:selectButton.imageView.layer type:SPOscillatoryAnimationToBigger];
    }
    [UIView showOscillatoryAnimationWithLayer:_numberImageView.layer type:SPOscillatoryAnimationToSmaller];
}

- (void)backButtonClick {
    if (self.navigationController.childViewControllers.count < 2) {
        [self.navigationController dismissViewControllerAnimated:YES completion:nil];
        if ([self.navigationController isKindOfClass: [SPImagePickerController class]]) {
            SPImagePickerController *nav = (SPImagePickerController *)self.navigationController;
            if (nav.imagePickerControllerDidCancelHandle) {
                nav.imagePickerControllerDidCancelHandle();
            }
        }
        return;
    }
    [self.navigationController popViewControllerAnimated:YES];
    if (self.backButtonClickBlock) {
        self.backButtonClickBlock(_isSelectOriginalPhoto);
    }
}

- (void)doneButtonClick {
    SPImagePickerController *_tzImagePickerVc = (SPImagePickerController *)self.navigationController;
    // 如果图片正在从iCloud同步中,提醒用户
    if (_progress > 0 && _progress < 1 && (_selectButton.isSelected || !_tzImagePickerVc.selectedModels.count )) {
        _alertView = [_tzImagePickerVc showAlertWithTitle:[NSBundle sp_localizedStringForKey:@"Synchronizing photos from iCloud"]];
        return;
    }
    
    // 如果没有选中过照片 点击确定时选中当前预览的照片
    if (_tzImagePickerVc.selectedModels.count == 0 && _tzImagePickerVc.minImagesCount <= 0) {
        SPAssetModel *model = _models[self.currentIndex];
        [_tzImagePickerVc addSelectedModel:model];
    }
    NSIndexPath *indexPath = [NSIndexPath indexPathForItem:self.currentIndex inSection:0];
    SPPhotoPreviewCell *cell = (SPPhotoPreviewCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    if (_tzImagePickerVc.allowCrop && [cell isKindOfClass:[SPPhotoPreviewCell class]]) { // 裁剪状态
        _doneButton.enabled = NO;
        [_tzImagePickerVc showProgressHUD];
        UIImage *cropedImage = [SPImageCropManager cropImageView:cell.previewView.imageView toRect:_tzImagePickerVc.cropRect zoomScale:cell.previewView.scrollView.zoomScale containerView:self.view];
        if (_tzImagePickerVc.needCircleCrop) {
            cropedImage = [SPImageCropManager circularClipImage:cropedImage];
        }
        _doneButton.enabled = YES;
        [_tzImagePickerVc hideProgressHUD];
        if (self.doneButtonClickBlockCropMode) {
            SPAssetModel *model = _models[self.currentIndex];
            self.doneButtonClickBlockCropMode(cropedImage,model.asset);
        }
    } else if (self.doneButtonClickBlock) { // 非裁剪状态
        self.doneButtonClickBlock(_isSelectOriginalPhoto);
    }
    if (self.doneButtonClickBlockWithPreviewType) {
        self.doneButtonClickBlockWithPreviewType(self.photos,_tzImagePickerVc.selectedAssets,self.isSelectOriginalPhoto);
    }
}

- (void)originalPhotoButtonClick {
    _originalPhotoButton.selected = !_originalPhotoButton.isSelected;
    _isSelectOriginalPhoto = _originalPhotoButton.isSelected;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) {
        [self showPhotoBytes];
        if (!_selectButton.isSelected) {
            // 如果当前已选择照片张数 < 最大可选张数 && 最大可选张数大于1，就选中该张图
            SPImagePickerController *_tzImagePickerVc = (SPImagePickerController *)self.navigationController;
            if (_tzImagePickerVc.selectedModels.count < _tzImagePickerVc.maxImagesCount && _tzImagePickerVc.showSelectBtn) {
                [self select:_selectButton];
            }
        }
    }
}

- (void)didTapPreviewCell {
    self.isHideNaviBar = !self.isHideNaviBar;
    _naviBar.hidden = self.isHideNaviBar;
    _toolBar.hidden = self.isHideNaviBar;
}

#pragma mark - UIScrollViewDelegate

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    CGFloat offSetWidth = scrollView.contentOffset.x;
    offSetWidth = offSetWidth +  ((self.view.sp_width + 20) * 0.5);
    
    NSInteger currentIndex = offSetWidth / (self.view.sp_width + 20);
    if (currentIndex < _models.count && _currentIndex != currentIndex) {
        _currentIndex = currentIndex;
        [self refreshNaviBarAndBottomBarState];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"photoPreviewCollectionViewDidScroll" object:nil];
}

#pragma mark - UICollectionViewDataSource && Delegate

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _models.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SPImagePickerController *_tzImagePickerVc = (SPImagePickerController *)self.navigationController;
    SPAssetModel *model = _models[indexPath.item];
    
    SPAssetPreviewCell *cell;
    __weak typeof(self) weakSelf = self;
    if (_tzImagePickerVc.allowPickingMultipleVideo && model.type == SPAssetModelMediaTypeVideo) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZVideoPreviewCell" forIndexPath:indexPath];
    } else if (_tzImagePickerVc.allowPickingMultipleVideo && model.type == SPAssetModelMediaTypePhotoGif && _tzImagePickerVc.allowPickingGif) {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZGifPreviewCell" forIndexPath:indexPath];
    } else {
        cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TZPhotoPreviewCell" forIndexPath:indexPath];
        SPPhotoPreviewCell *photoPreviewCell = (SPPhotoPreviewCell *)cell;
        photoPreviewCell.cropRect = _tzImagePickerVc.cropRect;
        photoPreviewCell.allowCrop = _tzImagePickerVc.allowCrop;
        __weak typeof(_tzImagePickerVc) weakTzImagePickerVc = _tzImagePickerVc;
        __weak typeof(_collectionView) weakCollectionView = _collectionView;
        __weak typeof(photoPreviewCell) weakCell = photoPreviewCell;
        [photoPreviewCell setImageProgressUpdateBlock:^(double progress) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            __strong typeof(weakTzImagePickerVc) strongTzImagePickerVc = weakTzImagePickerVc;
            __strong typeof(weakCollectionView) strongCollectionView = weakCollectionView;
            __strong typeof(weakCell) strongCell = weakCell;
            strongSelf.progress = progress;
            if (progress >= 1) {
                if (strongSelf.isSelectOriginalPhoto) [strongSelf showPhotoBytes];
                if (strongSelf.alertView && [strongCollectionView.visibleCells containsObject:strongCell]) {
                    [strongTzImagePickerVc hideAlertView:strongSelf.alertView];
                    strongSelf.alertView = nil;
                    [strongSelf doneButtonClick];
                }
            }
        }];
    }
    
    cell.model = model;
    [cell setSingleTapGestureBlock:^{
        __strong typeof(weakSelf) strongSelf = weakSelf;
        [strongSelf didTapPreviewCell];
    }];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[SPPhotoPreviewCell class]]) {
        [(SPPhotoPreviewCell *)cell recoverSubviews];
    }
}

- (void)collectionView:(UICollectionView *)collectionView didEndDisplayingCell:(UICollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath {
    if ([cell isKindOfClass:[SPPhotoPreviewCell class]]) {
        [(SPPhotoPreviewCell *)cell recoverSubviews];
    } else if ([cell isKindOfClass:[SPVideoPreviewCell class]]) {
        [(SPVideoPreviewCell *)cell pausePlayerAndShowNaviBar];
    }
}

#pragma mark - Private Method

- (void)dealloc {
    // NSLog(@"%@ dealloc",NSStringFromClass(self.class));
}

- (void)refreshNaviBarAndBottomBarState {
    SPImagePickerController *_tzImagePickerVc = (SPImagePickerController *)self.navigationController;
    SPAssetModel *model = _models[self.currentIndex];
    _selectButton.selected = model.isSelected;
    [self refreshSelectButtonImageViewContentMode];
    if (_selectButton.isSelected && _tzImagePickerVc.showSelectedIndex && _tzImagePickerVc.showSelectBtn) {
        NSString *index = [NSString stringWithFormat:@"%d", (int)([_tzImagePickerVc.selectedAssetIds indexOfObject:model.asset.localIdentifier] + 1)];
        _indexLabel.text = index;
        _indexLabel.hidden = NO;
    } else {
        _indexLabel.hidden = YES;
    }
    _numberLabel.text = [NSString stringWithFormat:@"%zd",_tzImagePickerVc.selectedModels.count];
    _numberImageView.hidden = (_tzImagePickerVc.selectedModels.count <= 0 || _isHideNaviBar || _isCropImage);
    _numberLabel.hidden = (_tzImagePickerVc.selectedModels.count <= 0 || _isHideNaviBar || _isCropImage);
    
    _originalPhotoButton.selected = _isSelectOriginalPhoto;
    _originalPhotoLabel.hidden = !_originalPhotoButton.isSelected;
    if (_isSelectOriginalPhoto) [self showPhotoBytes];
    
    // If is previewing video, hide original photo button
    // 如果正在预览的是视频，隐藏原图按钮
    if (!_isHideNaviBar) {
        if (model.type == SPAssetModelMediaTypeVideo) {
            _originalPhotoButton.hidden = YES;
            _originalPhotoLabel.hidden = YES;
        } else {
            _originalPhotoButton.hidden = NO;
            if (_isSelectOriginalPhoto)  _originalPhotoLabel.hidden = NO;
        }
    }
    
    _doneButton.hidden = NO;
    _selectButton.hidden = !_tzImagePickerVc.showSelectBtn;
    // 让宽度/高度小于 最小可选照片尺寸 的图片不能选中
    if (![[SPImageManager manager] isPhotoSelectableWithAsset:model.asset]) {
        _numberLabel.hidden = YES;
        _numberImageView.hidden = YES;
        _selectButton.hidden = YES;
        _originalPhotoButton.hidden = YES;
        _originalPhotoLabel.hidden = YES;
        _doneButton.hidden = YES;
    }
}

- (void)refreshSelectButtonImageViewContentMode {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self->_selectButton.imageView.image.size.width <= 27) {
            self->_selectButton.imageView.contentMode = UIViewContentModeCenter;
        } else {
            self->_selectButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
        }
    });
}

- (void)showPhotoBytes {
    [[SPImageManager manager] getPhotosBytesWithArray:@[_models[self.currentIndex]] completion:^(NSString *totalBytes) {
        self->_originalPhotoLabel.text = [NSString stringWithFormat:@"(%@)",totalBytes];
    }];
}

- (NSInteger)currentIndex {
    return [SPCommonTools sp_isRightToLeftLayout] ? self.models.count - _currentIndex - 1 : _currentIndex;
}

@end
