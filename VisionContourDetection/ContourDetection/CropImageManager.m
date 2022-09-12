//
//  CropImageManager.m
//  VisionContourDetection
//
//  Created by LeeWong on 2022/7/25.
//

#import "CropImageManager.h"
#import <Vision/Vision.h>

@interface CropImageManager ()
@property (nonatomic, strong) CIImage *originCIImage;
@end

@implementation CropImageManager

- (void)saliencyFromOriginImage:(UIImage *)originImage {
    
    CIImage *ciOriginImg = [CIImage imageWithCGImage:originImage.CGImage];//原始图片
    self.originCIImage = ciOriginImg;

    VNImageRequestHandler *imageHandler = [[VNImageRequestHandler alloc]

                                               initWithCIImage:ciOriginImg
                                                        options:nil];
                                                        
    VNGenerateObjectnessBasedSaliencyImageRequest *attensionRequest = [[VNGenerateObjectnessBasedSaliencyImageRequest alloc] init];//基于物体的显著性区域检测请求
    NSError *err = nil;
    BOOL haveAttension =  [imageHandler performRequests:@[attensionRequest] error:&err];//有物品
    if ( haveAttension ) {//有物品
         if(attensionRequest.results && [attensionRequest.results count] > 0) {
          VNSaliencyImageObservation *observation = [attensionRequest.results firstObject];
                //获取显著区域热力图，接下来对该图进行边缘检测
                [self heatMapProcess:observation.pixelBuffer catOrigin:ciOriginImg];
           }
     }

}

- (void)heatMapProcess:(CVPixelBufferRef *)hotRef catOrigin:(CIImage *)catOrigin {
    CIImage *heatImage  = [CIImage imageWithCVPixelBuffer:hotRef];
    VNDetectContoursRequest *contourRequest = [[VNDetectContoursRequest alloc] init];
    contourRequest.revision = VNDetectContourRequestRevision1;
    contourRequest.contrastAdjustment = 1.0;
    contourRequest.detectDarkOnLight = NO;
    contourRequest.maximumImageDimension = 512;
    VNImageRequestHandler *handler = [[VNImageRequestHandler alloc] initWithCIImage:heatImage options:nil];
    NSError *err = nil;

    BOOL result = [handler performRequests:@[contourRequest] error:&err];

    if(result) {

         VNContoursObservation *contoursObv = [contourRequest.results firstObject];

         CIContext *cxt = [[CIContext alloc] initWithOptions:nil];
        
         CGImageRef origin = [cxt createCGImage:catOrigin
                                       fromRect:catOrigin.extent];
                                       //抠图
         UIImage *clipImage = [self drawContourWith:contoursObv
                                             withCgImg:nil
                                             originImg:origin];
        if (self.cropImageBlock) {
            self.cropImageBlock(clipImage);
        }
         
                                       
    }
}


- (UIImage *)drawContourWith:(VNContoursObservation *)contourObv

                   withCgImg:(CGImageRef)img

                   originImg:(CGImageRef)origin{

    CGSize size = CGSizeMake(CGImageGetWidth(origin), CGImageGetHeight(origin));

    UIImageView *originImgV = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, size.width, size.height)];

    originImgV.image = [UIImage imageWithCGImage:origin];

    CAShapeLayer *layer = [CAShapeLayer layer];

    CGAffineTransform flipMatrix =  CGAffineTransformMake(1, 0, 0, -1, 0, size.height);//坐标转换为底部为（0， 0）

    CGAffineTransform scaleTranform = CGAffineTransformScale(flipMatrix, size.width, size.height); //对path 进行按图尺寸放大

    CGPathRef scaedPath = CGPathCreateCopyByTransformingPath(contourObv.normalizedPath, &scaleTranform);//对归一化的path进行变换

    layer.path = scaedPath;

    [originImgV.layer setMask:layer];

    UIGraphicsBeginImageContext(originImgV.bounds.size);

    [originImgV.layer renderInContext:UIGraphicsGetCurrentContext()];

    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();

    UIGraphicsEndImageContext();

    //对于扣出来的主要内容进行截取

    //原数据放大的范围是ui的

    CGAffineTransform originScale = CGAffineTransformMakeScale(size.width, size.height);

    CGPathRef originScalePath = CGPathCreateCopyByTransformingPath(contourObv.normalizedPath, &originScale);//归一化的path进行还原，并拿到在图中位置的框

    CGRect targetReact = CGPathGetBoundingBox(originScalePath);
    
    CIImage *getBoundImage = [[CIImage alloc] initWithImage:image];

    CIImage *targetBoundImg = [getBoundImage imageByCroppingToRect:targetReact];//截取范围的图片

//    CIImage *cropImg = [self.originCIImage imageByCroppingToRect:normalRect];

    return [UIImage imageWithCIImage:targetBoundImg];
    
}

- (UIImage *)removeColorWithMaxR:(float)maxR minR:(float)minR maxG:(float)maxG minG:(float)minG maxB:(float)maxB minB:(float)minB image:(UIImage *)image {
const CGFloat myMaskingColors[6] = {minR, maxR,  minG, maxG, minB, maxB};
CGImageRef ref = CGImageCreateWithMaskingColors(image.CGImage, myMaskingColors);
return [UIImage imageWithCGImage:ref];
}

//颜色替换

- (UIImage*) imageToTransparent:(UIImage*) image
{
    // 分配内存

    const int imageWidth = image.size.width;

    const int imageHeight = image.size.height;

    size_t      bytesPerRow = imageWidth * 4;

    uint32_t* rgbImageBuf = (uint32_t*)malloc(bytesPerRow * imageHeight);


    // 创建context

    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();

    CGContextRef context = CGBitmapContextCreate(rgbImageBuf, imageWidth, imageHeight, 8, bytesPerRow, colorSpace,

                                                 kCGBitmapByteOrder32Little | kCGImageAlphaNoneSkipLast);

    CGContextDrawImage(context, CGRectMake(0, 0, imageWidth, imageHeight), image.CGImage);


    // 遍历像素

    int pixelNum = imageWidth * imageHeight;

    uint32_t* pCurPtr = rgbImageBuf;

    for (int i = 0; i < pixelNum; i++, pCurPtr++)

    {
        //把绿色变成黑色，把背景色变成透明

        if ((*pCurPtr & 0x65815A00) == 0x65815a00)    // 将背景变成透明

        {
            uint8_t* ptr = (uint8_t*)pCurPtr;

            ptr[0] = 0;

        }

        else if ((*pCurPtr & 0x00FF0000) == 0x00ff0000)    // 将绿色变成黑色

        {
            uint8_t* ptr = (uint8_t*)pCurPtr;

            ptr[3] = 0; //0~255

            ptr[2] = 0;

            ptr[1] = 0;

        }

        else if ((*pCurPtr & 0xFFFFFF00) == 0xffffff00)    // 将白色变成透明

        {
            uint8_t* ptr = (uint8_t*)pCurPtr;

            ptr[0] = 0;

        }

        else

        {
            // 改成下面的代码，会将图片转成想要的颜色

            uint8_t* ptr = (uint8_t*)pCurPtr;

            ptr[3] = 0; //0~255

            ptr[2] = 0;

            ptr[1] = 0;

        }


    }


    // 将内存转成image

    CGDataProviderRef dataProvider = CGDataProviderCreateWithData(NULL, rgbImageBuf, bytesPerRow * imageHeight, ProviderReleaseData);

    CGImageRef imageRef = CGImageCreate(imageWidth, imageHeight, 8, 32, bytesPerRow, colorSpace,

                                        kCGImageAlphaLast | kCGBitmapByteOrder32Little, dataProvider,

                                        NULL, true, kCGRenderingIntentDefault);

    CGDataProviderRelease(dataProvider);


    UIImage* resultUIImage = [UIImage imageWithCGImage:imageRef];


    // 释放

    CGImageRelease(imageRef);

    CGContextRelease(context);

    CGColorSpaceRelease(colorSpace);

    // free(rgbImageBuf) 创建dataProvider时已提供释放函数，这里不用free

    

    return resultUIImage;

}



/** 颜色变化 */

void ProviderReleaseData (void *info, const void *data, size_t size)

{
    free((void*)data);

}

@end
