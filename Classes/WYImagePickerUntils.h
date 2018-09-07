#import <Foundation/Foundation.h>

@class PHAsset;
@class PHAssetCollection;
@class UIImage;
@class PHLivePhoto;

extern NSString *const IAPHAuthorizationStatusNotification;

typedef NS_OPTIONS(NSInteger, IAAssetType) {
    IAAssetTypeUnknown   = 1,
    IAAssetTypePhoto     = 1 << 1,
    IAAssetTypeVideo     = 1 << 2,
    IAAssetTypeLivePhoto = 1 << 3,
    IAAssetTypeAll       = IAAssetTypePhoto | IAAssetTypeVideo | IAAssetTypeLivePhoto
};


#pragma mark -
#pragma mark -
@interface WYImagePickerUntils : NSObject

+ (NSArray <PHAssetCollection *> *)fetchAllCollection;
+ (NSArray <PHAsset *> *)fetchAllAsset;
+ (PHAsset *)fetchFirstAssetForCollection:(PHAssetCollection *)collection;
+ (NSArray <PHAsset *>*)fetchAssetForCollection:(PHAssetCollection *)collection;
+ (IAAssetType)typeForAsset:(PHAsset *)asset;

+ (void)thumbnailForAsset:(PHAsset *)asset isHighQuality:(BOOL)isHighQuality handler:(void (^)(UIImage *thumbnail))handler;

@end


#pragma mark -
#pragma mark - IAPhoto
@interface WYImagePickerUntils (IAPhoto)

+ (void)imageForAsset:(PHAsset *)asset handler:(void (^)(UIImage *image))handler;
+ (void)originImageForAsset:(PHAsset *)asset handler:(void (^)(UIImage *image))handler;
//+ (void)livePhotoForAsset:(PHAsset *)asset andSize:(CGSize)size handler:(void (^)(PHLivePhoto *livePhoto))handler;

@end


#pragma mark -
#pragma mark - IAVideo
@interface WYImagePickerUntils (IAVideo)

+ (void)videoForAsset:(PHAsset *)asset handler:(void (^)(NSURL *avURL))handler;

@end
