//
//  UIUtilities.swift
//  eliss ios
//
//  Created by darrelhong on 8/4/23.
//

import AVFoundation
import UIKit


public class UIUtilities {
    
    public static func imageOrientation(
        fromDevicePosition devicePosition: AVCaptureDevice.Position = .back
        , deviceOrientation: UIDeviceOrientation) -> UIImage.Orientation {
        let deviceOrientation = UIDevice.current.orientation
        if deviceOrientation == .faceDown || deviceOrientation == .faceUp
            || deviceOrientation
            == .unknown
        {
            
        }
        switch deviceOrientation {
        case .portrait:
            return devicePosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return devicePosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return devicePosition == .front ? .rightMirrored : .left
        case .landscapeRight:
            return devicePosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return .up
        @unknown default:
            fatalError()
        }
    }
}
