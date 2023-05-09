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
            HStack(spacing: 4) {
                Text(String(mic.level))
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
