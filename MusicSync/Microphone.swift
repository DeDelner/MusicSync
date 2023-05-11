//
//  Microphone.swift
//  MusicSync
//
//  Created by Christian Langolf on 08/05/2023.
//

import Foundation
import AVFoundation

class Microphone: ObservableObject {
    
    struct HyperionColorStruct: Codable {
        var command: String
        var priority: Int
        var color: [Int]
        var origin: String
    }
    
    struct HyperionInstanceStruct: Codable {
        var command: String
        var subcommand: String
        var instance: Int
    }
    
    // 1
    private var audioRecorder: AVAudioRecorder
    private var timer: Timer?
    private var degree: Double
    private var webSocket: URLSessionWebSocketTask?
    
    // 2
    @Published public var level: [Int]
    @Published public var offset: Double
    @Published public var status: String
    
    init() {
        self.level = [0, 0]
        self.degree = 0.0
        self.offset = 0
        self.status = "Not connected"
        
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
            try audioSession.setCategory(.playAndRecord, mode: .default, options: [])
            
            startMonitoring()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    
    private func normalizeSoundLevel(level: Float) -> CGFloat {
        let level = max(0.0, CGFloat(level) + 50) // between 0.0 and 25
        
        return CGFloat(min(max((pow(level, 3) / 300) + self.offset, 0), 255)) // scaled to max at 255 (our height of our bar)
    }
    
    private func bassSoundLevel(level: Float) -> CGFloat {
        let level = max(0.0, CGFloat(level) + 50) // between 0.0 and 25
        
        return CGFloat(min(max((pow(level, 3) / 300) - 255 + self.offset, 0), 255)) // scaled to max at 255 (our height of our bar)
    }
    
    // 6
    private func startMonitoring() {
        
        //Session
        let session = URLSession(configuration: .default)
        
        //Server API
        let url = URL(string:  "ws://192.168.0.206:8090")
        
        //Socket
        webSocket = session.webSocketTask(with: url!)
        
        //Connect and hanles handshake
        webSocket?.resume()
        
        func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didOpenWithProtocol protocol: String?) {
            status = "Connected to server"
        }
        
        func urlSession(_ session: URLSession, webSocketTask: URLSessionWebSocketTask, didCloseWith closeCode: URLSessionWebSocketTask.CloseCode, reason: Data?) {
            status = "Disconnect from Server"
        }
        
        audioRecorder.isMeteringEnabled = true
        audioRecorder.record()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            // 7
            self.audioRecorder.updateMeters()
            
            if (self.degree < 360) {
                self.degree += 0.0001
            } else{
                self.degree = 0
            }
            
            self.level[0] = Int(self.normalizeSoundLevel(level: self.audioRecorder.averagePower(forChannel: 0)))
            self.level[1] = Int(self.bassSoundLevel(level: self.audioRecorder.averagePower(forChannel: 0)))
            
            self.sendDataForInstance(instance: 1)
            self.sendDataForInstance(instance: 0)
        })
    }
    
    private func sendData(hyperionMessage: Codable) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(hyperionMessage)
            let json = String(data: data, encoding: .utf8)
            //print(String(data: data, encoding: .utf8)!)
            
            let message = URLSessionWebSocketTask.Message.string(json!)
            
            webSocket?.send(message) { error in
                if let error = error {
                    print("WebSocket sending error: \(error)")
                }
            }
        } catch {
            print("Oopsie doopsie")
        }
    }
    
    private func sendDataForInstance(instance: Int) {
        let switchTo = HyperionInstanceStruct(command: "instance", subcommand: "switchTo", instance: instance)
        self.sendData(hyperionMessage: switchTo)
        
        let color = HyperionColorStruct(
            command: "color",
            priority: 100,
            color: [
                self.level[0],
                self.level[1],
                self.level[0]
            ],
            origin: "musicsync"
        )
        self.sendData(hyperionMessage: color)
    }
    
    // 8
    deinit {
        timer?.invalidate()
        audioRecorder.stop()
    }
}
