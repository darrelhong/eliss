//
//  DataModel.swift
//  eliss ios
//
//  Created by darrelhong on 7/4/23.
//

import AVFoundation
import os.log
import SwiftUI

final class DataModel: ObservableObject {
    let camera = Camera()
    
    @Published var viewfinderImage: Image?
    
    init() {
        Task {
            await handleCameraPreviews()
        }
    }
    
    func handleCameraPreviews() async {
        let imageStream = camera.previewStream.map { $0.image }
        
        for await image in imageStream {
            Task { @MainActor in
                viewfinderImage = image
            }
        }
    }
}

private extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}

private let logger = Logger(subsystem: "com.darrelhong.eliss-ios", category: "DataModel")
