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
    
    private var timer: Timer?
    
    private var volumeThreshold: Float = 50.0
    private var previousVolumeLevel: Float = 0.0
    private var lastRequestTime: Date = Date()
    
    @Published public var rawAmpltiude: Float = 0.0
    @Published public var bassAmpltiude: Float = 0.0
    
    // Constans
    private final var TIMER_INTERVAL: Double = 0.01
    private final var MAX_ELAPSED_TIME: Double = 0.2
    
    init() {
        timer = Timer.scheduledTimer(withTimeInterval: TIMER_INTERVAL, repeats: true, block: { (timer) in
            self.rawAmpltiude = min(max((self.microphone.normalizedLevel - self.settingsManager.offset) * (0.5 + self.settingsManager.sensivity * 0.5), 0.0), 1.0)
            self.bassAmpltiude = min(pow(max((self.microphone.normalizedLevel - self.settingsManager.offset) * (0.5 + self.settingsManager.sensivity * 0.5), 0.0), 6.0) * 64.0, 1.0)
            
            
            let deltaVolumeLevel = self.rawAmpltiude - self.previousVolumeLevel
            let timeSinceLastRequest = Date().timeIntervalSince(self.lastRequestTime)
            
            if (deltaVolumeLevel > self.volumeThreshold || timeSinceLastRequest >= self.MAX_ELAPSED_TIME) {
//                self.sendColorToHomeAssistant(level: deltaVolumeLevel)
                self.previousVolumeLevel = self.rawAmpltiude
                self.lastRequestTime = Date()
            }
        })
    }
    
}
