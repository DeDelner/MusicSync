//
//  Microphone.swift
//  MusicSync
//
//  Created by Christian Langolf on 08/05/2023.
//

import Foundation
import AVFoundation

class Microphone: ObservableObject {
    
    struct HyperionStruct: Codable {
        var command: String
        var priority: Int
        var color: [Int]
        var origin: String
    }
    
    // 1
    private var audioRecorder: AVAudioRecorder
    private var timer: Timer?
    
    // 2
    @Published public var level: Int
    
    init() {
        self.level = 0
        
        // 3
        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (isGranted) in
                if !isGranted {
                    fatalError("You must allow audio recording for this demo to work")
                }
            }
        }
        
        // 4
        let url = URL(fileURLWithPath: "/dev/null", isDirectory: true)
        let recorderSettings: [String:Any] = [
            AVFormatIDKey: NSNumber(value: kAudioFormatAppleLossless),
            AVSampleRateKey: 44100.0,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
        ]
        
        // 5
        do {
            audioRecorder = try AVAudioRecorder(url: url, settings: recorderSettings)
            try audioSession.setCategory(.ambient, mode: .measurement, options: [])
            
            startMonitoring()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    
    private func normalizeSoundLevel(level: Float) -> CGFloat {
        let level = max(0.0, CGFloat(level) + 50) // between 0.0 and 25
        
        return CGFloat(min(pow(level, 3) / 300, 255)) // scaled to max at 255 (our height of our bar)
    }
    
    // 6
    private func startMonitoring() {
        var webSocket : URLSessionWebSocketTask?
        
        //Session
        let session = URLSession(configuration: .default)
        
        //Server API
        let url = URL(string:  "ws://192.168.0.206:8090")
        
        //Socket
        webSocket = session.webSocketTask(with: url!)
        
        //Connect and hanles handshake
        webSocket?.resume()
        
        audioRecorder.isMeteringEnabled = true
        audioRecorder.record()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            // 7
            self.audioRecorder.updateMeters()
            
            self.level = Int(self.normalizeSoundLevel(level: self.audioRecorder.averagePower(forChannel: 0)))
            
            do {
                let hyperionMessage = HyperionStruct(
                    command: "color",
                    priority: 100,
                    color: [
                        self.level,
                        self.level,
                        self.level
                    ],
                    origin: "musicsync"
                )
                
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                
                let data = try encoder.encode(hyperionMessage)
                let json = String(data: data, encoding: .utf8)
                //print(String(data: data, encoding: .utf8)!)
                
                let message = URLSessionWebSocketTask.Message.string(json!)
                
//                webSocket?.send(message) { error in
//                    if let error = error {
//                        print("WebSocket sending error: \(error)")
//                    }
//                }
                
            } catch {
                print("Oopsie doopsie")
            }
        
        })
    }
    
    // 8
    deinit {
        timer?.invalidate()
        audioRecorder.stop()
    }
}

