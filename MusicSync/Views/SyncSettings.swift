//
//  SyncSettings.swift
//  MusicSync
//
//  Created by Christian Langolf on 07/01/2024.
//

import SwiftUI

struct SyncSettings: View {
    @ObservedObject var settingsManager = SettingsManager.shared
    
    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Interval Time")) {
                    HStack {
                        Slider(
                            value: $settingsManager.maxElapsedTime,
                            in: 0.1...1.0,
                            step: 0.01
                        )
                        Text(String(format: "%.0fms", settingsManager.maxElapsedTime * 1000)).frame(width: 62)
                    }
                    Text("Define the time interval for synchronizing the lights.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }

                
                Section(header: Text("Instant Effect Threshold")) {
                    HStack {
                        Slider(
                            value: $settingsManager.instantEffectThreshold,
                            in: 0.0...1.0,
                            step: 0.05
                        )
                        Text("\(Int(settingsManager.instantEffectThreshold * 100))%").frame(width: 50)
                    }
                    Text("Specify the volume % at which the lights should be synced immediatetly, regardless of the interval time. This is particularly effective for bass kicks.")
                        .font(.footnote)
                        .foregroundColor(.gray)
                }
            }
        }.navigationTitle("Sync Settings")
    }
}

#Preview {
    SyncSettings()
}
