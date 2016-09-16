//
//  CameraSessionController.swift
//  Whale
//
//  Created by John on 9/15/16.
//  Copyright © 2016 John. All rights reserved.
//

import Foundation
import CoreMedia
import AVFoundation
import AssetsLibrary
import MediaPlayer
import CoreAudio
import CoreFoundation

class CameraSessionController: AVCaptureFileOutputRecordingDelegate {
    static let sharedInstance = CameraSessionController()
    
    var captureSession: AVCaptureSession?
    var videoCaptureDevice: AVCaptureDevice?
    var audioCaptureDevice: AVCaptureDevice?
    var videoInputDevice: AVCaptureDeviceInput?
    var audioInputDevice: AVCaptureDeviceInput?
    var previewLayer: AVCaptureVideoPreviewLayer?
    
    var movieFileOutput: AVCaptureMovieFileOutput?
    var outputPath = NSTemporaryDirectory() as String
    
    var totalSeconds: Float64 = 10.00
    var framesPerSecond:Int32 = 30
    
    var maxDuration: CMTime?
    var toggleCameraSwitch: UIButton = UIButton()
    
    var videoAssets = [AVAsset]()
    var assetURLs = [String]()
    
    var incInterval: NSTimeInterval = 0.05
    var timer: NSTimer?
    var stopRecording: Bool = false
    var remainingTime : NSTimeInterval = 10.0
    var oldX: CGFloat = 0
    var appendix: Int32 = 1
    var defaultTrimDuration: Int = 10
    
    func setupCapturing() {
        if let videoCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) {
            videoInputDevice =  try? AVCaptureDeviceInput(device: videoCaptureDevice )
            captureSession?.addInput(videoInputDevice)
        }
        
        if let audioCaptureDevice = AVCaptureDevice.devicesWithMediaType(AVMediaTypeAudio)[0] as? AVCaptureDevice {
            audioInputDevice =  try? AVCaptureDeviceInput(device: audioCaptureDevice )
            captureSession?.addInput(audioInputDevice)
        }
    }
    
    func beginRecording() {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            self.captureSession?.startRunning()
            
        })
    }
    
    func endRecording() {
        
    }
    
    func connectionIsActive(connections: [AVCaptureConnection], mediaType: String) -> AVCaptureConnection {
        
        for connection in connections {
            
            for port in connection.inputPorts {
                
                if(port.mediaType  == mediaType) {
                    
                    
                    return connection
                }
            }
            
        }
        
        return connections[0] as AVCaptureConnection
    }

    
}
