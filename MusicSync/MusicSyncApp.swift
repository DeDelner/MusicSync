//
//  MusicSyncApp.swift
//  MusicSync
//
//  Created by Christian Langolf on 08/05/2023.
//

import SwiftUI

@main
struct MusicSyncApp: App {
    @ObservedObject var webSocketManager = WebSocketManager.shared
    
    init() {
        do {
            try webSocketManager.connect()
        } catch {
            
        }
    }
    
    var body: some Scene {
        WindowGroup {
            Home()
        }
    }
}
