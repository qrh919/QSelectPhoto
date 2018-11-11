//
//  SelectSuccessViewController.m
//  SelectPhoto
//
//  Created by qrh on 2018/11/8.
//  Copyright © 2018年 applee. All rights reserved.
//

#import "SelectSuccessViewController.h"
#import "LxGridViewFlowLayout.h"
#import "SelectSuccessCell.h"
#import "UIView+SPLayout.h"

static NSString *const kSelectSuccessCell = @"kSelectSuccessCell";

@interface SelectSuccessViewController ()
<UICollectionViewDataSource,UICollectionViewDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (strong, nonatomic) LxGridViewFlowLayout *layout;
@end

@implementation SelectSuccessViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self initializePageSubviews];
}

-(void)viewWillAppear:(BOOL)animated{
    [super viewWillAppear:animated];
    self.navigationController.navigationBarHidden = NO;
}

#pragma mark - delegate
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return _images.count + 1;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    SelectSuccessCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:kSelectSuccessCell forIndexPath:indexPath];
    if(indexPath.item == _images.count){
        cell.image = [UIImage imageNamed:@"AlbumAddBtn"];
        cell.hideDelete = YES;
    }else{
        cell.image = _images[indexPath.item];
        cell.hideDelete = NO;
    }
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    // preview photos / 预览照片
//    TZImagePickerController *imagePickerVc = [[TZImagePickerController alloc] initWithSelectedAssets:_selectedAssets selectedPhotos:_selectedPhotos index:indexPath.item];
//    imagePickerVc.maxImagesCount = self.maxCountTF.text.integerValue;
//    imagePickerVc.allowPickingGif = self.allowPickingGifSwitch.isOn;
//    imagePickerVc.allowPickingOriginalPhoto = self.allowPickingOriginalPhotoSwitch.isOn;
//    imagePickerVc.allowPickingMultipleVideo = self.allowPickingMuitlpleVideoSwitch.isOn;
//    imagePickerVc.showSelectedIndex = self.showSelectedIndexSwitch.isOn;
//    imagePickerVc.isSelectOriginalPhoto = _isSelectOriginalPhoto;
//    [imagePickerVc setDidFinishPickingPhotosHandle:^(NSArray<UIImage *> *photos, NSArray *assets, BOOL isSelectOriginalPhoto) {
//        self->_selectedPhotos = [NSMutableArray arrayWithArray:photos];
//        self->_selectedAssets = [NSMutableArray arrayWithArray:assets];
//        self->_isSelectOriginalPhoto = isSelectOriginalPhoto;
//        [self->_collectionView reloadData];
//        self->_collectionView.contentSize = CGSizeMake(0, ((self->_selectedPhotos.count + 2) / 3 ) * (self->_margin + self->_itemWH));
//    }];
//    [self presentViewController:imagePickerVc animated:YES completion:nil];
    
}

#pragma mark - LxGridViewDataSource

/// 以下三个方法为长按排序相关代码
- (BOOL)collectionView:(UICollectionView *)collectionView canMoveItemAtIndexPath:(NSIndexPath *)indexPath {
    return indexPath.item < _images.count;
}

- (BOOL)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)sourceIndexPath canMoveToIndexPath:(NSIndexPath *)destinationIndexPath {
    return (sourceIndexPath.item < _images.count && destinationIndexPath.item < _images.count);
}

- (void)collectionView:(UICollectionView *)collectionView itemAtIndexPath:(NSIndexPath *)sourceIndexPath didMoveToIndexPath:(NSIndexPath *)destinationIndexPath {
    UIImage *image = _images[sourceIndexPath.item];
    [_images removeObjectAtIndex:sourceIndexPath.item];
    [_images insertObject:image atIndex:destinationIndexPath.item];
    
    [_collectionView reloadData];
}

#pragma mark - init
-(void)initializePageSubviews{
    self.navigationItem.title = @"发布";
    [self.view addSubview:self.collectionView];
    [_collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.size.equalTo(self.view);
        make.center.equalTo(self.view);
    }];
    [_collectionView reloadData];
}

-(UICollectionView *)collectionView{
    if(!_collectionView){
        LxGridViewFlowLayout *layout = [[LxGridViewFlowLayout alloc] init];
        CGFloat margin = 4;
        CGFloat itemWH = (self.view.sp_width - 2 * margin - 4) / 3 - margin;
        layout.itemSize = CGSizeMake(itemWH, itemWH);
        layout.minimumInteritemSpacing = margin;
        layout.minimumLineSpacing = margin;
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
        CGFloat rgb = 244 / 255.0;
        _collectionView.alwaysBounceVertical = YES;
        _collectionView.backgroundColor = [UIColor colorWithRed:rgb green:rgb blue:rgb alpha:1.0];
        _collectionView.contentInset = UIEdgeInsetsMake(4, 4, 4, 4);
        _collectionView.dataSource = self;
        _collectionView.delegate = self;
        _collectionView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
        [self.view addSubview:_collectionView];
        [_collectionView registerClass:[SelectSuccessCell class] forCellWithReuseIdentifier:kSelectSuccessCell];
    }
    return _collectionView;
}

@end
