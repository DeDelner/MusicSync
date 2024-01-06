//
//  Microphone.swift
//  MusicSync
//
//  Created by Christian Langolf on 04/01/2024.
//

import Foundation
import AVFoundation
import SwiftUI

class Microphone: ObservableObject {
    static var shared = Microphone()
    
    private var audioRecorder: AVAudioRecorder
    
    // Constans
    private final var NOISE_FLOOR: Float = 60.0 //db
    
    init() {
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (isGranted) in
                if !isGranted {
                    fatalError("You must allow audio recording")
                }
            }
        }
        
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        let recorderSettings: [String:Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]

        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            audioRecorder.isMeteringEnabled = true
            audioRecorder.record()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    public var level: Float {
        get {
            self.audioRecorder.updateMeters()
            return self.audioRecorder.averagePower(forChannel: 0)
        }
    }
    
    public var normalizedLevel: Float {
        get {
            let level = max(0.0, level + NOISE_FLOOR)
            return min(level / 100.0, 1.0) // limit it to 1.0
        }
    }
    
}
