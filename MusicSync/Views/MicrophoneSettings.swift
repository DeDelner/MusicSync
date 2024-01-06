//
//  MicrophoneSettings.swift
//  MusicSync
//
//  Created by Christian Langolf on 05/01/2024.
//

import SwiftUI

struct MicrophoneSettings: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    @ObservedObject var audioProcessor = AudioProcessor.shared
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Monitoring")) {
                    Text("Raw: \(Int(audioProcessor.rawAmpltiude * 100)) %")
                    ProgressView(value: Double(audioProcessor.rawAmpltiude))
                        .scaleEffect(x: 1, y: 4, anchor: .center)
                    Text("Bass: \(Int(audioProcessor.bassAmpltiude * 100)) %")
                    ProgressView(value: Double(audioProcessor.bassAmpltiude))
                        .scaleEffect(x: 1, y: 4, anchor: .center)
                }
                
                Section(header: Text("Sensivity")) {
                    HStack {
                        Slider(
                            value: $settingsManager.sensivity,
                            in: 0...2,
                            step: 0.1
                        )
                        Text("\(Int(settingsManager.sensivity * 100))%").frame(width: 50)
                    }
                }

                Section(header: Text("Offset")) {
                    HStack {
                        Slider(
                            value: $settingsManager.offset,
                            in: -1...1,
                            step: 0.1
                        )
                        Text("\(settingsManager.offset.formatted())").frame(width: 50)
                    }
                }
            }
        }.navigationTitle("Microphone")
    }
}

#Preview {
    MicrophoneSettings()
}
