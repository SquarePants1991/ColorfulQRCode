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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.init(white: 0.6, alpha: 1.0)
        if let image = UIImage.init(named: "qrcode.png") {
            qrcodeView.setQRCodeImage(qrcodeImage: image)
        }
    }

}

