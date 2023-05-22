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
    private var colors: [UIColor]
    
    // 2
    @Published public var level: [Int]
    @Published public var offset: Double
    @Published public var sensivity: Double
    @Published public var status: String
    
    init() {
        self.level = [0, 0]
        self.degree = 0.0
        self.offset = 0
        self.sensivity = 0
        self.status = "Not connected"
        self.colors = [
            UIColor(red: 255, green: 0, blue: 0, alpha: 1),
            UIColor(red: 200, green: 50, blue: 0, alpha: 1),
            UIColor(red: 150, green: 100, blue: 50, alpha: 1)
        ]
        
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
        let level = max(0.0, CGFloat(level) + 50)
        //let sensivity = CGFloat(300.0 + self.sensivity);
        let sensivity = CGFloat(300.0);
        
        return CGFloat(min(max((pow(level, 3) / sensivity) + offset, 0), 255))
    }
    
    private func bassSoundLevel(level: Float) -> CGFloat {
        let level = max(0.0, CGFloat(level) + 50)
        let sensivity = CGFloat(300.0 + self.sensivity);
        
        return CGFloat(min(max((pow(level, 3) / sensivity) - 255 + offset, 0), 255))
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
            
            //self.sendDataForInstance(instance: 1)
            self.sendDataForInstance(instance: 0)
        })
    }
    
    private func sendData(hyperionMessage: Codable) {
        do {
            let encoder = JSONEncoder()
            encoder.outputFormatting = .prettyPrinted
            
            let data = try encoder.encode(hyperionMessage)
            let json = String(data: data, encoding: .utf8)
            
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
        //self.sendData(hyperionMessage: switchTo)
        
        colors[0] = colors[0].adjust(hueBy: CGFloat(self.level[1]) * 0.00002)
        //colors[1] = colors[1].adjust(hueBy: CGFloat(self.level[1]) * 0.00002)
        //colors[2] = colors[2].adjust(hueBy: CGFloat(self.level[1]) * 0.00002)
        
        var newColor1 = UIColor(.black).mixin(infusion: colors[0], alpha: CGFloat(self.level[0]) * 0.5 / 255)
        newColor1 = newColor1.mixin(infusion: UIColor(red: 255, green: 255, blue: 255, alpha: 255), alpha: CGFloat(self.level[1]) / 255)
//
//        var newColor2 = UIColor(.black).mixin(infusion: colors[1], alpha: CGFloat(self.level[0]) / 255)
//        newColor2 = newColor2.mixin(infusion: UIColor(red: 255, green: 255, blue: 255, alpha: 255), alpha: CGFloat(self.level[1]) / 255)
//
//        var newColor3 = UIColor(.black).mixin(infusion: colors[2], alpha: CGFloat(self.level[0]) / 255)
//        newColor3 = newColor3.mixin(infusion: UIColor(red: 255, green: 255, blue: 255, alpha: 255), alpha: CGFloat(self.level[1]) / 255)
        
        let color = HyperionColorStruct(
            command: "color",
            priority: 100,
            color: [
                Int(newColor1.rgba.red),
                Int(newColor1.rgba.green),
                Int(newColor1.rgba.blue)
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
