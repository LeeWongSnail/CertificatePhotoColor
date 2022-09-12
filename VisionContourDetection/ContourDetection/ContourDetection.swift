//
//  ContourDetection.swift
//  VisionContourDetection
//
//  Created by LeeWong on 2022/7/21.
//

import Foundation
import Vision
import UIKit

class ContourDetection: NSObject {
    
    func detectPhoto(photo: UIImage) -> UIImage {
        
        let ciOriginImage = CIImage(cgImage: photo.cgImage!)
        
        let imageHandler = VNImageRequestHandler(ciImage: ciOriginImage, options: [:])
        let attensionRequest = VNGenerateObjectnessBasedSaliencyImageRequest { [weak self] request, error in
            if let err = error {
                print("发生了错误 \(err.localizedDescription)")
                return
            }
            if let result = request.results, result.count > 0,
               let observation = result.first as? VNSaliencyImageObservation {
                // 获取显著区域热力图 接下里对对该图进行边缘检测
                self?.heatMapProcess(pixelBuffer: observation.pixelBuffer, ciImage: ciOriginImage)
            }
        }
        
        do {
            try imageHandler.perform([attensionRequest])
        } catch {
            print(error.localizedDescription)
        }
        
        return photo
        
    }
    
    private func heatMapProcess(pixelBuffer: CVPixelBuffer, ciImage: CIImage) {
        let heatImge = CIImage(cvPixelBuffer: pixelBuffer)
        let contourRequest = VNDetectContoursRequest { [weak self] request, error in
            if let err = error {
                print("发生了错误 \(err.localizedDescription)")
                return
            }
            if let result = request.results, result.count > 0,
               let observation = result.first as? VNContoursObservation {
                let cxt = CIContext()
                let origin = cxt.createCGImage(ciImage, from: ciImage.extent)
                let _ = self?.drawContour(contourObv: observation, cgImage: nil, originImg: origin)
            }
            
        }
        contourRequest.revision = VNDetectContourRequestRevision1
        contourRequest.contrastAdjustment = 1.0
        contourRequest.detectsDarkOnLight = false
        contourRequest.maximumImageDimension = 512
        
        let handler = VNImageRequestHandler(ciImage: heatImge, options: [:])
        
        do {
            try handler.perform([contourRequest])
        } catch {
            print("\(error.localizedDescription)")
        }
    }
    
    private func drawContour(contourObv: VNContoursObservation, cgImage: CGImage?, originImg: CGImage?) {
        
    }
    
    
    public func drawContours(contoursObservation: VNContoursObservation, sourceImage: CGImage) -> UIImage {
            let size = CGSize(width: sourceImage.width, height: sourceImage.height)
            let renderer = UIGraphicsImageRenderer(size: size)

            let renderedImage = renderer.image { (context) in
            let renderingContext = context.cgContext

            let flipVertical = CGAffineTransform(a: 1, b: 0, c: 0, d: -1, tx: 0, ty: size.height)
            renderingContext.concatenate(flipVertical)

            renderingContext.draw(sourceImage, in: CGRect(x: 0, y: 0, width: size.width, height: size.height))

            renderingContext.scaleBy(x: size.width, y: size.height)
            renderingContext.setLineWidth(5.0 / CGFloat(size.width))
            let redUIColor = UIColor.red
            renderingContext.setStrokeColor(redUIColor.cgColor)
            renderingContext.addPath(contoursObservation.normalizedPath)
            renderingContext.strokePath()
            }

            return renderedImage
        }
    
}
