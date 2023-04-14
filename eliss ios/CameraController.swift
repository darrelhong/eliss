//
//  CameraController.swift
//  eliss ios
//
//  Created by darrelhong on 12/4/23.
//

import AVFoundation
import MLKit
import os.log
import SwiftUI
import UIKit

class CameraController: UIViewController, AVCaptureVideoDataOutputSampleBufferDelegate {
    private var permissionGranted = false
    private let captureSession = AVCaptureSession()
    private let sessionQueue = DispatchQueue(label: "sessionQueue")
    var previewLayer = AVCaptureVideoPreviewLayer()
    var screenRect: CGRect! = nil
    private var currentCapturePosition: AVCaptureDevice.Position = .front
    
    private var videoOutput = AVCaptureVideoDataOutput()
    var poseDetector: PoseDetector = .poseDetector(options: AccuratePoseDetectorOptions())
    var detectionLayer: CALayer! = nil

    
    var dataModel: DataModel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        dataModel.cameraController = self

        checkAuthorisation()
        
        sessionQueue.async { [unowned self] in
            guard permissionGranted else { return }
            self.setupCaptureSession()
            
            self.setupDetectionLayer()
            
            self.captureSession.startRunning()
        }
    }
    
    override func willTransition(to newCollection: UITraitCollection, with coordinator: UIViewControllerTransitionCoordinator) {
        screenRect = UIScreen.main.bounds
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)

        switch UIDevice.current.orientation {
        case UIDeviceOrientation.portraitUpsideDown:
            previewLayer.connection?.videoOrientation = .portraitUpsideDown
                     
        case UIDeviceOrientation.landscapeLeft:
            previewLayer.connection?.videoOrientation = .landscapeRight
                    
        case UIDeviceOrientation.landscapeRight:
            previewLayer.connection?.videoOrientation = .landscapeLeft
                     
        case UIDeviceOrientation.portrait:
            previewLayer.connection?.videoOrientation = .portrait
                        
        default:
            break
        }
        
        updateDetectionLayer()
    }
    
    private func setupCaptureSession() {
        guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: currentCapturePosition) else {
            logger.debug("Failed to obtain capture device")
            return
        }
        
        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            logger.error("Failed to obtain input")
            return
        }
        
        guard captureSession.canAddInput(deviceInput) else {
            logger.error("Unable to add device input to capture session")
            return
        }
        
        
        captureSession.addInput(deviceInput)
        
        screenRect = UIScreen.main.bounds

        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer.frame = CGRect(x: 0, y: 0, width: screenRect.size.width, height: screenRect.size.height)
        previewLayer.videoGravity = AVLayerVideoGravity.resizeAspectFill // Fill screen

        previewLayer.connection?.videoOrientation = .portrait
        
        videoOutput.setSampleBufferDelegate(self, queue: DispatchQueue(label: "sampleBufferQueue"))
        captureSession.addOutput(videoOutput)

        videoOutput.connection(with: .video)?.videoOrientation = .portrait
        
        DispatchQueue.main.sync { [weak self] in
            self!.view.layer.addSublayer(self!.previewLayer)
        }
    }
    
    private func checkAuthorisation() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            logger.debug("Camera access authorised")
            permissionGranted = true
            
        case .notDetermined:
            logger.debug("Camera access not determined")
            sessionQueue.suspend()
            AVCaptureDevice.requestAccess(for: .video) { [unowned self] _ in
                logger.debug("Camera access authorised after")
                self.permissionGranted = true
                self.sessionQueue.resume()
            }
        case .restricted:
            logger.debug("Camera access restricted")
        case .denied:
            logger.debug("Camera access denied")
        @unknown default:
            logger.debug("Unknown error occured")
        }
    }
    
    func switchCamera() {
        if currentCapturePosition == .front {
            guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) else {
                logger.debug("Failed to obtain capture device")
                return
            }
            updateSessionForCaptureDevice(captureDevice)
            currentCapturePosition = .back
        } else {
            print("there")
            guard let captureDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
                logger.debug("Failed to obtain capture device")
                return
            }
            updateSessionForCaptureDevice(captureDevice)
            currentCapturePosition = .front
        }
    }
    
    private func updateSessionForCaptureDevice(_ captureDevice: AVCaptureDevice) {
        captureSession.beginConfiguration()
        defer { captureSession.commitConfiguration() }
            
        for input in captureSession.inputs {
            if let deviceInput = input as? AVCaptureDeviceInput {
                captureSession.removeInput(deviceInput)
            }
        }
        guard let deviceInput = try? AVCaptureDeviceInput(device: captureDevice) else {
            logger.error("Failed to obtain input")
            return
        }
        if !captureSession.inputs.contains(deviceInput), captureSession.canAddInput(deviceInput) {
            captureSession.addInput(deviceInput)
        }
    }
}

private let logger = Logger(subsystem: "com.darrelhong.elliss-ios", category: "CameraController")
