//
//  DataModel.swift
//  eliss ios
//
//  Created by darrelhong on 7/4/23.
//

import AVFoundation
import Combine
import MLKit
import os.log
import SwiftUI

final class DataModel: ObservableObject {
    let camera = Camera()
    
    @Published var viewfinderImage: Image?
    @Published var situpAngle: CGFloat?
    @Published var debouncedAngle: CGFloat?
    
    private var cancellables = Set<AnyCancellable>()

    private func calculateAngle(_ left: PoseLandmark, _ mid: PoseLandmark, _ right: PoseLandmark) -> CGFloat {
        let dx1 = left.position.x - mid.position.x
        let dy1 = left.position.y - mid.position.y
        let dx2 = right.position.x - mid.position.x
        let dy2 = right.position.y - mid.position.y
            
        let angle1 = atan2(dy1, dx1)
        let angle2 = atan2(dy2, dx2)
            
        var angleDegrees = (angle1 - angle2) * 180 / .pi
            
        if angleDegrees < 0 {
            angleDegrees += 360
        }
            
        return angleDegrees
    }
    
    init() {
        $situpAngle.throttle(for: .milliseconds(250), scheduler: DispatchQueue.main, latest: true)
            .sink(receiveValue: { [weak self] a in
                self?.debouncedAngle = a
            })
            .store(in: &cancellables)
                
        Task {
            await handleCameraPreviews()
        }
        Task {
            await handlePoseResults()
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
    
    func handlePoseResults() async {
        let poseStream = camera.poseStream
        
        for await pose in poseStream {
            Task { @MainActor in
                let rightShoulderPose = pose.landmark(ofType: PoseLandmarkType.rightShoulder)
                let rightHipPose = pose.landmark(ofType: PoseLandmarkType.rightHip)
                let rightKneePose = pose.landmark(ofType: PoseLandmarkType.rightKnee)
                
                situpAngle = calculateAngle(rightShoulderPose, rightHipPose, rightKneePose)
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
