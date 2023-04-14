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

enum RepPosition: String {
    case up, down
}

final class DataModel: ObservableObject {
    let camera = Camera()
    
//    @Published var viewfinderImage: Image?
    
    @Published var situpAngle: CGFloat?
    @Published var debouncedAngle: CGFloat?
    @Published var reps: Int = 0
    @Published var repPosition: RepPosition = .down
    
    var cameraController: CameraController!
    
    private var cancellables = Set<AnyCancellable>()

    private func calculateAngle(_ left: PoseLandmark, _ mid: PoseLandmark, _ right: PoseLandmark) -> CGFloat {
        let leftAngle = atan2(left.position.y - mid.position.y, left.position.x - mid.position.x)
        let rightAngle = atan2(right.position.y - mid.position.y, right.position.x - mid.position.x)
        
        var angle = rightAngle - leftAngle
        if angle < 0 {
            angle += 2 * .pi
        }

        return angle * 180 / .pi
    }
    
    private func update(_ angle: CGFloat) {
        if angle > 110 {
            self.repPosition = RepPosition.down
        } else if angle < 40 && self.repPosition == RepPosition.down {
            self.reps += 1
            self.repPosition = RepPosition.up
        }
    }
    
    func updateWithPose(_ pose: Pose) {
        let rightShoulderPose = pose.landmark(ofType: PoseLandmarkType.rightShoulder)
        let rightHipPose = pose.landmark(ofType: PoseLandmarkType.rightHip)
        let rightKneePose = pose.landmark(ofType: PoseLandmarkType.rightKnee)
        
        if rightShoulderPose.inFrameLikelihood > InFrameLikelihoodThreshold && rightHipPose.inFrameLikelihood > InFrameLikelihoodThreshold && rightKneePose.inFrameLikelihood > InFrameLikelihoodThreshold {
            let angle = self.calculateAngle(rightShoulderPose, rightHipPose, rightKneePose)
            
            self.update(angle)
            
            self.situpAngle = angle
        } else {
            self.situpAngle = nil
        }
    }
    
    init() {
        self.$situpAngle.throttle(for: .milliseconds(250), scheduler: DispatchQueue.main, latest: true)
            .sink(receiveValue: { [weak self] a in
                self?.debouncedAngle = a
            })
            .store(in: &self.cancellables)
                
//        Task {
//            await self.handleCameraPreviews()
//        }
//        Task {
//            await self.handlePoseResults()
//        }
    }
    
//    func handleCameraPreviews() async {
//        let imageStream = self.camera.previewStream.map { $0.image }
//
//        for await image in imageStream {
//            Task { @MainActor in
//                self.viewfinderImage = image
//            }
//        }
//    }
    
//    func handlePoseResults() async {
//        let poseStream = self.camera.poseStream
//
//        for await pose in poseStream {
//            Task { @MainActor in
//                self.pose = pose
//
//                let rightShoulderPose = pose.landmark(ofType: PoseLandmarkType.rightShoulder)
//                let rightHipPose = pose.landmark(ofType: PoseLandmarkType.rightHip)
//                let rightKneePose = pose.landmark(ofType: PoseLandmarkType.rightKnee)
//
//                if rightShoulderPose.inFrameLikelihood > InFrameLikelihoodThreshold && rightHipPose.inFrameLikelihood > InFrameLikelihoodThreshold && rightKneePose.inFrameLikelihood > InFrameLikelihoodThreshold {
//                    let angle = self.calculateAngle(rightShoulderPose, rightHipPose, rightKneePose)
//
//                    self.update(angle)
//
//                    self.situpAngle = angle
//                } else {
//                    self.situpAngle = nil
//                }
//            }
//        }
//    }
}

private extension CIImage {
    var image: Image? {
        let ciContext = CIContext()
        guard let cgImage = ciContext.createCGImage(self, from: extent) else { return nil }
        return Image(decorative: cgImage, scale: 1, orientation: .up)
    }
}

private let logger = Logger(subsystem: "com.darrelhong.eliss-ios", category: "DataModel")
