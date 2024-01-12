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
                        Text("\(settingsManager.maxElapsedTime)ms").frame(width: 50)
                    }
                    Text("In what interval the lights should be synced.")
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
                    Text("At how much volume % the effect should be applied immediately, no matter the interval time. Ideal for bass kicks.")
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
