//
//  HassSettings.swift
//  MusicSync
//
//  Created by Christian Langolf on 01/01/2024.
//

import Security
import SwiftUI

struct HassSettings: View {
    @State private var ipAddress = ""
    @State private var bearerToken = ""
    @State private var entityId = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoading = false
    
    @ObservedObject var webSocketManager = WebSocketManager.shared
    @ObservedObject var settingsManager = SettingsManager.shared

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Connection")) {
                    ClearableTextField(placeholder: "IP Address or Local Hostname", text: $ipAddress)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                    ClearableTextField(placeholder: "Bearer Token", text: $bearerToken)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Section(header: Text("Entity")) {
                    ClearableTextField(placeholder: "Entity ID", text: $entityId)
                        .autocapitalization(.none)
                        .disableAutocorrection(true)
                }

                Button("Test Connection") {
                    isLoading = true
                    do {
                        try saveSettings()
                        try webSocketManager.connect()
                        isLoading = false
                    } catch {
                        alertMessage = error.localizedDescription
                        showingAlert = true
                        isLoading = false
                    }
                }.disabled(isLoading)
                
                if isLoading {
                    ProgressView()
                }

                Text("Status: \(webSocketManager.status)")
            }
            .alert(isPresented: $showingAlert) {
                Alert(title: Text("Error"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
            }
        }
        .navigationTitle("Home Assistant")
        .onAppear {
            loadSettings()
        }
    }

    func saveSettings() throws {
        if validateIpAddress(ipAddress: ipAddress) {
            settingsManager.ipAddress = ipAddress
            settingsManager.entityId = entityId
            if let tokenData = bearerToken.data(using: .utf8) {
                let status = KeychainHelper.save(key: "BearerToken", data: tokenData)
                print(status == noErr ? "Token saved successfully" : "Failed to save Token")
            }
        } else {
            throw NSError(domain: "", code: 0, userInfo: [NSLocalizedDescriptionKey : "Invalid IP address or port. It cannot start with http:// or https:// (for now)"])
        }
    }

    func validateIpAddress(ipAddress: String) -> Bool {
        if !ipAddress.hasPrefix("https") && !ipAddress.hasPrefix("http") {
            let urlComponents = URLComponents(string: "http://\(ipAddress)")
            if let host = urlComponents?.host, let port = urlComponents?.port {
                let ipAndPort = "\(host):\(port)"
                return ipAddress.contains(ipAndPort)
            }
        }
        return false
    }

    func loadSettings() {
        ipAddress = settingsManager.ipAddress ?? ""
        entityId = settingsManager.entityId ?? ""
        if let token = KeychainHelper.load(key: "BearerToken") {
            bearerToken = String(decoding: token, as: UTF8.self)
        }
    }

}

#Preview {
    HassSettings()
}
