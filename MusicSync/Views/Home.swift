//
//  Home.swift
//  MusicSync
//
//  Created by Christian Langolf on 01/01/2024.
//

import SwiftUI

struct Home: View {
//    @ObservedObject private var mic = Microphone()
    @ObservedObject var webSocketManager = WebSocketManager.shared
    @ObservedObject var settingsManager = SettingsManager.shared
    
    @ObservedObject var audioProcessor = AudioProcessor.shared

    var body: some View {
        NavigationView {
            List {
                NavigationLink {
                    HassSettings()
                } label: {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 40, height: 40)
                            .foregroundColor(.blue)
                        VStack(alignment: .leading) {
                            Text("Home Assistant")
                            Text("Status: \(webSocketManager.status)")
                                .font(.footnote)
                        }
                    }
                }
                
                Section() {
                    NavigationLink {
                        MicrophoneSettings()
                    } label: {
                        Text("Microphone Settings")
                    }
                    NavigationLink {
                        EmptyView()
                    } label: {
                        Text("Sync Settings")
                    }
                }
                
                Section(header: Text("Monitoring")) {
                    Text("\(audioProcessor.rawAmpltiude)")
                    ProgressView(value: Double(audioProcessor.rawAmpltiude))
                        .scaleEffect(x: 1, y: 4, anchor: .center)
                        .padding(.bottom, 8)
                }

//                ProgressView(value: Double(mic.level[1]) / 255.0)
//                    .scaleEffect(x: 1, y: 4, anchor: .center)
//                    .padding(.bottom, 8)
            }
            .navigationTitle("MusicSync")
        }
    }
}

#Preview {
    Home()
}
