//
//  CropImageManager.h
//  VisionContourDetection
//
//  Created by LeeWong on 2022/7/25.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CropImageManager : NSObject
@property (nonatomic, copy) void (^cropImageBlock)(UIImage *image);
- (void)saliencyFromOriginImage:(UIImage *)originImage;
- (UIImage *)removeColorWithMaxR:(float)maxR minR:(float)minR maxG:(float)maxG minG:(float)minG maxB:(float)maxB minB:(float)minB image:(UIImage *)image;
- (UIImage*) imageToTransparent:(UIImage*) image;
@end

NS_ASSUME_NONNULL_END
