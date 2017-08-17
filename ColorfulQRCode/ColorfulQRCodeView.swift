//
//  ColorfulQRCodeView.swift
//  ColorfulQRCode
//
//  Created by wang yang on 2017/8/15.
//  Copyright © 2017年 ocean. All rights reserved.
//

import UIKit

class ColorfulQRCodeView: UIView {
    lazy var maskLayer: CALayer = {
        let _maskLayer = CALayer.init()
        self.layer.addSublayer(_maskLayer)
        return _maskLayer
    }()
    
    lazy var gradientLayer: CAGradientLayer = {
        let layer = CAGradientLayer.init()
        layer.colors = [
            UIColor.init(red: 0x2a / 255.0, green: 0x9c / 255.0, blue: 0x1f / 255.0, alpha: 1.0).cgColor,
            UIColor.init(red: 0xe6 / 255.0, green: 0xcd / 255.0, blue: 0x27 / 255.0, alpha: 1.0).cgColor,
            UIColor.init(red: 0xe6 / 255.0, green: 0x27 / 255.0, blue: 0x57 / 255.0, alpha: 1.0).cgColor
        ]
        self.layer.addSublayer(layer)
        layer.frame = self.bounds
        return layer
    }()
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.backgroundColor = UIColor.white
    }
    
    func syncFrame() {
        self.maskLayer.frame = self.bounds
        self.gradientLayer.frame = self.bounds
    }

    // 设置黑白二维码图片
    func setQRCodeImage(qrcodeImage: UIImage) {
        let imageMask = genQRCodeImageMask(grayScaleQRCodeImage: qrcodeImage)
        maskLayer.contents = imageMask
        maskLayer.frame = self.bounds
        self.gradientLayer.mask = maskLayer
    }
    
    private func genQRCodeImageMask(grayScaleQRCodeImage: UIImage?) -> CGImage? {
        if let image = grayScaleQRCodeImage {
            let bitsPerComponent = 8
            let bytesPerPixel = 4
            let width:Int = Int(image.size.width)
            let height:Int = Int(image.size.height)
            let imageData = UnsafeMutableRawPointer.allocate(bytes: Int(width * height * bytesPerPixel), alignedTo: 8)
            
            // 将原始黑白二维码图片绘制到像素格式为ARGB的图片上，绘制后的像素数据在imageData中。
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            let imageContext = CGContext.init(data: imageData, width: Int(image.size.width), height: Int(image.size.height), bitsPerComponent: bitsPerComponent, bytesPerRow: width * bytesPerPixel, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedFirst.rawValue )
            UIGraphicsPushContext(imageContext!)
            imageContext?.translateBy(x: 0, y: CGFloat(height))
            imageContext?.scaleBy(x: 1, y: -1)
            image.draw(in: CGRect.init(x: 0, y: 0, width: width, height: height))
            UIGraphicsPopContext()
            
            // 根据每个像素R通道的值修改Alpha通道的值，当Red大于100，则将Alpha置为0，反之置为255
            for row in 0..<height {
                for col in 0..<width {
                    let offset = row * width * bytesPerPixel + col * bytesPerPixel
                    let r = imageData.load(fromByteOffset: offset + 1, as: UInt8.self)
                    let alpha:UInt8 = r > 100 ? 0 : 255
                    imageData.storeBytes(of: alpha, toByteOffset: offset, as: UInt8.self)
                }
            }
            
            return imageContext?.makeImage()
        }
        return nil
    }
}
