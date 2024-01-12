//
//  AudioProcessor.swift
//  MusicSync
//
//  Created by Christian Langolf on 05/01/2024.
//

import Foundation
import SwiftUI

class AudioProcessor: ObservableObject {
    static var shared = AudioProcessor()
    
    @ObservedObject var settingsManager = SettingsManager.shared
    @ObservedObject var microphone = Microphone.shared
    @ObservedObject var websocketManager = WebSocketManager.shared
    
    private var timer: Timer?
    
    private var previousVolumeLevel: Float = 0.0
    private var lastRequestTime: Date = Date()
    
    @Published public var rawAmpltiude: Float = 0.0
    @Published public var bassAmpltiude: Float = 0.0
    
    // Constans
    private final var TIMER_INTERVAL: Double = 0.01
    
    public func start() {
        if (settingsManager.entityId != "") {
            timer = Timer.scheduledTimer(withTimeInterval: TIMER_INTERVAL, repeats: true, block: { (timer) in
                self.rawAmpltiude = min(max((self.microphone.normalizedLevel - self.settingsManager.offset) * (0.5 + self.settingsManager.sensivity * 0.5), 0.0), 1.0)
                self.bassAmpltiude = min(pow(max((self.microphone.normalizedLevel - self.settingsManager.offset) * (0.5 + self.settingsManager.sensivity * 0.5), 0.0), 6.0) * 64.0, 1.0)
                
                
                let deltaVolumeLevel = self.bassAmpltiude - self.previousVolumeLevel
                let timeSinceLastRequest = Date().timeIntervalSince(self.lastRequestTime)
                
                if (deltaVolumeLevel > self.settingsManager.instantEffectThreshold || timeSinceLastRequest >= self.settingsManager.maxElapsedTime) {
                    self.sendColorToHomeAssistant(level: self.bassAmpltiude, deltaLevel: deltaVolumeLevel)
                    self.previousVolumeLevel = self.bassAmpltiude
                    self.lastRequestTime = Date()
                }
            })
        } else {
            self.stop()
        }
    }
    
    public func stop() {
        timer?.invalidate()
        timer = nil
        rawAmpltiude = 0.0
        bassAmpltiude = 0.0
    }
    
    private func sendColorToHomeAssistant(level: Float, deltaLevel: Float) {
        if (self.websocketManager.status.elementsEqual("Authenticated")) {
            let rgb = [
                255,
                255,
                255
            ]
            
            let transitionTime = deltaLevel > self.settingsManager.instantEffectThreshold ? 0 : self.settingsManager.maxElapsedTime
            
            let message: [String: Any] = [
                "type": "call_service",
                "domain": "light",
                "service": "turn_on",
                "service_data": [
                    "entity_id": settingsManager.entityId,
                    "rgb_color": rgb,
                    "brightness": Int(level * 255),
                    "transition": transitionTime
                ]
            ]
            
            websocketManager.sendMessage(message: message)
        }
    }
    
}
