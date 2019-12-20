#import "WYImagePickerUtils.h"
#import <Photos/Photos.h>
#import "WYUtils.h"

NSString *const IAPHAuthorizationStatusNotification = @"kIAPHAuthorizationStatusNotification";


#pragma mark -
#pragma mark -
@implementation WYImagePickerUtils

+ (void)fetchAllCollection:(WYCollectionsBlock)block {
    [WYImagePickerUtils fetchAllCollectionOfSubType:PHAssetCollectionSubtypeSmartAlbumUserLibrary completion:block];
}

+ (void)fetchCollectionOfRegularMode:(WYCollectionsBlock)block {
    [WYImagePickerUtils fetchAllCollectionOfSubType:PHAssetCollectionSubtypeSmartAlbumUserLibrary collectionsType:PHAssetCollectionTypeSmartAlbum completion:^(NSArray<PHAssetCollection *> *collections) {
        [WYImagePickerUtils fetchAllCollectionOfSubType:PHAssetCollectionSubtypeAlbumRegular collectionsType:PHAssetCollectionTypeAlbum completion:^(NSArray<PHAssetCollection *> *collections1) {
            NSMutableArray<PHAssetCollection *> *tmpMutableArray = [NSMutableArray array];
            [tmpMutableArray addObjectsFromArray:collections];
            [tmpMutableArray addObjectsFromArray:collections1];
            if(block) {
                block(tmpMutableArray.copy);
            }
        }];
    }];
}

+ (void)fetchAllCollectionOfSubType:(PHAssetCollectionSubtype)subType completion:(WYCollectionsBlock)block {
    [WYImagePickerUtils fetchAllCollectionOfSubType:subType collectionsType:PHAssetCollectionTypeSmartAlbum completion:block];
}

+ (void)fetchAllCollectionOfSubType:(PHAssetCollectionSubtype)subType collectionsType:(PHAssetCollectionType)collectionsType completion:(WYCollectionsBlock)block {
    if (![self canAccessPhoto]) {
        if(block) {
            block(@[]);
        }
        return;
    }

    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
        NSMutableArray <PHAssetCollection *> *collectionArray = [NSMutableArray array];
        PHFetchResult *smartAlbums = [PHAssetCollection fetchAssetCollectionsWithType:collectionsType subtype:subType options:nil];
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
        dispatch_async(dispatch_get_main_queue(), ^{
            if(block) {
                block(collectionArray);
            }
        });
    });
}

+ (void)fetchAllAsset:(WYAssetsBlock)block {
    if (![self canAccessPhoto]) {
        if(block) {
            block(@[]);
        }
        return;
    }
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
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
        dispatch_async(dispatch_get_main_queue(), ^{
            if(block) {
                block(albumAllAssets);
            }
        });
    });
}

+ (void)fetchFirstAssetForCollection:(PHAssetCollection *)collection completion:(WYSingleAssetBlock)block {
    if ([self canAccessPhoto] && collection) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            if ([collection isKindOfClass:[PHAssetCollection class]]) {
                PHFetchOptions *options = [[PHFetchOptions alloc] init];
                options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate"
                                                                          ascending:NO]];
                PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:collection options:options];
                dispatch_async(dispatch_get_main_queue(), ^{
                    if (assets.count > 0) {
                        if(block) {
                            block((PHAsset *)assets.firstObject);
                        }
                    } else {
                        if(block) {
                            block(nil);
                        }
                    }
                });
            }
        });
    } else {
        if(block) {
            block(nil);
        }
    }
}

+ (void)fetchAssetForCollection:(PHAssetCollection *)collection completion:(WYAssetsBlock)block {
    if ([self canAccessPhoto] && collection) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            NSMutableArray <PHAsset *> *albumAssets = [NSMutableArray array];

            if ([collection isKindOfClass:[PHAssetCollection class]]) {
                PHFetchOptions *options = [[PHFetchOptions alloc] init];
                options.sortDescriptors = @[[NSSortDescriptor sortDescriptorWithKey:@"creationDate"
                                                                          ascending:NO]];
                PHFetchResult *assets = [PHAsset fetchAssetsInAssetCollection:collection options:options];
                if (assets.count > 0) {
                    for (PHAsset *asset in assets) {
                        if (asset.mediaType == PHAssetMediaTypeImage || asset.mediaType == PHAssetMediaTypeVideo) {
                            [albumAssets addObject:asset];
                        }
                    }
                }
            }
            dispatch_async(dispatch_get_main_queue(), ^{
                if(block) {
                    block(albumAssets);
                }
            });
        });
    } else {
        if(block) {
            block(@[]);
        }
    }
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

+ (WYSyncToken *)thumbnailForAsset:(PHAsset *)asset isHighQuality:(BOOL)isHighQuality handler:(WYPickerResultBlock)handler {
    WYAsyncBlock asyncBlock = ^(WYSyncOperation * __nonnull operation, WYSyncCompletedBlock completeBlock) {
        if ([self canAccessPhoto] && asset) {
            CGSize size = isHighQuality ? CGSizeMake(200.f, 200.f) : CGSizeMake(40.f, 40.f);
            PHImageContentMode contentMode = PHImageContentModeAspectFill;
            PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
            requestOptions.resizeMode = PHImageRequestOptionsResizeModeFast;
            requestOptions.networkAccessAllowed = YES;
            requestOptions.synchronous = YES;
            [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:contentMode options:requestOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
                if(completeBlock) {
                    completeBlock(YES, asset.localIdentifier, result);
                }
            }];
        }
    };
    
    return [[WYSyncTaskManager sharedInstance] addAsyncTaskWithCompletion:asyncBlock taskIdentifier:[NSString stringWithFormat:@"%@-thumb", asset.localIdentifier] completeBlock:^(BOOL success, NSString * _Nonnull indexKey, id result) {
        if(success && indexKey.length && [result isKindOfClass:[UIImage class]]) {
            if(handler) {
                handler((UIImage *)result, asset.localIdentifier);
            }
        } else {
            if(handler) {
                handler(nil, asset.localIdentifier);
            }
        }
    }];
}

+ (void)cancelPickerTask:(WYSyncToken *)token {
    [[WYSyncTaskManager sharedInstance] cancelTaskForResource:token];
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
@implementation WYImagePickerUtils (IAPhoto)
+ (WYSyncToken *)imageForAsset:(PHAsset *)asset handler:(WYPickerResultBlock)handler {
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
        return [self imageForAsset:asset size:size handler:handler];
    } else {
        return nil;
    }
}

+ (WYSyncToken *)originImageForAsset:(PHAsset *)asset handler:(WYPickerResultBlock)handler {
    if ([self canAccessPhoto] && asset) {
        return [self imageForAsset:asset size:PHImageManagerMaximumSize handler:handler];
    } else {
        return nil;
    }
}

+ (WYSyncToken *)imageForAsset:(PHAsset *)asset size:(CGSize)size handler:(WYPickerResultBlock)handler {
    WYAsyncBlock asyncBlock = ^(WYSyncOperation * __nonnull operation, WYSyncCompletedBlock completeBlock) {
       PHImageContentMode contentMode = PHImageContentModeAspectFit;
       PHImageRequestOptions *requestOptions = [[PHImageRequestOptions alloc] init];
       [requestOptions setResizeMode:PHImageRequestOptionsResizeModeExact];
       [requestOptions setNetworkAccessAllowed:YES];
       [requestOptions setSynchronous:YES];
       [[PHImageManager defaultManager] requestImageForAsset:asset targetSize:size contentMode:contentMode options:requestOptions resultHandler:^(UIImage * _Nullable result, NSDictionary * _Nullable info) {
           if(completeBlock) {
               completeBlock(YES, asset.localIdentifier, result);
           }
       }];
    };
    
    return [[WYSyncTaskManager sharedInstance] addAsyncTaskWithCompletion:asyncBlock taskIdentifier:[NSString stringWithFormat:@"%@-%d-%d", asset.localIdentifier, (int)size.width, (int)size.height] completeBlock:^(BOOL success, NSString * _Nonnull indexKey, id result) {
        if(success && indexKey.length && [result isKindOfClass:[UIImage class]]) {
            if(handler) {
                handler((UIImage *)result, asset.localIdentifier);
            }
        } else {
            if(handler) {
                handler(nil, asset.localIdentifier);
            }
        }
    }];
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
@implementation WYImagePickerUtils (IAVideo)
+ (void)videoForAsset:(PHAsset *)asset handler:(void (^)(NSURL *))handler {
    if ([self canAccessPhoto] && asset) {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_HIGH, 0), ^{
            PHVideoRequestOptions *requestOptions = [[PHVideoRequestOptions alloc] init];
            requestOptions.deliveryMode = PHImageRequestOptionsDeliveryModeOpportunistic;
            requestOptions.version = PHVideoRequestOptionsVersionOriginal;
            [[PHImageManager defaultManager] requestAVAssetForVideo:asset
                                                            options:requestOptions
                                                      resultHandler:^(AVAsset * _Nullable asset, AVAudioMix * _Nullable audioMix, NSDictionary * _Nullable info) {
                                                          if (handler && [asset isKindOfClass:[AVURLAsset class]]) {
                                                              AVURLAsset *avURLAsset = (AVURLAsset *)asset;
                                                              dispatch_async(dispatch_get_main_queue(), ^{
                                                                  handler(avURLAsset.URL);
                                                              });
                                                          }
                                                      }];
        });
    }
}

@end

