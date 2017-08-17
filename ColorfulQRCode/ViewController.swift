//
//  ViewController.swift
//  ColorfulQRCode
//
//  Created by wang yang on 2017/8/15.
//  Copyright © 2017年 ocean. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var qrcodeView: ColorfulQRCodeView!
    @IBOutlet weak var qrcodeMetalView: ColorfulQRCodeMetalView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.init(white: 0.85, alpha: 1.0)
        if let image = UIImage.init(named: "qrcode.png") {
            qrcodeView.setQRCodeImage(qrcodeImage: image)
            qrcodeMetalView.setQRCodeImage(qrcodeImage: image)
        }
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        qrcodeView.syncFrame()
        qrcodeMetalView.syncFrame()
    }

}

