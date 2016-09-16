//
//  VideoHandler.swift
//  Whale
//
//  Created by John on 9/15/16.
//  Copyright © 2016 John. All rights reserved.
//

import Foundation
import CoreMedia
import AVFoundation
import CoreAudio
import CoreFoundation
import Photos

protocol VideoHandlerDelegate: class {
    func didStartRecording()
    func exportCompleted(url: NSURL!)
}

class VideoHandler: NSObject {
    // Delegate
    weak var delegate:VideoHandlerDelegate?
    
    // Session
    var captureSession: AVCaptureSession?
    
    // Devices
    var videoCaptureDevice: AVCaptureDevice?
    var audioCaptureDevice: AVCaptureDevice?
    var videoInputDevice: AVCaptureDeviceInput?
    var audioInputDevice: AVCaptureDeviceInput?
    
    // File Outputs
    var movieFileOutput: AVCaptureMovieFileOutput?
    var outputPath = NSTemporaryDirectory() as String
    
    // Collections of Assets (for merging)
    var videoAssets = [AVAsset]()
    var assetURLs = [String]()

    // Settings
    var totalSeconds: Float64 = 60.00
    var framesPerSecond:Int32 = 30
    var maxDuration: CMTime = CMTime(seconds: 60, preferredTimescale: 30)
    var remainingTime : NSTimeInterval = 60.0
    
    var filePartAppendix: Int32 = 1
    var defaultTrimDuration: Int = 10
    
    override init() {
        super.init()
        setupCapturing()
    }
    
    func setupCapturing() {
        //TODO - This takes too long, need to research correct way to do this on background thread
        
        captureSession = AVCaptureSession()
        captureSession?.beginConfiguration()
        if let videoCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo) {
            videoInputDevice = try? AVCaptureDeviceInput(device: videoCaptureDevice )
            captureSession?.addInput(videoInputDevice)
        }
        
        
        if let audioCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeAudio) {
            audioInputDevice = try? AVCaptureDeviceInput(device: audioCaptureDevice )
            captureSession?.addInput(audioInputDevice)
        }
        
        movieFileOutput = AVCaptureMovieFileOutput()
        maxDuration = CMTimeMakeWithSeconds(totalSeconds, 1)
        movieFileOutput?.maxRecordedDuration = maxDuration
        
        captureSession?.addOutput(movieFileOutput)
        captureSession?.commitConfiguration()
        
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), {
            
            self.captureSession?.startRunning()
            
        })
    }
    
    func createViewPortLayer(frame: CGRect) -> AVCaptureVideoPreviewLayer?  {
        if let viewPortLayer = AVCaptureVideoPreviewLayer(session: captureSession) {
            viewPortLayer.frame = frame
            viewPortLayer.videoGravity = AVLayerVideoGravityResizeAspectFill
            return viewPortLayer
        }
        
        return nil
    }
    
    func beginRecording() {
        
        
        let outputFilePath = outputPath + "output-\(filePartAppendix).mov"
        filePartAppendix += 1
        let outputURL = NSURL(fileURLWithPath: outputFilePath)
        let fileManager = NSFileManager.defaultManager()
        if(fileManager.fileExistsAtPath(outputFilePath)) {
            
            do {
                try fileManager.removeItemAtPath(outputFilePath)
            } catch _ {
            }
        }
        
        movieFileOutput?.startRecordingToOutputFileURL(outputURL, recordingDelegate: self)
    }
    
    func endRecording() {
        movieFileOutput?.stopRecording()
    }
    
    func flipCamera() {
        var newInputDevice: AVCaptureDeviceInput = videoInputDevice!
        let position: AVCaptureDevicePosition? = videoInputDevice?.device.position
        var newDevice: AVCaptureDevice?
        if(position == AVCaptureDevicePosition.Back) {
            newDevice = cameraWithPosition(AVCaptureDevicePosition.Front)
            newInputDevice = try! AVCaptureDeviceInput(device: newDevice)
        } else if(position == AVCaptureDevicePosition.Front) {
            newDevice = cameraWithPosition(AVCaptureDevicePosition.Back)
            newInputDevice = try! AVCaptureDeviceInput(device: newDevice)
        }
        
        captureSession?.beginConfiguration()
        captureSession?.removeInput(videoInputDevice)
        captureSession?.addInput(newInputDevice)
        videoInputDevice = newInputDevice
        captureSession?.commitConfiguration()
    }

    func cameraWithPosition(position: AVCaptureDevicePosition) -> AVCaptureDevice {
        
        var rv: AVCaptureDevice = AVCaptureDevice.defaultDeviceWithMediaType(AVMediaTypeVideo)
        let devices = AVCaptureDevice.devicesWithMediaType(AVMediaTypeVideo)
        for device in devices {
            if(device.position == position) {
                rv = device as! AVCaptureDevice
            }
        }
        return rv
    }
    
    func reset() {
        // Delete what we've written
        for assetURL in assetURLs {
            
            if(NSFileManager.defaultManager().fileExistsAtPath(assetURL)) {
                
                do {
                    try NSFileManager.defaultManager().removeItemAtPath(assetURL)
                } catch _ {
                }
            }
        }
        
        videoAssets.removeAll(keepCapacity: false)
        assetURLs.removeAll(keepCapacity: false)
        filePartAppendix = 1
        remainingTime = 60.00
    }

    //MARK: video merging
    
    func mergeVideos() {
        let composition = AVMutableComposition()
        
        let firstTrack:AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeVideo, preferredTrackID: CMPersistentTrackID())
        
        let audioTrack: AVMutableCompositionTrack = composition.addMutableTrackWithMediaType(AVMediaTypeAudio, preferredTrackID: CMPersistentTrackID())
        
        var insertTime: CMTime = kCMTimeZero
        
        for asset in videoAssets {
            do {
                try firstTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), ofTrack: asset.tracksWithMediaType(AVMediaTypeVideo)[0] , atTime: insertTime)
            } catch _ {
            }
            do {
                try audioTrack.insertTimeRange(CMTimeRangeMake(kCMTimeZero, asset.duration), ofTrack: asset.tracksWithMediaType(AVMediaTypeAudio)[0] , atTime: insertTime)
            } catch _ {
            }
            
            insertTime = CMTimeAdd(insertTime, asset.duration)
        }
        firstTrack.preferredTransform = CGAffineTransformMakeRotation(CGFloat(M_PI_2))
        
        //get path of newly merged video
        let documentsPath : String = NSSearchPathForDirectoriesInDomains(.DocumentDirectory,.UserDomainMask,true)[0]
        let destinationPath: String = documentsPath + "/mergeVideo-\(arc4random()%1000).mov"
        let videoPath: NSURL = NSURL(fileURLWithPath: destinationPath as String)
        if let exporter: AVAssetExportSession = AVAssetExportSession(asset: composition, presetName:AVAssetExportPresetHighestQuality) {
            exporter.outputURL = videoPath
            exporter.outputFileType = AVFileTypeQuickTimeMovie
            exporter.shouldOptimizeForNetworkUse = true
            exporter.timeRange = CMTimeRangeMake(kCMTimeZero, CMTimeMakeWithSeconds(Float64(totalSeconds),framesPerSecond))
            exporter.exportAsynchronouslyWithCompletionHandler({
                
                // finished (call on main thread)
                dispatch_async(dispatch_get_main_queue(),{
                    self.exportDidFinish(exporter)
                })
                
            })
        }
    }
    
    func exportDidFinish(session: AVAssetExportSession) {
        if let outputURL: NSURL = session.outputURL {
            //TODO - Write output to PHLibrary
            self.delegate?.exportCompleted(outputURL)
        }
    }
}

extension VideoHandler: AVCaptureFileOutputRecordingDelegate {
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        // Append asset onto array
        let asset : AVURLAsset = AVURLAsset(URL: outputFileURL, options: nil)
        videoAssets.append(asset)
        assetURLs.append(outputFileURL.path!)
        
        //Update remaining time
        let duration = CMTimeGetSeconds(asset.duration)
        remainingTime = remainingTime - duration
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        delegate?.didStartRecording()
    }
}
