//
//  SettingsManager.swift
//  MusicSync
//
//  Created by Christian Langolf on 04/01/2024.
//

import Foundation

class SettingsManager: ObservableObject {
    static var shared = SettingsManager()
    
    init() {
        self.sensivity = UserDefaults.standard.float(forKey: "sensivity")
        self.offset = UserDefaults.standard.float(forKey: "offset")
    }
    
    static var ipAddress: String? {
        get {
            return UserDefaults.standard.string(forKey: "ipAddress")
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: "ipAddress")
        }
    }
    
    static var entityId: String? {
        get {
            return UserDefaults.standard.string(forKey: "entityId")
        }
        set(value) {
            UserDefaults.standard.set(value, forKey: "entityId")
        }
    }
    
    @Published var sensivity: Float {
        didSet {
            UserDefaults.standard.set(sensivity, forKey: "sensivity")
        }
    }
    
    @Published var offset: Float {
        didSet {
            UserDefaults.standard.set(offset, forKey: "offset")
        }
    }

}
