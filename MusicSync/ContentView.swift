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
        VStack {
            ProgressView(value: Double(mic.level[0]) / 255.0)
            ProgressView(value: Double(mic.level[1]) / 255.0)
            HStack(spacing: 4) {
                Text(String(mic.level[0]))
                Text(String(mic.level[1]))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
