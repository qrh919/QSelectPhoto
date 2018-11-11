//
//  SPImageManager.m
//  SPImagePickerController
//
//  Created by 谭真 on 16/1/4.
//  Copyright © 2016年 谭真. All rights reserved.
//

#import "SPImageManager.h"
#import "SPAssetModel.h"
#import "SPImagePickerController.h"

@interface SPImageManager ()
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
@end

@implementation SPImageManager

CGSize AssetGridThumbnailSize;
CGFloat SPScreenWidth;
CGFloat SPScreenScale;

static SPImageManager *manager;
static dispatch_once_t onceToken;

+ (instancetype)manager {
    dispatch_once(&onceToken, ^{
        manager = [[self alloc] init];
        // manager.cachingImageManager = [[PHCachingImageManager alloc] init];
        // manager.cachingImageManager.allowsCachingHighQualityImages = YES;
        
        [manager configTZScreenWidth];
    });
    return manager;
}

+ (void)deallocManager {
    onceToken = 0;
    manager = nil;
}

- (void)setPhotoWidth:(CGFloat)photoWidth {
    _photoWidth = photoWidth;
    SPScreenWidth = photoWidth / 2;
}

- (void)setColumnNumber:(NSInteger)columnNumber {
    [self configTZScreenWidth];

    _columnNumber = columnNumber;
    CGFloat margin = 4;
    CGFloat itemWH = (SPScreenWidth - 2 * margin - 4) / columnNumber - margin;
    AssetGridThumbnailSize = CGSizeMake(itemWH * SPScreenScale, itemWH * SPScreenScale);
}

- (void)configTZScreenWidth {
    SPScreenWidth = [UIScreen mainScreen].bounds.size.width;
    // 测试发现，如果scale在plus真机上取到3.0，内存会增大特别多。故这里写死成2.0
    SPScreenScale = 2.0;
    if (SPScreenWidth > 700) {
        SPScreenScale = 1.5;
    }
}

/// Return YES if Authorized 返回YES如果得到了授权
- (BOOL)authorizationStatusAuthorized {
    NSInteger status = [PHPhotoLibrary authorizationStatus];
    if (status == 0) {
        /**
         * 当某些情况下AuthorizationStatus == AuthorizationStatusNotDetermined时，无法弹出系统首次使用的授权alertView，系统应用设置里亦没有相册的设置，此时将无法使用，故作以下操作，弹出系统首次使用的授权alertView
         */
        [self requestAuthorizationWithCompletion:nil];
    }
    
    return status == 3;
}

- (void)requestAuthorizationWithCompletion:(void (^)(void))completion {
    void (^callCompletionBlock)(void) = ^(){
        dispatch_async(dispatch_get_main_queue(), ^{
            if (completion) {
                completion();
            }
        });
    };
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            callCompletionBlock();
        }];
    });
}

#pragma mark - Get Album

/// Get Album 获得相册/相册数组
- (void)getCameraRollAlbum:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage needFetchAssets:(BOOL)needFetchAssets completion:(void (^)(SPAlbumModel *model))completion {
    __block SPAlbumModel *model;
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    if (!allowPickingVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    if (!allowPickingImage) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",
                                                PHAssetMediaTypeVideo];
    // option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:self.sortAscendingByModificationDate]];
    if (!self.sortAscendingByModificationDate) {
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:self.sortAscendingByModificationDate]];
    }
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    for (PHAssetCollection *collection in smartAlbums) {
        // 有可能是PHCollectionList类的的对象，过滤掉
        if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
        // 过滤空相册
        if (collection.estimatedAssetCount <= 0) continue;
        if ([self isCameraRollAlbum:collection]) {
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            model = [self modelWithResult:fetchResult name:collection.localizedTitle isCameraRoll:YES needFetchAssets:needFetchAssets];
            if (completion) completion(model);
            break;
        }
    }
}

- (void)getAllAlbums:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage needFetchAssets:(BOOL)needFetchAssets completion:(void (^)(NSArray<SPAlbumModel *> *))completion{
    NSMutableArray *albumArr = [NSMutableArray array];
    PHFetchOptions *option = [[PHFetchOptions alloc] init];
    if (!allowPickingVideo) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld", PHAssetMediaTypeImage];
    if (!allowPickingImage) option.predicate = [NSPredicate predicateWithFormat:@"mediaType == %ld",
                                                PHAssetMediaTypeVideo];
    // option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"modificationDate" ascending:self.sortAscendingByModificationDate]];
    if (!self.sortAscendingByModificationDate) {
        option.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate" ascending:self.sortAscendingByModificationDate]];
    }
    // 我的照片流 1.6.10重新加入..
    PHFetchResult *myPhotoStreamAlbum = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumMyPhotoStream options:nil];
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum subtype:PHAssetCollectionSubtypeAlbumRegular options:nil];
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    PHFetchResult *syncedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumSyncedAlbum options:nil];
    PHFetchResult *sharedAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeAlbum subtype:PHAssetCollectionSubtypeAlbumCloudShared options:nil];
    NSArray *allAlbums = @[myPhotoStreamAlbum,smartAlbums,topLevelUserCollections,syncedAlbums,sharedAlbums];
    for (PHFetchResult *fetchResult in allAlbums) {
        for (PHAssetCollection *collection in fetchResult) {
            // 有可能是PHCollectionList类的的对象，过滤掉
            if (![collection isKindOfClass:[PHAssetCollection class]]) continue;
            // 过滤空相册
            if (collection.estimatedAssetCount <= 0) continue;
            PHFetchResult *fetchResult = [PHAsset fetchAssetsInAssetCollection:collection options:option];
            if (fetchResult.count < 1) continue;
            
            if ([self.pickerDelegate respondsToSelector:@selector(isAlbumCanSelect:result:)]) {
                if (![self.pickerDelegate isAlbumCanSelect:collection.localizedTitle result:fetchResult]) {
                    continue;
                }
            }
            
            if (collection.assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumAllHidden) continue;
            if (collection.assetCollectionSubtype == 1000000201) continue; //『最近删除』相册
            if ([self isCameraRollAlbum:collection]) {
                [albumArr insertObject:[self modelWithResult:fetchResult name:collection.localizedTitle isCameraRoll:YES needFetchAssets:needFetchAssets] atIndex:0];
            } else {
                [albumArr addObject:[self modelWithResult:fetchResult name:collection.localizedTitle isCameraRoll:NO needFetchAssets:needFetchAssets]];
            }
        }
    }
    if (completion && albumArr.count > 0) completion(albumArr);
}

#pragma mark - Get Assets

/// Get Assets 获得照片数组
- (void)getAssetsFromFetchResult:(PHFetchResult *)result completion:(void (^)(NSArray<SPAssetModel *> *))completion {
    SPImagePickerConfig *config = [SPImagePickerConfig sharedInstance];
    return [self getAssetsFromFetchResult:result allowPickingVideo:config.allowPickingVideo allowPickingImage:config.allowPickingImage completion:completion];
}

- (void)getAssetsFromFetchResult:(PHFetchResult *)result allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(NSArray<SPAssetModel *> *))completion {
    NSMutableArray *photoArr = [NSMutableArray array];
    [result enumerateObjectsUsingBlock:^(PHAsset *asset, NSUInteger idx, BOOL * _Nonnull stop) {
        SPAssetModel *model = [self assetModelWithAsset:asset allowPickingVideo:allowPickingVideo allowPickingImage:allowPickingImage];
        if (model) {
            [photoArr addObject:model];
        }
    }];
    if (completion) completion(photoArr);
}

///  Get asset at index 获得下标为index的单个照片
///  if index beyond bounds, return nil in callback 如果索引越界, 在回调中返回 nil
- (void)getAssetFromFetchResult:(PHFetchResult *)result atIndex:(NSInteger)index allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage completion:(void (^)(SPAssetModel *))completion {
    PHAsset *asset;
    @try {
        asset = result[index];
    }
    @catch (NSException* e) {
        if (completion) completion(nil);
        return;
    }
    SPAssetModel *model = [self assetModelWithAsset:asset allowPickingVideo:allowPickingVideo allowPickingImage:allowPickingImage];
    if (completion) completion(model);
}

- (SPAssetModel *)assetModelWithAsset:(PHAsset *)asset allowPickingVideo:(BOOL)allowPickingVideo allowPickingImage:(BOOL)allowPickingImage {
    BOOL canSelect = YES;
    if ([self.pickerDelegate respondsToSelector:@selector(isAssetCanSelect:)]) {
        canSelect = [self.pickerDelegate isAssetCanSelect:asset];
    }
    if (!canSelect) return nil;
    
    SPAssetModel *model;
    SPAssetModelMediaType type = [self getAssetType:asset];
    if (!allowPickingVideo && type == SPAssetModelMediaTypeVideo) return nil;
    if (!allowPickingImage && type == SPAssetModelMediaTypePhoto) return nil;
    if (!allowPickingImage && type == SPAssetModelMediaTypePhotoGif) return nil;
    
    PHAsset *phAsset = (PHAsset *)asset;
    if (self.hideWhenCanNotSelect) {
        // 过滤掉尺寸不满足要求的图片
        if (![self isPhotoSelectableWithAsset:phAsset]) {
            return nil;
        }
    }
    NSString *timeLength = type == SPAssetModelMediaTypeVideo ? [NSString stringWithFormat:@"%0.0f",phAsset.duration] : @"";
    timeLength = [self getNewTimeFromDurationSecond:timeLength.integerValue];
    model = [SPAssetModel modelWithAsset:asset type:type timeLength:timeLength];
    return model;
}

- (SPAssetModelMediaType)getAssetType:(PHAsset *)asset {
    SPAssetModelMediaType type = SPAssetModelMediaTypePhoto;
    PHAsset *phAsset = (PHAsset *)asset;
    if (phAsset.mediaType == PHAssetMediaTypeVideo)      type = SPAssetModelMediaTypeVideo;
    else if (phAsset.mediaType == PHAssetMediaTypeAudio) type = SPAssetModelMediaTypeAudio;
    else if (phAsset.mediaType == PHAssetMediaTypeImage) {
        if (@available(iOS 9.1, *)) {
            // if (asset.mediaSubtypes == PHAssetMediaSubtypePhotoLive) type = SPAssetModelMediaTypeLivePhoto;
        }
        // Gif
        if ([[phAsset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
            type = SPAssetModelMediaTypePhotoGif;
        }
    }
    return type;
}

- (NSString *)getNewTimeFromDurationSecond:(NSInteger)duration {
    NSString *newTime;
    if (duration < 10) {
        newTime = [NSString stringWithFormat:@"0:0%zd",duration];
    } else if (duration < 60) {
        newTime = [NSString stringWithFormat:@"0:%zd",duration];
    } else {
        NSInteger min = duration / 60;
        NSInteger sec = duration - (min * 60);
        if (sec < 10) {
            newTime = [NSString stringWithFormat:@"%zd:0%zd",min,sec];
        } else {
            newTime = [NSString stringWithFormat:@"%zd:%zd",min,sec];
        }
    }
    return newTime;
}

/// Get photo bytes 获得一组照片的大小
- (void)getPhotosBytesWithArray:(NSArray *)photos completion:(void (^)(NSString *totalBytes))completion {
    if (!photos || !photos.count) {
        if (completion) completion(@"0B");
        return;
    }
    __block NSInteger dataLength = 0;
    __block NSInteger assetCount = 0;
    for (NSInteger i = 0; i < photos.count; i++) {
        SPAssetModel *model = photos[i];
        PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
        options.resizeMode = PHImageRequestOptionsResizeModeFast;
        options.networkAccessAllowed = YES;
        if (model.type == SPAssetModelMediaTypePhotoGif) {
            options.version = PHImageRequestOptionsVersionOriginal;
        }
        [[PHImageManager defaultManager] requestImageDataForAsset:model.asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
            if (model.type != SPAssetModelMediaTypeVideo) dataLength += imageData.length;
            assetCount ++;
            if (assetCount >= photos.count) {
                NSString *bytes = [self getBytesFromDataLength:dataLength];
                if (completion) completion(bytes);
            }
        }];
    }
}

- (NSString *)getBytesFromDataLength:(NSInteger)dataLength {
    NSString *bytes;
    if (dataLength >= 0.1 * (1024 * 1024)) {
        bytes = [NSString stringWithFormat:@"%0.1fM",dataLength/1024/1024.0];
    } else if (dataLength >= 1024) {
        bytes = [NSString stringWithFormat:@"%0.0fK",dataLength/1024.0];
    } else {
        bytes = [NSString stringWithFormat:@"%zdB",dataLength];
    }
    return bytes;
}

#pragma mark - Get Photo

/// Get photo 获得照片本身
- (int32_t)getPhotoWithAsset:(PHAsset *)asset completion:(void (^)(UIImage *, NSDictionary *, BOOL isDegraded))completion {
    CGFloat fullScreenWidth = SPScreenWidth;
    if (fullScreenWidth > _photoPreviewMaxWidth) {
        fullScreenWidth = _photoPreviewMaxWidth;
    }
    return [self getPhotoWithAsset:asset photoWidth:fullScreenWidth completion:completion progressHandler:nil networkAccessAllowed:YES];
}

- (int32_t)getPhotoWithAsset:(PHAsset *)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion {
    return [self getPhotoWithAsset:asset photoWidth:photoWidth completion:completion progressHandler:nil networkAccessAllowed:YES];
}

- (int32_t)getPhotoWithAsset:(PHAsset *)asset completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler networkAccessAllowed:(BOOL)networkAccessAllowed {
    CGFloat fullScreenWidth = SPScreenWidth;
    if (_photoPreviewMaxWidth > 0 && fullScreenWidth > _photoPreviewMaxWidth) {
        fullScreenWidth = _photoPreviewMaxWidth;
    }
    return [self getPhotoWithAsset:asset photoWidth:fullScreenWidth completion:completion progressHandler:progressHandler networkAccessAllowed:networkAccessAllowed];
}

- (int32_t)requestImageDataForAsset:(PHAsset *)asset completion:(void (^)(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info))completion progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler {
    PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
    options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressHandler) {
                progressHandler(progress, error, stop, info);
            }
        });
    };
    options.networkAccessAllowed = YES;
    options.resizeMode = PHImageRequestOptionsResizeModeFast;
    int32_t imageRequestID = [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
        if (completion) completion(imageData,dataUTI,orientation,info);
    }];
    return imageRequestID;
}

- (int32_t)getPhotoWithAsset:(PHAsset *)asset photoWidth:(CGFloat)photoWidth completion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler networkAccessAllowed:(BOOL)networkAccessAllowed {
    CGSize imageSize;
    if (photoWidth < SPScreenWidth && photoWidth < _photoPreviewMaxWidth) {
        imageSize = AssetGridThumbnailSize;
    } else {
        PHAsset *phAsset = (PHAsset *)asset;
        CGFloat aspectRatio = phAsset.pixelWidth / (CGFloat)phAsset.pixelHeight;
        CGFloat pixelWidth = photoWidth * SPScreenScale * 1.5;
        // 超宽图片
        if (aspectRatio > 1.8) {
            pixelWidth = pixelWidth * aspectRatio;
        }
        // 超高图片
        if (aspectRatio < 0.2) {
            pixelWidth = pixelWidth * 0.5;
        }
        CGFloat pixelHeight = pixelWidth / aspectRatio;
        imageSize = CGSizeMake(pixelWidth, pixelHeight);
    }
    
    __block UIImage *image;
    // 修复获取图片时出现的瞬间内存过高问题
    // 下面两行代码，来自hsjcom，他的github是：https://github.com/hsjcom 表示感谢
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    int32_t imageRequestID = [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:imageSize contentMode:PHImageContentModeAspectFill options:option resultHandler:^(UIImage *result, NSDictionary *info) {
        if (result) {
            image = result;
        }
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        if (downloadFinined && result) {
            result = [self fixOrientation:result];
            if (completion) completion(result,info,[[info objectForKey:PHImageResultIsDegradedKey] boolValue]);
        }
        // Download image from iCloud / 从iCloud下载图片
        if ([info objectForKey:PHImageResultIsInCloudKey] && !result && networkAccessAllowed) {
            PHImageRequestOptions *options = [[PHImageRequestOptions alloc] init];
            options.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (progressHandler) {
                        progressHandler(progress, error, stop, info);
                    }
                });
            };
            options.networkAccessAllowed = YES;
            options.resizeMode = PHImageRequestOptionsResizeModeFast;
            [[PHImageManager defaultManager] requestImageDataForAsset:asset options:options resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
                UIImage *resultImage = [UIImage imageWithData:imageData];
                if (![SPImagePickerConfig sharedInstance].notScaleImage) {
                    resultImage = [self scaleImage:resultImage toSize:imageSize];
                }
                if (!resultImage) {
                    resultImage = image;
                }
                resultImage = [self fixOrientation:resultImage];
                if (completion) completion(resultImage,info,NO);
            }];
        }
    }];
    return imageRequestID;
}

/// Get postImage / 获取封面图
- (void)getPostImageWithAlbumModel:(SPAlbumModel *)model completion:(void (^)(UIImage *))completion {
    id asset = [model.result lastObject];
    if (!self.sortAscendingByModificationDate) {
        asset = [model.result firstObject];
    }
    [[SPImageManager manager] getPhotoWithAsset:asset photoWidth:80 completion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        if (completion) completion(photo);
    }];
}

/// Get Original Photo / 获取原图
- (void)getOriginalPhotoWithAsset:(PHAsset *)asset completion:(void (^)(UIImage *photo,NSDictionary *info))completion {
    [self getOriginalPhotoWithAsset:asset newCompletion:^(UIImage *photo, NSDictionary *info, BOOL isDegraded) {
        if (completion) {
            completion(photo,info);
        }
    }];
}

- (void)getOriginalPhotoWithAsset:(PHAsset *)asset newCompletion:(void (^)(UIImage *photo,NSDictionary *info,BOOL isDegraded))completion {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc]init];
    option.networkAccessAllowed = YES;
    option.resizeMode = PHImageRequestOptionsResizeModeFast;
    [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:PHImageManagerMaximumSize contentMode:PHImageContentModeAspectFit options:option resultHandler:^(UIImage *result, NSDictionary *info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        if (downloadFinined && result) {
            result = [self fixOrientation:result];
            BOOL isDegraded = [[info objectForKey:PHImageResultIsDegradedKey] boolValue];
            if (completion) completion(result,info,isDegraded);
        }
    }];
}

- (void)getOriginalPhotoDataWithAsset:(PHAsset *)asset completion:(void (^)(NSData *data,NSDictionary *info,BOOL isDegraded))completion {
    [self getOriginalPhotoDataWithAsset:asset progressHandler:nil completion:completion];
}

- (void)getOriginalPhotoDataWithAsset:(PHAsset *)asset progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler completion:(void (^)(NSData *data,NSDictionary *info,BOOL isDegraded))completion {
    PHImageRequestOptions *option = [[PHImageRequestOptions alloc] init];
    option.networkAccessAllowed = YES;
    if ([[asset valueForKey:@"filename"] hasSuffix:@"GIF"]) {
        // if version isn't PHImageRequestOptionsVersionOriginal, the gif may cann't play
        option.version = PHImageRequestOptionsVersionOriginal;
    }
    [option setProgressHandler:progressHandler];
    option.deliveryMode = PHImageRequestOptionsDeliveryModeHighQualityFormat;
    [[PHImageManager defaultManager] requestImageDataForAsset:asset options:option resultHandler:^(NSData *imageData, NSString *dataUTI, UIImageOrientation orientation, NSDictionary *info) {
        BOOL downloadFinined = (![[info objectForKey:PHImageCancelledKey] boolValue] && ![info objectForKey:PHImageErrorKey]);
        if (downloadFinined && imageData) {
            if (completion) completion(imageData,info,NO);
        }
    }];
}

#pragma mark - Save photo

- (void)savePhotoWithImage:(UIImage *)image completion:(void (^)(PHAsset *asset, NSError *error))completion {
    [self savePhotoWithImage:image location:nil completion:completion];
}

- (void)savePhotoWithImage:(UIImage *)image location:(CLLocation *)location completion:(void (^)(PHAsset *asset, NSError *error))completion {
    __block NSString *localIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromImage:image];
        localIdentifier = request.placeholderForCreatedAsset.localIdentifier;
        if (location) {
            request.location = location;
        }
        request.creationDate = [NSDate date];
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success && completion) {
                PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil] firstObject];
                completion(asset, nil);
            } else if (error) {
                NSLog(@"保存照片出错:%@",error.localizedDescription);
                if (completion) {
                    completion(nil, error);
                }
            }
        });
    }];
}

#pragma mark - Save video

- (void)saveVideoWithUrl:(NSURL *)url completion:(void (^)(PHAsset *asset, NSError *error))completion {
    [self saveVideoWithUrl:url location:nil completion:completion];
}

- (void)saveVideoWithUrl:(NSURL *)url location:(CLLocation *)location completion:(void (^)(PHAsset *asset, NSError *error))completion {
    __block NSString *localIdentifier = nil;
    [[PHPhotoLibrary sharedPhotoLibrary] performChanges:^{
        PHAssetChangeRequest *request = [PHAssetChangeRequest creationRequestForAssetFromVideoAtFileURL:url];
        localIdentifier = request.placeholderForCreatedAsset.localIdentifier;
        if (location) {
            request.location = location;
        }
        request.creationDate = [NSDate date];
    } completionHandler:^(BOOL success, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (success && completion) {
                PHAsset *asset = [[PHAsset fetchAssetsWithLocalIdentifiers:@[localIdentifier] options:nil] firstObject];
                completion(asset, nil);
            } else if (error) {
                NSLog(@"保存视频出错:%@",error.localizedDescription);
                if (completion) {
                    completion(nil, error);
                }
            }
        });
    }];
}

#pragma mark - Get Video

/// Get Video / 获取视频
- (void)getVideoWithAsset:(PHAsset *)asset completion:(void (^)(AVPlayerItem *, NSDictionary *))completion {
    [self getVideoWithAsset:asset progressHandler:nil completion:completion];
}

- (void)getVideoWithAsset:(PHAsset *)asset progressHandler:(void (^)(double progress, NSError *error, BOOL *stop, NSDictionary *info))progressHandler completion:(void (^)(AVPlayerItem *, NSDictionary *))completion {
    PHVideoRequestOptions *option = [[PHVideoRequestOptions alloc] init];
    option.networkAccessAllowed = YES;
    option.progressHandler = ^(double progress, NSError *error, BOOL *stop, NSDictionary *info) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (progressHandler) {
                progressHandler(progress, error, stop, info);
            }
        });
    };
    [[PHImageManager defaultManager] requestPlayerItemForVideo:asset options:option resultHandler:^(AVPlayerItem *playerItem, NSDictionary *info) {
        if (completion) completion(playerItem,info);
    }];
}

#pragma mark - Export video

/// Export Video / 导出视频
- (void)getVideoOutputPathWithAsset:(PHAsset *)asset success:(void (^)(NSString *outputPath))success failure:(void (^)(NSString *errorMessage, NSError *error))failure {
    [self getVideoOutputPathWithAsset:asset presetName:AVAssetExportPreset640x480 success:success failure:failure];
}

- (void)getVideoOutputPathWithAsset:(PHAsset *)asset presetName:(NSString *)presetName success:(void (^)(NSString *outputPath))success failure:(void (^)(NSString *errorMessage, NSError *error))failure {
    PHVideoRequestOptions* options = [[PHVideoRequestOptions alloc] init];
    options.version = PHVideoRequestOptionsVersionOriginal;
    options.deliveryMode = PHVideoRequestOptionsDeliveryModeAutomatic;
    options.networkAccessAllowed = YES;
    [[PHImageManager defaultManager] requestAVAssetForVideo:asset options:options resultHandler:^(AVAsset* avasset, AVAudioMix* audioMix, NSDictionary* info){
        // NSLog(@"Info:\n%@",info);
        AVURLAsset *videoAsset = (AVURLAsset*)avasset;
        // NSLog(@"AVAsset URL: %@",myAsset.URL);
        [self startExportVideoWithVideoAsset:videoAsset presetName:presetName success:success failure:failure];
    }];
}

/// Deprecated, Use -getVideoOutputPathWithAsset:failure:success:
- (void)getVideoOutputPathWithAsset:(PHAsset *)asset completion:(void (^)(NSString *outputPath))completion {
    [self getVideoOutputPathWithAsset:asset success:completion failure:nil];
}

- (void)startExportVideoWithVideoAsset:(AVURLAsset *)videoAsset presetName:(NSString *)presetName success:(void (^)(NSString *outputPath))success failure:(void (^)(NSString *errorMessage, NSError *error))failure {
    // Find compatible presets by video asset.
    NSArray *presets = [AVAssetExportSession exportPresetsCompatibleWithAsset:videoAsset];
    
    // Begin to compress video
    // Now we just compress to low resolution if it supports
    // If you need to upload to the server, but server does't support to upload by streaming,
    // You can compress the resolution to lower. Or you can support more higher resolution.
    if ([presets containsObject:presetName]) {
        AVAssetExportSession *session = [[AVAssetExportSession alloc] initWithAsset:videoAsset presetName:presetName];
        NSDateFormatter *formater = [[NSDateFormatter alloc] init];
        [formater setDateFormat:@"yyyy-MM-dd-HH:mm:ss-SSS"];
        NSString *outputPath = [NSHomeDirectory() stringByAppendingFormat:@"/tmp/video-%@.mp4", [formater stringFromDate:[NSDate date]]];
        if (videoAsset.URL && videoAsset.URL.lastPathComponent) {
            outputPath = [outputPath stringByReplacingOccurrencesOfString:@".mp4" withString:[NSString stringWithFormat:@"-%@", videoAsset.URL.lastPathComponent]];
        }
        // NSLog(@"video outputPath = %@",outputPath);
        session.outputURL = [NSURL fileURLWithPath:outputPath];
        
        // Optimize for network use.
        session.shouldOptimizeForNetworkUse = true;
        
        NSArray *supportedTypeArray = session.supportedFileTypes;
        if ([supportedTypeArray containsObject:AVFileTypeMPEG4]) {
            session.outputFileType = AVFileTypeMPEG4;
        } else if (supportedTypeArray.count == 0) {
            if (failure) {
                failure(@"该视频类型暂不支持导出", nil);
            }
            NSLog(@"No supported file types 视频类型暂不支持导出");
            return;
        } else {
            session.outputFileType = [supportedTypeArray objectAtIndex:0];
        }
        
        if (![[NSFileManager defaultManager] fileExistsAtPath:[NSHomeDirectory() stringByAppendingFormat:@"/tmp"]]) {
            [[NSFileManager defaultManager] createDirectoryAtPath:[NSHomeDirectory() stringByAppendingFormat:@"/tmp"] withIntermediateDirectories:YES attributes:nil error:nil];
        }
        
        if ([SPImagePickerConfig sharedInstance].needFixComposition) {
            AVMutableVideoComposition *videoComposition = [self fixedCompositionWithAsset:videoAsset];
            if (videoComposition.renderSize.width) {
                // 修正视频转向
                session.videoComposition = videoComposition;
            }
        }

        // Begin to export video to the output path asynchronously.
        [session exportAsynchronouslyWithCompletionHandler:^(void) {
            dispatch_async(dispatch_get_main_queue(), ^{
                switch (session.status) {
                    case AVAssetExportSessionStatusUnknown: {
                        NSLog(@"AVAssetExportSessionStatusUnknown");
                    }  break;
                    case AVAssetExportSessionStatusWaiting: {
                        NSLog(@"AVAssetExportSessionStatusWaiting");
                    }  break;
                    case AVAssetExportSessionStatusExporting: {
                        NSLog(@"AVAssetExportSessionStatusExporting");
                    }  break;
                    case AVAssetExportSessionStatusCompleted: {
                        NSLog(@"AVAssetExportSessionStatusCompleted");
                        if (success) {
                            success(outputPath);
                        }
                    }  break;
                    case AVAssetExportSessionStatusFailed: {
                        NSLog(@"AVAssetExportSessionStatusFailed");
                        if (failure) {
                            failure(@"视频导出失败", session.error);
                        }
                    }  break;
                    case AVAssetExportSessionStatusCancelled: {
                        NSLog(@"AVAssetExportSessionStatusCancelled");
                        if (failure) {
                            failure(@"导出任务已被取消", nil);
                        }
                    }  break;
                    default: break;
                }
            });
        }];
    } else {
        if (failure) {
            NSString *errorMessage = [NSString stringWithFormat:@"当前设备不支持该预设:%@", presetName];
            failure(errorMessage, nil);
        }
    }
}

- (BOOL)isCameraRollAlbum:(PHAssetCollection *)metadata {
    NSString *versionStr = [[UIDevice currentDevice].systemVersion stringByReplacingOccurrencesOfString:@"." withString:@""];
    if (versionStr.length <= 1) {
        versionStr = [versionStr stringByAppendingString:@"00"];
    } else if (versionStr.length <= 2) {
        versionStr = [versionStr stringByAppendingString:@"0"];
    }
    CGFloat version = versionStr.floatValue;
    // 目前已知8.0.0 ~ 8.0.2系统，拍照后的图片会保存在最近添加中
    if (version >= 800 && version <= 802) {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumRecentlyAdded;
    } else {
        return ((PHAssetCollection *)metadata).assetCollectionSubtype == PHAssetCollectionSubtypeSmartAlbumUserLibrary;
    }
}

/// 检查照片大小是否满足最小要求
- (BOOL)isPhotoSelectableWithAsset:(PHAsset *)asset {
    CGSize photoSize = CGSizeMake(asset.pixelWidth, asset.pixelHeight);
    if (self.minPhotoWidthSelectable > photoSize.width || self.minPhotoHeightSelectable > photoSize.height) {
        return NO;
    }
    return YES;
}

#pragma mark - Private Method

- (SPAlbumModel *)modelWithResult:(PHFetchResult *)result name:(NSString *)name isCameraRoll:(BOOL)isCameraRoll needFetchAssets:(BOOL)needFetchAssets {
    SPAlbumModel *model = [[SPAlbumModel alloc] init];
    [model setResult:result needFetchAssets:needFetchAssets];
    model.name = name;
    model.isCameraRoll = isCameraRoll;
    model.count = result.count;
    return model;
}

/// 缩放图片至新尺寸
- (UIImage *)scaleImage:(UIImage *)image toSize:(CGSize)size {
    if (image.size.width > size.width) {
        UIGraphicsBeginImageContext(size);
        [image drawInRect:CGRectMake(0, 0, size.width, size.height)];
        UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
        UIGraphicsEndImageContext();
        return newImage;
        
        /* 好像不怎么管用：https://mp.weixin.qq.com/s/CiqMlEIp1Ir2EJSDGgMooQ
        CGFloat maxPixelSize = MAX(size.width, size.height);
        CGImageSourceRef sourceRef = CGImageSourceCreateWithData((__bridge CFDataRef)UIImageJPEGRepresentation(image, 0.9), nil);
        NSDictionary *options = @{(__bridge id)kCGImageSourceCreateThumbnailFromImageAlways:(__bridge id)kCFBooleanTrue,
                                  (__bridge id)kCGImageSourceThumbnailMaxPixelSize:[NSNumber numberWithFloat:maxPixelSize]
                                  };
        CGImageRef imageRef = CGImageSourceCreateImageAtIndex(sourceRef, 0, (__bridge CFDictionaryRef)options);
        UIImage *newImage = [UIImage imageWithCGImage:imageRef scale:2 orientation:image.imageOrientation];
        CGImageRelease(imageRef);
        CFRelease(sourceRef);
        return newImage;
         */
    } else {
        return image;
    }
}

/// 判断asset是否是视频
- (BOOL)isVideo:(PHAsset *)asset {
    return asset.mediaType == PHAssetMediaTypeVideo;
}

- (SPAssetModel *)createModelWithAsset:(PHAsset *)asset {
    SPAssetModelMediaType type = [[SPImageManager manager] getAssetType:asset];
    NSString *timeLength = type == SPAssetModelMediaTypeVideo ? [NSString stringWithFormat:@"%0.0f",asset.duration] : @"";
    timeLength = [[SPImageManager manager] getNewTimeFromDurationSecond:timeLength.integerValue];
    SPAssetModel *model = [SPAssetModel modelWithAsset:asset type:type timeLength:timeLength];
    return model;
}

/// 获取优化后的视频转向信息
- (AVMutableVideoComposition *)fixedCompositionWithAsset:(AVAsset *)videoAsset {
    AVMutableVideoComposition *videoComposition = [AVMutableVideoComposition videoComposition];
    // 视频转向
    int degrees = [self degressFromVideoFileWithAsset:videoAsset];
    if (degrees != 0) {
        CGAffineTransform translateToCenter;
        CGAffineTransform mixedTransform;
        videoComposition.frameDuration = CMTimeMake(1, 30);
        
        NSArray *tracks = [videoAsset tracksWithMediaType:AVMediaTypeVideo];
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        
        AVMutableVideoCompositionInstruction *roateInstruction = [AVMutableVideoCompositionInstruction videoCompositionInstruction];
        roateInstruction.timeRange = CMTimeRangeMake(kCMTimeZero, [videoAsset duration]);
        AVMutableVideoCompositionLayerInstruction *roateLayerInstruction = [AVMutableVideoCompositionLayerInstruction videoCompositionLayerInstructionWithAssetTrack:videoTrack];
        
        if (degrees == 90) {
            // 顺时针旋转90°
            translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.height, 0.0);
            mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI_2);
            videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height,videoTrack.naturalSize.width);
            [roateLayerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
        } else if(degrees == 180){
            // 顺时针旋转180°
            translateToCenter = CGAffineTransformMakeTranslation(videoTrack.naturalSize.width, videoTrack.naturalSize.height);
            mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI);
            videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.width,videoTrack.naturalSize.height);
            [roateLayerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
        } else if(degrees == 270){
            // 顺时针旋转270°
            translateToCenter = CGAffineTransformMakeTranslation(0.0, videoTrack.naturalSize.width);
            mixedTransform = CGAffineTransformRotate(translateToCenter,M_PI_2*3.0);
            videoComposition.renderSize = CGSizeMake(videoTrack.naturalSize.height,videoTrack.naturalSize.width);
            [roateLayerInstruction setTransform:mixedTransform atTime:kCMTimeZero];
        }
        
        roateInstruction.layerInstructions = @[roateLayerInstruction];
        // 加入视频方向信息
        videoComposition.instructions = @[roateInstruction];
    }
    return videoComposition;
}

/// 获取视频角度
- (int)degressFromVideoFileWithAsset:(AVAsset *)asset {
    int degress = 0;
    NSArray *tracks = [asset tracksWithMediaType:AVMediaTypeVideo];
    if([tracks count] > 0) {
        AVAssetTrack *videoTrack = [tracks objectAtIndex:0];
        CGAffineTransform t = videoTrack.preferredTransform;
        if(t.a == 0 && t.b == 1.0 && t.c == -1.0 && t.d == 0){
            // Portrait
            degress = 90;
        } else if(t.a == 0 && t.b == -1.0 && t.c == 1.0 && t.d == 0){
            // PortraitUpsideDown
            degress = 270;
        } else if(t.a == 1.0 && t.b == 0 && t.c == 0 && t.d == 1.0){
            // LandscapeRight
            degress = 0;
        } else if(t.a == -1.0 && t.b == 0 && t.c == 0 && t.d == -1.0){
            // LandscapeLeft
            degress = 180;
        }
    }
    return degress;
}

/// 修正图片转向
- (UIImage *)fixOrientation:(UIImage *)aImage {
    if (!self.shouldFixOrientation) return aImage;
    
    // No-op if the orientation is already correct
    if (aImage.imageOrientation == UIImageOrientationUp)
        return aImage;
    
    // We need to calculate the proper transformation to make the image upright.
    // We do it in 2 steps: Rotate if Left/Right/Down, and then flip if Mirrored.
    CGAffineTransform transform = CGAffineTransformIdentity;
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationDown:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, aImage.size.height);
            transform = CGAffineTransformRotate(transform, M_PI);
            break;
            
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformRotate(transform, M_PI_2);
            break;
            
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, 0, aImage.size.height);
            transform = CGAffineTransformRotate(transform, -M_PI_2);
            break;
        default:
            break;
    }
    
    switch (aImage.imageOrientation) {
        case UIImageOrientationUpMirrored:
        case UIImageOrientationDownMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.width, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
            
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRightMirrored:
            transform = CGAffineTransformTranslate(transform, aImage.size.height, 0);
            transform = CGAffineTransformScale(transform, -1, 1);
            break;
        default:
            break;
    }
    
    // Now we draw the underlying CGImage into a new context, applying the transform
    // calculated above.
    CGContextRef ctx = CGBitmapContextCreate(NULL, aImage.size.width, aImage.size.height,
                                             CGImageGetBitsPerComponent(aImage.CGImage), 0,
                                             CGImageGetColorSpace(aImage.CGImage),
                                             CGImageGetBitmapInfo(aImage.CGImage));
    CGContextConcatCTM(ctx, transform);
    switch (aImage.imageOrientation) {
        case UIImageOrientationLeft:
        case UIImageOrientationLeftMirrored:
        case UIImageOrientationRight:
        case UIImageOrientationRightMirrored:
            // Grr...
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.height,aImage.size.width), aImage.CGImage);
            break;
            
        default:
            CGContextDrawImage(ctx, CGRectMake(0,0,aImage.size.width,aImage.size.height), aImage.CGImage);
            break;
    }
    
    // And now we just create a new UIImage from the drawing context
    CGImageRef cgimg = CGBitmapContextCreateImage(ctx);
    UIImage *img = [UIImage imageWithCGImage:cgimg];
    CGContextRelease(ctx);
    CGImageRelease(cgimg);
    return img;
}

#pragma clang diagnostic pop

@end


//@implementation SPSortDescriptor
//
//- (id)reversedSortDescriptor {
//    return [NSNumber numberWithBool:![SPImageManager manager].sortAscendingByModificationDate];
//}
//
//@end