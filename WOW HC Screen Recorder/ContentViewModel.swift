//
//  ContentViewModel.swift
//  Record WOW HC
//
//  Created by james bouker on 6/6/23.
//

import Foundation
import SwiftUI
import AVFoundation

class ViewModel: NSObject, ObservableObject, AVCaptureFileOutputRecordingDelegate {
    var timer: Timer?
    var diskCalcTimer: Timer?
    var copy = false
    
    var url: URL = URL.wowHCDefaultRecordingDIR()
    
    var screenInput: AVCaptureScreenInput?
    var movieOutput: AVCaptureMovieFileOutput?
    var captureSession: AVCaptureSession?
    var outputURL: URL?
    
    @Published var isRecording = false
    @Published var hasFiles = false
    @Published var hidePermissions = false
    @Published var frameRate = 30 {
        didSet { frameRate.save(to: "frameRate") }
    }
    
    @Published var numberOfVideos = 5 {
        didSet {
            numberOfVideos.save(to: "numberOfVideos")
            
            while recordedURLS.count > numberOfVideos {
                let dropped = recordedURLS.removeFirst()
                try? FileManager.default.removeItem(at: dropped)
            }
        }
    }
        
    var recordedURLS: [URL] = [] {
        didSet { recordedURLS.save(to: "recordedURLS") }
    }
    
    // MARK: - Functions
    
    override init() {
        super.init()
        numberOfVideos = .saved(at: "numberOfVideos") ?? 5
        frameRate = .saved(at: "frameRate") ?? 30
        recordedURLS = .saved(at: "recordedURLS") ?? []
    }
    
    func userStart(_ url: URL) {
        setupCaptureSession()
        
        self.url = url
        timer?.invalidate()
        timer = Timer.scheduledTimer(timeInterval: 300, target: self,
                                     selector: #selector(ViewModel.tickEvery5Minutes),
                                     userInfo: nil,
                                     repeats: true)
        isRecording = true
        start()
    }
    
    func userStop() {
        timer?.invalidate()
        timer = nil
        movieOutput?.stopRecording()
        isRecording = false
        
        captureSession?.stopRunning()
    }
    
    func userStopAndCopy() {
        copy = true
        userStop()
    }
    
    // MARK: - Timer
    
    @objc func tickEvery5Minutes() {
        if isRecording {
            movieOutput?.stopRecording()
            start()
        }
    }
    
    // MARK: - AVCaptureFileOutputRecordingDelegate
    
    func fileOutput(_ output: AVCaptureFileOutput, didStartRecordingTo fileURL: URL, from connections: [AVCaptureConnection]) {
        debugPrint("Recording started")
        DispatchQueue.main.async {
            self.hasFiles = true
            self.hidePermissions = true
        }
    }
    
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {

        if let error = error {
            // Recording finished with an error
            debugPrint("Recording finished with error: \(error.localizedDescription)")
        } else {
            // Recording finished successfully
            debugPrint("Recording finished")
            
            if copy {
                self.copy = false
                let documentsDirectory = url
                let filename = "Death_" + outputFileURL.lastPathComponent
                let copyURL = documentsDirectory.appendingPathComponent(filename)
                
                try? FileManager.default.copyItem(at: outputFileURL, to: copyURL)
                NSWorkspace.shared.open(documentsDirectory)
            }
        }
    }
    
    // MARK: - Private Functions
    
    private func start() {
        // Start recording
        let documentsDirectory = url
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        let timestamp = formatter.string(from: Date())
        let filename = "Recording_\(timestamp).mov"
        let outputURL = documentsDirectory.appendingPathComponent(filename)
        debugPrint("Recording to \(outputURL)")
        movieOutput?.startRecording(to: outputURL, recordingDelegate: self)
        isRecording = true
        recordedURLS.append(outputURL)
        
        while recordedURLS.count > numberOfVideos {
            let dropped = recordedURLS.removeFirst()
            try? FileManager.default.removeItem(at: dropped)
        }
    }
    
    private func setupCaptureSession() {
        captureSession = AVCaptureSession()
        
        if let screen = NSScreen.main {
            let screenRect = screen.frame
            screenInput = AVCaptureScreenInput(displayID: screen.deviceDescription[NSDeviceDescriptionKey("NSScreenNumber")] as! CGDirectDisplayID)
            screenInput?.cropRect = screenRect
            screenInput?.minFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
            if let screenInput = screenInput, captureSession!.canAddInput(screenInput) {
                captureSession!.addInput(screenInput)
            }
        }
        
        movieOutput = AVCaptureMovieFileOutput()
        if let movieOutput = movieOutput, captureSession!.canAddOutput(movieOutput) {
            captureSession!.addOutput(movieOutput)
        }
        
        captureSession?.startRunning()
    }
}
