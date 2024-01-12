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
    @Published public var status: String = "Disconnected"
    
    @ObservedObject var settingsManager = SettingsManager.shared
    
    func connect() throws {
        self.status = "Connecting..."
        guard let ip = settingsManager.ipAddress else {
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
    
    func sendMessage(message: [String: Any]) {
        do {
            var messageWithID = message
            if (self.status.elementsEqual("Authenticated")) {
                messageWithID["id"] = self.requestID
            }
            let jsonData = try JSONSerialization.data(withJSONObject: messageWithID, options: [])
            let jsonString = String(data: jsonData, encoding: .utf8)
            webSocket?.send(URLSessionWebSocketTask.Message.string(jsonString ?? "")) { error in
                if let error = error {
                    print("WebSocket sending error: \(error)")
                } else {
                    // Call receiveWebSocketMessage() after the message is sent
                    self.receiveResult()
                }
            }
            self.requestID += 1
        } catch {
            print("Error converting message to JSON: \(error)")
        }
    }
    
    private func receiveResult() {
        webSocket?.receive { result in
            DispatchQueue.main.async {
                switch result {
                case .failure(let error):
                    print("WebSocket receiving error: \(error)")
                case .success(let message):
                    switch message {
                    case .string(let text):
                        print("Received string: \(text)")
                        if text.contains("\"type\":\"auth_required\"") {
                            self.status = "Authenticating..."
                            if let bearerToken = KeychainHelper.load(key: "BearerToken") {
                                if let bearerTokenString = String(data: bearerToken, encoding: .utf8) {
                                    self.sendMessage(message:
                                                        [
                                                            "type": "auth",
                                                            "access_token": bearerTokenString
                                                        ]
                                    )
                                } else {
                                    print("Conversion to string failed")
                                }
                            } else {
                                self.status = "No bearer token provided"
                            }
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
