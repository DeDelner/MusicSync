//
//  WebSocketManager.swift
//  MusicSync
//
//  Created by Christian Langolf on 03/01/2024.
//

import Foundation
import AVFoundation
import SwiftUI

class WebSocketManager: ObservableObject {
    static var shared = WebSocketManager()
    
    private var webSocket: URLSessionWebSocketTask?
    private var requestID = 1
    @Published public var status: String = "Not connected"
    
    private var hassIP: String? {
        get {
            return UserDefaults.standard.string(forKey: "HassIP")
        }
    }
    
    func connect() throws {
        self.status = "Connecting..."
        guard let ip = hassIP else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "IP address not found"])
        }
        let url = URL(string: "ws://\(ip)/api/websocket")!
        webSocket = URLSession.shared.webSocketTask(with: url)
        webSocket?.resume()
        receiveResult()
    }
    
    func disconnect() {
        webSocket?.cancel(with: .normalClosure, reason: nil)
    }
    
    func sendMessage(message: String) {
        webSocket?.send(URLSessionWebSocketTask.Message.string(message)) { error in
            if let error = error {
                print("WebSocket sending error: \(error)")
            } else {
                // Call receiveWebSocketMessage() after the message is sent
                self.receiveResult()
            }
        }
        self.requestID += 1
    }
    
    private func receiveResult() {
        webSocket?.receive { result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    print("WebSocket receiving error: \(error)")
                case .success(let message):
                    self.status = "Connected"
                    switch message {
                    case .string(let text):
                        print("Received string: \(text)")
                        if text.contains("\"type\":\"auth_required\"") {
                            self.status = "Authenticating..."
                            self.sendMessage(message: """
                            {
                                "type": "auth",
                                "access_token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJkNTBiYTY3OTE0NmM0NjIyYjRmYzVlMDlmZWM4NGUzYiIsImlhdCI6MTcwNDMxMTgxMCwiZXhwIjoyMDE5NjcxODEwfQ.6fb9zkwo_xOw8FOV4Pz3Lmx7juPFQPSDn8MLwWIwogM"
                            }
                            """)
                        } else if text.contains("\"type\":\"auth_ok\"") {
                            self.status = "Authenticated"
                        }
                    case .data(let data):
                        print("Received data: \(data)")
                    @unknown default:
                        print("Unknown message type")
                    }
                }
            }
        }
    }
}
