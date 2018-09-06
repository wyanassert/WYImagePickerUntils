#import "WYImagePickerUntils.h"
#import <Photos/Photos.h>

NSString *const IAPHAuthorizationStatusNotification = @"kIAPHAuthorizationStatusNotification";


#pragma mark -
#pragma mark -
@implementation WYImagePickerUntils
+ (NSArray <PHAssetCollection *> *)fetchAllCollection {
    if (![self canAccessPhoto]) {
        return nil;
    }
    
    NSMutableArray <PHAssetCollection *> *collectionArray = [NSMutableArray array];
    PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:PHAssetCollectionTypeSmartAlbum
                                                                          subtype:PHAssetCollectionSubtypeSmartAlbumUserLibrary
                                                                          options:nil];
    if (smartAlbums.count > 0) {
        [smartAlbums enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[PHAssetCollection class]]) {
                PHAssetCollection *collection = obj;
                PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:collection
                                                                      options:nil];
                if (assets.count > 0) {
                    [collectionArray addObject:collection];
                }
            }
        }];
    }
    
    PHFetchResult *topLevelUserCollections = [PHCollectionList fetchTopLevelUserCollectionsWithOptions:nil];
    if (topLevelUserCollections.count > 0) {
        [topLevelUserCollections enumerateObjectsUsingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
            if ([obj isKindOfClass:[PHAssetCollection class]]) {
                PHAssetCollection *collection = obj;
                PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:collection
                                                                      options:nil];
                if (assets.count > 0) {
                    [collectionArray addObject:collection];
                }
            }
        }];
    }
    
    return collectionArray;
}

+ (NSArray <PHAsset *> *)fetchAllAsset {
    if (![self canAccessPhoto]) {
        return nil;
    }
    
    NSMutableArray <PHAsset *> *albumAllAssets = [NSMutableArray array];
    
    PHFetchOptions *options = [[PHFetchOptions alloc] init];
    options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate"
                                                              ascending:NO]];
    PHFetchResult *assets = [PHAsset fetchAssetsWithOptions:options];
    if (assets.count > 0) {
        for (PHAsset *asset in assets) {
            [albumAllAssets addObject:asset];
        }
    }
    
    return albumAllAssets;
}

+ (PHAsset *)fetchFirstAssetForCollection:(PHAssetCollection *)collection {
    if ([self canAccessPhoto] && collection) {
        
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate"
                                                                      ascending:NO]];
            PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            if (assets.count > 0) {
                return (PHAsset *)assets.firstObject;
            }
        }

        return nil;
    }
    
    return nil;
}

+ (NSArray <PHAsset *>*)fetchAssetForCollection:(PHAssetCollection *)collection {
    if ([self canAccessPhoto] && collection) {
        NSMutableArray <PHAsset *> *albumAssets = [NSMutableArray array];
        
        if ([collection isKindOfClass:[PHAssetCollection class]]) {
            PHFetchOptions *options = [[PHFetchOptions alloc] init];
            options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate"
                                                                      ascending:NO]];
            PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:collection options:options];
            if (assets.count > 0) {
                for (PHAsset *asset in assets) {
                    if (asset.mediaType == PHAssetMediaTypeImage) {
                        [albumAssets addObject:asset];
                    }
                }
            }
        }
        
        return albumAssets;
    }
    
    return nil;
}

+ (IAAssetType)typeForAsset:(PHAsset *)asset {
    PHAssetMediaType type = asset.mediaType;
    
    if (PHAssetMediaTypeVideo == type) {
        return IAAssetTypeVideo;
    } else if (PHAssetMediaTypeImage == type){
        return IAAssetTypePhoto;
    } else {
        return IAAssetTypeUnknown;
    }
}

+ (void)thumbnailForAsset:(PHAsset *)asset isHighQuality:(BOOL)isHighQuality handler:(void (^)(UIImage *thumbnail))handler {
    if ([self canAccessPhoto] && asset) {
        CGSize size = isHighQuality ? CGSizeMake(200.f, 200.f) : CGSizeMake(40.f, 40.f);
        PHImageContentMode contentMode = PHImageContentModeAspectFill;
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        requestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
        requestOptions.networkAccessAllowed = YES;
        requestOptions.synchronous = YES;
        [[PHImageManager defaultManager] requestImageForAsset:asset
                                                   targetSize:size
                                                  contentMode:contentMode
                                                      options:requestOptions
                                                resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                    if (handler) {
                                                        handler(result);
                                                    }
                                                }];
    }
}

+ (BOOL)canAccessPhoto {
    PHAuthorizationStatus authStatusA = [PHPhotoLibrary authorizationStatus];
    if (PHAuthorizationStatusNotDetermined == authStatusA) {
        [PHPhotoLibrary requestAuthorization:^(PHAuthorizationStatus status) {
            [[NSNotificationCenter defaultCenter] postNotificationName:IAPHAuthorizationStatusNotification
                                                                object:@(status)];
        }];
        return NO;
    } else if (PHAuthorizationStatusAuthorized != authStatusA) {
        return NO;
    }
    
    return YES;
}

@end


#pragma mark -
#pragma mark - IAPhoto
@implementation WYImagePickerUntils (IAPhoto)
+ (void)imageForAsset:(PHAsset *)asset handler:(void (^)(UIImage *))handler {
    if ([self canAccessPhoto] && asset) {
        CGSize size;
        switch ((NSInteger)[UIScreen mainScreen].bounds.size.width) {
            case 320:
                size = CGSizeMake(320.f, 568.f);
            case 375:
                size = CGSizeMake(375.f, 667.f);
            case 414:
                size =  CGSizeMake(414.f, 736.f);
            case 768:
            default:
                size =  CGSizeMake(768.f, 1024.f);
        }
        PHImageContentMode contentMode = PHImageContentModeAspectFit;
        PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
        [requestOptions setResizeMode:PHImageRequestOptionsResizeModeExact];
        [requestOptions setNetworkAccessAllowed:YES];
        [requestOptions setSynchronous:YES];
        [[PHImageManager defaultManager] requestImageForAsset:asset
                                                   targetSize:size
                                                  contentMode:contentMode
                                                      options:requestOptions
                                                resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                                                    if (handler) {
                                                        handler(result);
                                                    }
                                                }];
    }
}

//+ (void)livePhotoForAsset:(PHAsset *)asset andSize:(CGSize)size handler:(void (^)(PHLivePhoto *))handler {
//    if ([self canAccessPhoto] && asset) {
//        PHLivePhotoRequestOptions *requestOptions = [[PHLivePhotoRequestOptions alloc] init];
//        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
//        requestOptions.networkAccessAllowed = YES;
//        [[PHImageManager defaultManager] requestLivePhotoForAsset:asset targetSize:size contentMode:PHImageContentModeAspectFit options:requestOptions resultHandler:^(PHLivePhoto * _Nullable livePhoto, NSDictionary * _Nullable info) {
//            
//            if (handler && livePhoto) {
//                handler(livePhoto);
//            }
//        }];
//    }
//}

@end


#pragma mark -
#pragma mark - IAVideo
@implementation WYImagePickerUntils (IAVideo)
+ (void)videoForAsset:(PHAsset *)asset handler:(void (^)(NSURL *))handler {
    if ([self canAccessPhoto] && asset) {
        PHVideoRequestOptions *requestOptions = [[PHVideoRequestOptions alloc] init];
        requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
        requestOptions.version = PHVideoRequestOptionsVersionOriginal;
        [[PHImageManager defaultManager] requestAVAssetForVideo:asset
                                                        options:requestOptions
                                                  resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                                                      if (handler && [asset isKindOfClass:[AVURLAsset class]]) {
                                                          AVURLAsset *avURLAsset = (AVURLAsset *)asset;
                                                          handler(avURLAsset.URL);
                                                      }
                                                  }];
    }
}

@end
