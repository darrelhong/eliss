//
//  PoseDetect.swift
//  eliss ios
//
//  Created by darrelhong on 13/4/23.
//

import AVFoundation
import MLKit
import os.log
import UIKit

extension CameraController {
    func drawPose(_ poses: [Pose], _ imageHeight: CGFloat, _ imageWidth: CGFloat) {
        detectionLayer.sublayers = nil
        
        poses.forEach { pose in
            let poseOverlayView = UIUtilities.createPoseOverlayView(
                forPose: pose,
                inViewWithBounds: detectionLayer.bounds,
                lineWidth: 3.0,
                dotRadius: 4.0,
                positionTransformationClosure: { position -> CGPoint in
                    self.normalisedPoint(
                        fromVisionPoint: position, width: imageWidth, height: imageHeight
                    )
                }
            )
            detectionLayer.addSublayer(poseOverlayView.layer)
        }
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
            logger.debug("Failed to get image buffer from sample buffer")
            return
        }
        
        let imageWidth = CGFloat(CVPixelBufferGetWidth(pixelBuffer))
        let imageHeight = CGFloat(CVPixelBufferGetHeight(pixelBuffer))
        
        let visionImage = VisionImage(buffer: sampleBuffer)
        
        var results: [Pose] = []
        do {
            results = try poseDetector.results(in: visionImage)
        } catch {
            logger.error("Failed to detect pose with error: \(error.localizedDescription).")
            return
        }
        guard !results.isEmpty else {
            logger.error("Pose detector returned no results.")
            return
        }
        
        
        DispatchQueue.main.async(execute: {
            self.dataModel.updateWithPose(results[0])
            self.drawPose(results, imageHeight, imageWidth)
        }
        )
    }
    
    private func normalisedPoint(
        fromVisionPoint point: VisionPoint,
        width: CGFloat,
        height: CGFloat
    ) -> CGPoint {
        let cgPoint = CGPoint(x: point.x, y: point.y)
        var normalisedPoint = CGPoint(x: cgPoint.x / width, y: cgPoint.y / height)
        normalisedPoint = previewLayer.layerPointConverted(fromCaptureDevicePoint: normalisedPoint)
        return normalisedPoint
    }

    func setupDetectionLayer() {
        detectionLayer = CALayer()
        detectionLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        self.view.layer.addSublayer(detectionLayer)
    }
    
    func updateDetectionLayer() {
        detectionLayer?.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
    }
}

private let logger = Logger(subsystem: "com.darrelhong.elliss-ios", category: "PoseDetect")
