//
//  ViewController.swift
//  VisionContourDetection
//
//  Created by LeeWong on 2022/7/21.
//

import UIKit

class ViewController: UIViewController {

    let detection = ContourDetection()
    let manager = CropImageManager()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        getImageBackgroundColor()
    }
    
    
    func alphaImage() {
        let image = UIImage(named: "photo1")!
        imageView.image = manager.image(toTransparent: image)
    }
    
    func getImageBackgroundColor() {
        let image = UIImage(named: "photo1")!
        let size = image.size
        let leftTopColor = image.getPointColor(point: CGPoint(x: 1, y: 1))
        let rightTopColor = image.getPointColor(point: CGPoint(x: size.width - 1.0 , y: 1.0))
        if leftTopColor == rightTopColor {
            replaceBackground(color: leftTopColor!)
        } else {
            print("color not equal")
        }
    }
    
    func replaceImageBackgourndColor() {
        let image = UIImage(named: "photo1")
        manager.cropImageBlock = { [weak self] cropImage in
            self?.imageView.backgroundColor = UIColor.red
            self?.imageView.image = cropImage
        }
        manager.saliency(fromOriginImage: image!)
    }
    
    func removeBackgroundColor() {
        let image = UIImage(named: "photo1")!
        imageView.backgroundColor = .red
        imageView.image = manager.removeColor(withMaxR: 255, minR: 250, maxG: 255, minG: 250, maxB: 255, minB: 250, image: image)
        
    }
    
    func replaceBackground(color: UIColor) {
        let originImage = UIImage(named: "photo1")!
        imageView.image = originImage
            
        let backgroundImage = UIImage.imageWithColor(color: .red, size: CGSize(width: 60, height: 90))
        
        let hsvColor = color.hsba
        
        let cubeMap = createCubeMap(Float(hsvColor.0), Float(hsvColor.1), Float(hsvColor.2))
//        let cubeMap = createCubeMap(Float(originImage.size.width), Float(originImage.size.height), Float(hsvColor.0), Float(hsvColor.1), Float(hsvColor.2))
//        let cubeMap = createCubeMapWithHueRange(<#T##minHueAngle: Float##Float#>, <#T##maxHueAngle: Float##Float#>)
        let data = NSData(bytesNoCopy: cubeMap.data, length: Int(cubeMap.length), freeWhenDone: true)
        let colorCubeFilter = CIFilter(name: "CIColorCube")!
        
        colorCubeFilter.setValue(cubeMap.dimension, forKey: "inputCubeDimension")
        colorCubeFilter.setValue(data, forKey: "inputCubeData")
        colorCubeFilter.setValue(CIImage(image: imageView.image!), forKey: kCIInputImageKey)
        var outputImage = colorCubeFilter.outputImage!
        
        let sourceOverCompositingFilter = CIFilter(name: "CISourceOverCompositing")!
        sourceOverCompositingFilter.setValue(outputImage, forKey: kCIInputImageKey)
        sourceOverCompositingFilter.setValue(CIImage(image: backgroundImage), forKey: kCIInputBackgroundImageKey)

        outputImage = sourceOverCompositingFilter.outputImage!
        if let cgImage = context.createCGImage(outputImage, from: outputImage.extent) {
            imageView.image = UIImage(cgImage: cgImage)
        }
        
    }


    
    private lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.frame = CGRect(x: 0, y: 200, width: UIScreen.main.bounds.width, height: 300)
        view.addSubview(imageView)
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    lazy var context: CIContext = {
        let context = CIContext(options: nil)
        return context
    }()
}


extension UIImage {
    class func imageWithColor(color:UIColor,size:CGSize) -> UIImage {
        let rect = CGRect(x: 0, y: 0, width: size.width, height: size.height)
        UIGraphicsBeginImageContextWithOptions(rect.size, false, 0)
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(color.cgColor)
        context?.fill(rect)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image!
    }
    func getPointColor(point: CGPoint) -> UIColor? {

        guard CGRect(origin: CGPoint(x: 0, y: 0), size: size).contains(point) else {
            return nil
        }

        let pointX = trunc(point.x);
        let pointY = trunc(point.y);

        let width = size.width;
        let height = size.height;
        let colorSpace = CGColorSpaceCreateDeviceRGB();
        var pixelData: [UInt8] = [0, 0, 0, 0]

        pixelData.withUnsafeMutableBytes { pointer in
            if let context = CGContext(data: pointer.baseAddress, width: 1, height: 1, bitsPerComponent: 8, bytesPerRow: 4, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue), let cgImage = cgImage {
                context.setBlendMode(.copy)
                context.translateBy(x: -pointX, y: pointY - height)
                context.draw(cgImage, in: CGRect(x: 0, y: 0, width: width, height: height))
            }
        }

        let red = CGFloat(pixelData[0]) / CGFloat(255.0)
        let green = CGFloat(pixelData[1]) / CGFloat(255.0)
        let blue = CGFloat(pixelData[2]) / CGFloat(255.0)
        let alpha = CGFloat(pixelData[3]) / CGFloat(255.0)

        if #available(iOS 10.0, *) {
            return UIColor(displayP3Red: red, green: green, blue: blue, alpha: alpha)
        } else {
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
    }
    
}

extension UIColor {
    func colorToRGBA() -> (r: CGFloat?, g: CGFloat?, b: CGFloat?, a: CGFloat?) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        let multiplier = CGFloat(255.999999)
        
        guard self.getRed(&red, green: &green, blue: &blue, alpha: &alpha) else {
            return (nil, nil, nil, nil)
        }
        return (CGFloat(red * multiplier), CGFloat(green * multiplier), CGFloat(blue * multiplier), alpha)
    }
    
    var hsba: (hue: CGFloat, saturation: CGFloat, brightness: CGFloat, alpha: CGFloat) {
        /**
         hue：色相
         saturation：饱和度
         brightness：亮度
         alpha：透明度
         */
        var h: CGFloat = 0
        var s: CGFloat = 0
        var b: CGFloat = 0
        var a: CGFloat = 0
        self.getHue(&h, saturation: &s, brightness: &b, alpha: &a)
        return (h * 360, s, b, a)
    }
}
