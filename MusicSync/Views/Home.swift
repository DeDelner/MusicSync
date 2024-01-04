//
//  Home.swift
//  MusicSync
//
//  Created by Christian Langolf on 01/01/2024.
//

import SwiftUI

struct Home: View {
//    @ObservedObject private var mic = Microphone()

    var body: some View {
        NavigationView {
            List {
                Section(header: Text("Home Assistant")) {
                    NavigationLink {
                        HassSettings()
                    } label: {
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .resizable()
                                .frame(width: 40, height: 40)
                                .foregroundColor(.blue)
                            Text("Home Assistant")
                        }
                    }
                }
                
                Section(header: Text("Microphone Settings")) {
                    NavigationLink {
                        EmptyView()
                    } label: {
                        Text("Navigation Link")
                    }
                }
                
//                ProgressView(value: Double(mic.level[0]) / 255.0)
//                    .scaleEffect(x: 1, y: 4, anchor: .center)
//                    .padding(.bottom, 8)
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
