//
//  ViewController.swift
//  Whale
//
//  Created by John on 9/15/16.
//  Copyright © 2016 John. All rights reserved.
//

import UIKit
import AVFoundation
import AVKit

class ViewController: UIViewController {
    @IBOutlet weak var progressView: UIView?
    @IBOutlet weak var viewPort: UIView?
    @IBOutlet weak var deleteButton: UIButton?
    @IBOutlet weak var recordButton: UIButton?
    @IBOutlet weak var nextButton: UIBarButtonItem?
    
    var longPressRecognizer: UILongPressGestureRecognizer!
    var videoHandler: VideoHandler!
    
    var progressTimer: NSTimer? = nil
    var finishedRecording = false
    var remainingTime: NSTimeInterval = 0.0
    var progressBarProgressX: CGFloat = 0
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Record"
        videoHandler = VideoHandler()
        videoHandler.delegate = self
        nextButton?.enabled = false
        deleteButton?.hidden = true
        progressView?.layer.borderColor = UIColor.blackColor().CGColor
        progressView?.layer.borderWidth = 1.0
        recordButton?.layer.borderColor = UIColor.lightGrayColor().CGColor
        recordButton?.layer.borderWidth = 15.0
        recordButton?.layer.cornerRadius = 60

        // Add a recognizer to the button for long press (could also do with touch methods)
        longPressRecognizer = UILongPressGestureRecognizer(target: self, action: #selector(ViewController.recordPressed))
        recordButton?.addGestureRecognizer(longPressRecognizer)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        // Add the viewport
        if let viewPortLayer = videoHandler.createViewPortLayer((self.viewPort?.bounds)!) {
            viewPort?.layer.addSublayer(viewPortLayer)
        }
    }
    
    func recordPressed(recognizer: UILongPressGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.Began {
            videoHandler.beginRecording()
            recordButton?.layer.borderColor = UIColor(red: 170.0/255.0, green: 67.0/255.0, blue: 170.0/255.0, alpha: 1.0).CGColor            
        } else if recognizer.state == UIGestureRecognizerState.Ended {
            progressTimer?.invalidate()
            videoHandler.endRecording()
            progressTimer?.invalidate()
            progressBarProgressX += 1
            recordButton?.layer.borderColor = UIColor.lightGrayColor().CGColor
        }
    }
    
    @IBAction func flipCamera() {
        videoHandler.flipCamera()
    }
    
    @IBAction func deletePressed() {
        videoHandler.reset()
        progressBarProgressX = 0
        nextButton?.enabled = false
        deleteButton?.hidden = true
        clearProgressBar()
    }
    
    @IBAction func nextPressed() {
        //TODO - Should add in an activity indicator here
        videoHandler.mergeVideos()
    }
    
    private func startProgressTimer() {
        
        progressTimer = NSTimer(timeInterval: 0.05, target: self, selector: #selector(ViewController.updateProgress), userInfo: nil, repeats: true)
        
        NSRunLoop.currentRunLoop().addTimer(progressTimer!, forMode: NSDefaultRunLoopMode)
    }
    
    func updateProgress() {
        let progressProportion: CGFloat = CGFloat(0.05 / 60.0)
        let progressInc: UIView = UIView()
        progressInc.backgroundColor = UIColor(red: 170.0/255.0, green: 67.0/255.0, blue: 170.0/255.0, alpha: 1.0)
        let newWidth = (progressView?.frame.width)! * progressProportion
        progressInc.frame = CGRect(x: progressBarProgressX , y: 0, width: newWidth, height: progressView!.frame.height)
        progressBarProgressX = progressBarProgressX + newWidth
        progressView?.addSubview(progressInc)
    }
    
    private func addSegmentToProgressBar() {
        
    }
    
    private func clearProgressBar() {
        if let subviews = progressView?.subviews {
            for subview in subviews {
                
                subview.removeFromSuperview()
            }
        }
    }
}

extension ViewController: VideoHandlerDelegate {
    func didStartRecording() {
        deleteButton?.hidden = false
        nextButton?.enabled = true
        startProgressTimer()
    }
    
    func exportCompleted(url: NSURL!) {
        let player = AVPlayer(URL: url)
        let playerViewController = AVPlayerViewController()
        playerViewController.player = player
        self.presentViewController(playerViewController, animated: true) {
            playerViewController.player?.play()
        }
    }
}

