//
//  CameraPreview.swift
//  eliss ios
//
//  Created by darrelhong on 12/4/23.
//

import SwiftUI

struct CameraPreviewController: UIViewControllerRepresentable {
    var dataModel: DataModel
    
    func makeUIViewController(context: Context) -> CameraController {
        let cc = CameraController()
        cc.dataModel = dataModel
        return cc
    }

    func updateUIViewController(_ uiView: CameraController, context: Context) {
    }
}
