//
//  ColorfulQRCodeMetalView.swift
//  ColorfulQRCode
//
//  Created by wang yang on 2017/8/15.
//  Copyright © 2017年 ocean. All rights reserved.
//

import UIKit
import Metal
import MetalKit

class ColorfulQRCodeMetalView: UIView {
    var device: MTLDevice! = nil
    
    var commandQueue: MTLCommandQueue! = nil
    var pipelineState: MTLRenderPipelineState! = nil
    var pipelineStateDescriptor: MTLRenderPipelineDescriptor! = nil;
    
    var metalLayer: CAMetalLayer!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        initMetal()
        initPipline()
    }
    
    // 设置黑白二维码图片
    func setQRCodeImage(qrcodeImage: UIImage) {
        if let qrcodeTexture = createQRCodeTexture(qrcodeImage: qrcodeImage) {
            render(qrcodeTexture: qrcodeTexture)
        }
    }
    
    // 同步layer的大小
    func syncFrame() {
        self.metalLayer.frame = self.bounds
    }
    
    // 使用qrcode图片创建纹理
    func createQRCodeTexture(qrcodeImage: UIImage) -> MTLTexture? {
        let bitsPerComponent = 8
        let bytesPerPixel = 4
        let width:Int = Int(qrcodeImage.size.width)
        let height:Int = Int(qrcodeImage.size.height)
        let imageData = UnsafeMutableRawPointer.allocate(bytes: Int(width * height * bytesPerPixel), alignedTo: 8)
        
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let imageContext = CGContext.init(data: imageData, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: width * bytesPerPixel, space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.order32Big.rawValue )
        UIGraphicsPushContext(imageContext!)
        imageContext?.translateBy(x: 0, y: CGFloat(height))
        imageContext?.scaleBy(x: 1, y: -1)
        qrcodeImage.draw(in: CGRect.init(x: 0, y: 0, width: width, height: height))
        UIGraphicsPopContext()
        
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .rgba8Unorm, width: width, height: height, mipmapped: false)
        descriptor.usage = .shaderRead
        let texture = device.makeTexture(descriptor: descriptor)
        texture?.replace(region: MTLRegionMake2D(0, 0, width, height), mipmapLevel: 0, withBytes: imageData, bytesPerRow: width * bytesPerPixel)
        return texture
    }
    
    // 绘制一个2x2的矩形，将二维码纹理绑定到index 0处，将渐变色colors和渐变色个数传入fragment shader处理方法里。
    func draw(renderEncoder: MTLRenderCommandEncoder, qrcodeTexture: MTLTexture) {
        let squareData: [Float] = [
            -1,   1,    0.0, 0, 0,
            -1,   -1,   0.0, 0, 1,
            1,    -1,   0.0, 1, 1,
            1,    -1,   0.0, 1, 1,
            1,    1,    0.0, 1, 0,
            -1,   1,    0.0, 0, 0
        ]
        let vertexBufferSize = MemoryLayout<Float>.size * squareData.count
        let vertexBuffer = device.makeBuffer(bytes: squareData, length: vertexBufferSize, options: MTLResourceOptions.cpuCacheModeWriteCombined)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(qrcodeTexture, index: 0)
        
        let colors: [Float] = [
            0x2a / 255.0, 0x9c / 255.0, 0x1f / 255.0,
            0xe6 / 255.0, 0xcd / 255.0, 0x27 / 255.0,
            0xe6 / 255.0, 0x27 / 255.0, 0x57 / 255.0
        ]
        let colorsBufferSize = MemoryLayout<Float>.size * colors.count
        let colorsBuffer = device.makeBuffer(bytes: colors, length: colorsBufferSize, options: MTLResourceOptions.cpuCacheModeWriteCombined)
        renderEncoder.setFragmentBuffer(colorsBuffer, offset: 0, index: 0)
        
        let uniform: [Int] = [colors.count / 3]
        let uniformBufferSize = MemoryLayout<Int>.size * uniform.count
        let uniformBuffer = device.makeBuffer(bytes: uniform, length: uniformBufferSize, options: MTLResourceOptions.cpuCacheModeWriteCombined)
        renderEncoder.setFragmentBuffer(uniformBuffer, offset: 0, index: 1)
        
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
    
    // MARK: Metal相关方法
    func initMetal() {
        device = MTLCreateSystemDefaultDevice()
        guard device != nil else {
            print("Metal is not supported on this device")
            return
        }
        
        metalLayer = CAMetalLayer()
        metalLayer.device = device
        metalLayer.pixelFormat = .bgra8Unorm
        metalLayer.framebufferOnly = true
        metalLayer.frame = self.bounds
        self.layer.addSublayer(metalLayer)
    }
    
    func initPipline() {
        commandQueue = device.makeCommandQueue()
        commandQueue.label = "main metal command queue"
        
        let defaultLibrary = device.makeDefaultLibrary()!
        let fragmentProgram = defaultLibrary.makeFunction(name: "passThroughFragment")!
        let vertexProgram = defaultLibrary.makeFunction(name: "passThroughVertex")!
        
        self.pipelineStateDescriptor = MTLRenderPipelineDescriptor()
        pipelineStateDescriptor.vertexFunction = vertexProgram
        pipelineStateDescriptor.fragmentFunction = fragmentProgram
        pipelineStateDescriptor.colorAttachments[0].pixelFormat = metalLayer.pixelFormat
        
        do {
            try pipelineState = device.makeRenderPipelineState(descriptor: pipelineStateDescriptor)
        } catch let error {
            print("Failed to create pipeline state, error \(error)")
        }
    }
    
    func render(qrcodeTexture: MTLTexture) {
        guard let drawable = metalLayer?.nextDrawable() else { return }
        let renderPassDescriptor = MTLRenderPassDescriptor.init()
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColor.init(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0);
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        
        let commandBuffer = commandQueue.makeCommandBuffer()!
        commandBuffer.label = "Frame command buffer"
        let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        renderEncoder.label = "render encoder"
        renderEncoder.pushDebugGroup("begin draw")
        renderEncoder.setRenderPipelineState(pipelineState)
        
        self.draw(renderEncoder: renderEncoder, qrcodeTexture: qrcodeTexture)
        
        renderEncoder.popDebugGroup()
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
