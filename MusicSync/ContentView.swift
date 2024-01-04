//
//  ContentView.swift
//  MusicSync
//
//  Created by Christian Langolf on 08/05/2023.
//


import SwiftUI

struct ContentView: View {
    @ObservedObject private var mic = Microphone()

    var body: some View {
        NavigationView {
            VStack(alignment: .leading) {
                List {
                    Section {
                        Label("Sun", systemImage: "sun.max")
                        Label("Cloud", systemImage: "cloud")
                        Label("Rain", systemImage: "cloud.rain")
                    }
                }.listStyle(.automatic)
                Text("Status: \(mic.status)")
                Text("Offset: \(Int(mic.offset))")
                Slider(
                    value: $mic.offset,
                    in: -300...300
                )
                Text("Sensivity: \(Int(mic.sensivity))")
                Slider(
                    value: $mic.sensivity,
                    in: -100...100
                )
                Text("Levels: \(mic.level[0]) \(mic.level[1])")
                ProgressView(value: Double(mic.level[0]) / 255.0)
                    .scaleEffect(x: 1, y: 4, anchor: .center)
                    .padding(.bottom, 8)
                ProgressView(value: Double(mic.level[1]) / 255.0)
                    .scaleEffect(x: 1, y: 4, anchor: .center)
                    .padding(.bottom, 8)
            }.padding(25).navigationTitle("MusicSync")
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
