//
//  Microphone.swift
//  MusicSync
//
//  Created by Christian Langolf on 08/05/2023.
//

import Foundation
import AVFoundation
import SwiftUI

class Microphone: ObservableObject {
    private var audioRecorder: AVAudioRecorder
    private var timer: Timer?
    private var colors: [UIColor]
    private var webSocket: URLSessionWebSocketTask?
    private var requestID = 1
    private var previousVolumeLevel: CGFloat = 0.0
    private var lastRequestTime: Date = Date()

    @Published public var level: [Int]
    @Published public var offset: Double
    @Published public var sensivity: Double
    @Published public var status: String

    init() {
        self.level = [0, 0]
        self.offset = 0
        self.sensivity = 0
        self.status = "Not connected"
        self.colors = [
            UIColor(red: 255, green: 0, blue: 0, alpha: 1),
            UIColor(red: 200, green: 50, blue: 0, alpha: 1),
            UIColor(red: 150, green: 100, blue: 50, alpha: 1)
        ]

        let audioSession = AVAudioSession.sharedInstance()
        if audioSession.recordPermission != .granted {
            audioSession.requestRecordPermission { (isGranted) in
                if !isGranted {
                    fatalError("You must allow audio recording for this demo to work")
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
            
            webSocket = URLSession.shared.webSocketTask(with: URL(string: "ws://192.168.0.207:8123/api/websocket")!)
            webSocket?.resume()
            receiveWebSocketMessage()
            
            startMonitoring()
        } catch {
            fatalError(error.localizedDescription)
        }
    }
    
    private func normalizeSoundLevel(level: Float) -> CGFloat {
        let level = max(0.0, CGFloat(level) + 50)
        let sensivity = CGFloat(300.0);
        
        return CGFloat(min(max((pow(level, 3) / sensivity) + offset, 0), 255))
    }
    
    private func bassSoundLevel(level: Float) -> CGFloat {
        let level = max(0.0, CGFloat(level) + 50)
        let sensivity = CGFloat(300.0 + self.sensivity);
        
        return CGFloat(min(max((pow(level, 3) / sensivity) - 255 + offset, 0), 255))
    }
    
    private func startMonitoring() {
        audioRecorder.isMeteringEnabled = true
        audioRecorder.record()
        timer = Timer.scheduledTimer(withTimeInterval: 0.01, repeats: true, block: { (timer) in
            self.audioRecorder.updateMeters()
            
            self.level[0] = Int(self.normalizeSoundLevel(level: self.audioRecorder.averagePower(forChannel: 0)))
            self.level[1] = Int(self.bassSoundLevel(level: self.audioRecorder.averagePower(forChannel: 0)))
            
            let currentVolumeLevel = CGFloat(self.level[0] + self.level[1])
            let deltaVolumeLevel = currentVolumeLevel - self.previousVolumeLevel
            let timeSinceLastRequest = Date().timeIntervalSince(self.lastRequestTime)
            
            let volumeThreshold: CGFloat = 10.0
            
            if (deltaVolumeLevel > 50.0 || timeSinceLastRequest >= 0.2) {
                self.sendColorToHomeAssistant(level: deltaVolumeLevel)
                self.previousVolumeLevel = currentVolumeLevel
                self.lastRequestTime = Date()
            }
        })
    }
    
    private func sendColorToHomeAssistant(level: CGFloat) {
        colors[0] = colors[0].adjust(hueBy: CGFloat(self.level[1]) * 0.001)
        
        var newColor = UIColor(.black).mixin(infusion: colors[0], alpha: CGFloat(self.level[0]) * 0.5 / 255)
        newColor = newColor.mixin(infusion: UIColor(red: 255, green: 255, blue: 255, alpha: 255), alpha: CGFloat(self.level[1]) / 255)
        
        let rgb = [
            Int(newColor.rgba.red),
            Int(newColor.rgba.green),
            Int(newColor.rgba.blue)
        ]
        
        let transitionTime = level > 50.0 ? 0 : 0.1

        webSocket?.send(URLSessionWebSocketTask.Message.string("""
        {
            "id": \(self.requestID),
            "type": "call_service",
            "domain": "light",
            "service": "turn_on",
            "service_data": {
                "entity_id": "light.musicsync",
                "rgb_color": \(rgb),
                "brightness": \(self.level[0] + 5),
                "transition": \(transitionTime)
            }
        }
        """)) { error in
            if let error = error {
                print("WebSocket sending error: \(error)")
            }
        }
        self.requestID += 1
    }
    
    private func receiveWebSocketMessage() {
        webSocket?.receive { result in
            switch result {
            case .failure(let error):
                print("WebSocket receiving error: \(error)")
            case .success(let message):
                switch message {
                case .string(let text):
                    print("Received string: \(text)")
                    if text.contains("\"type\":\"auth_required\"") {
                        self.webSocket?.send(URLSessionWebSocketTask.Message.string("""
                        {
                            "type": "auth",
                            "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiIyNzk2YWY3MDhlMDQ0ZDBkYmJhZDU2MjNjNWU1ZTE0MCIsImlhdCI6MTY5ODYwMzQ0MiwiZXhwIjoyMDEzOTYzNDQyfQ.Uhx7zBrjcjv6OR7KOVp72586LqKzeuIt9l1-GQ3wh6A"
                        }
                        """)) { error in
                            if let error = error {
                                print("WebSocket sending error: \(error)")
                            }
                        }
                    } else if text.contains("\"type\":\"auth_ok\"") {
                        self.status = "Connected"
                    }
                case .data(let data):
                    print("Received data: \(data)")
                @unknown default:
                    print("Unknown message type")
                }
            }
        }
    }
    
    deinit {
        timer?.invalidate()
        audioRecorder.stop()
        webSocket?.cancel(with: .normalClosure, reason: nil)
    }
}



extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)

        return (red, green, blue, alpha)
    }

    func mixin(infusion:UIColor, alpha:CGFloat) -> UIColor {
        let alpha2 = min(1.0, max(0, alpha))
        let beta = 1.0 - alpha2

        var r1:CGFloat = 0, r2:CGFloat = 0
        var g1:CGFloat = 0, g2:CGFloat = 0
        var b1:CGFloat = 0, b2:CGFloat = 0
        var a1:CGFloat = 0, a2:CGFloat = 0
        if getRed(&r1, green: &g1, blue: &b1, alpha: &a1) &&
            infusion.getRed(&r2, green: &g2, blue: &b2, alpha: &a2)
        {
            let red     = r1 * beta + r2 * alpha2;
            let green   = g1 * beta + g2 * alpha2;
            let blue    = b1 * beta + b2 * alpha2;
            let alpha   = a1 * beta + a2 * alpha2;
            return UIColor(red: red, green: green, blue: blue, alpha: alpha)
        }
        // epique de las failuree
        return self
    }
    
    public func adjust(hueBy hue: CGFloat = 0, saturationBy saturation: CGFloat = 0, brightnessBy brightness: CGFloat = 0) -> UIColor {
        var currentHue: CGFloat = 0.0
        var currentSaturation: CGFloat = 0.0
        var currentBrigthness: CGFloat = 0.0
        var currentAlpha: CGFloat = 0.0

        if getHue(&currentHue, saturation: &currentSaturation, brightness: &currentBrigthness, alpha: &currentAlpha) {
            return UIColor(hue: currentHue + hue,
                       saturation: currentSaturation + saturation,
                       brightness: currentBrigthness + brightness,
                       alpha: currentAlpha)
        } else {
            return self
        }
    }
}
