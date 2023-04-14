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

let InFrameLikelihoodThreshold: Float = 0.8

enum RepPosition : String {
    case up, down
}

final class DataModel: ObservableObject {
    let camera = Camera()
    
    @Published var viewfinderImage: Image?
    @Published var situpAngle: CGFloat? 
    @Published var debouncedAngle: CGFloat?
    @Published var reps: Int = 0
    @Published var repPosition: RepPosition = RepPosition.down
    
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
    
    private func update(_ angle: CGFloat) {
        if angle > 110 {
            self.repPosition = RepPosition.down
        } else if angle < 40 && self.repPosition == RepPosition.down {
            self.reps += 1
            self.repPosition = RepPosition.up
        }
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
                
                
                if (rightShoulderPose.inFrameLikelihood > InFrameLikelihoodThreshold && rightHipPose.inFrameLikelihood > InFrameLikelihoodThreshold && rightKneePose.inFrameLikelihood > InFrameLikelihoodThreshold) {
                    let angle = calculateAngle(rightShoulderPose, rightHipPose, rightKneePose)
                    
                    update(angle)
                    
                    situpAngle = angle
                } else {
                    situpAngle = nil
                }
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
