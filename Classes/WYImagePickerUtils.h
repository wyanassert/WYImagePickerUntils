#import <Foundation/Foundation.h>
#import <Photos/PhotosTypes.h>

@class PHAsset;
@class PHAssetCollection;
@class UIImage;
@class PHLivePhoto;

typedef void(^WYCollectionsBlock)(NSArray <PHAssetCollection *> *collections);
typedef void(^WYAssetsBlock)(NSArray <PHAsset *> *assets);
typedef void(^WYSingleAssetBlock)(PHAsset *asset);

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
@interface WYImagePickerUtils : NSObject

+ (void)fetchAllCollection:(WYCollectionsBlock)block;
+ (void)fetchCollectionOfRegularMode:(WYCollectionsBlock)block;
+ (void)fetchAllCollectionOfSubType:(PHAssetCollectionSubtype)subType completion:(WYCollectionsBlock)block;
+ (void)fetchAllCollectionOfSubType:(PHAssetCollectionSubtype)subType collectionsType:(PHAssetCollectionType)collectionsType completion:(WYCollectionsBlock)block;
+ (void)fetchAllAsset:(WYAssetsBlock)block;
+ (void)fetchFirstAssetForCollection:(PHAssetCollection *)collection completion:(WYSingleAssetBlock)block;
+ (void)fetchAssetForCollection:(PHAssetCollection *)collection completion:(WYAssetsBlock)block;
+ (IAAssetType)typeForAsset:(PHAsset *)asset;

+ (void)thumbnailForAsset:(PHAsset *)asset isHighQuality:(BOOL)isHighQuality handler:(void (^)(UIImage *thumbnail))handler;

@end


#pragma mark -
#pragma mark - IAPhoto
@interface WYImagePickerUtils (IAPhoto)

+ (void)imageForAsset:(PHAsset *)asset handler:(void (^)(UIImage *image))handler;
+ (void)originImageForAsset:(PHAsset *)asset handler:(void (^)(UIImage *image))handler;
//+ (void)livePhotoForAsset:(PHAsset *)asset andSize:(CGSize)size handler:(void (^)(PHLivePhoto *livePhoto))handler;

@end


#pragma mark -
#pragma mark - IAVideo
@interface WYImagePickerUtils (IAVideo)

+ (void)videoForAsset:(PHAsset *)asset handler:(void (^)(NSURL *avURL))handler;

@end
