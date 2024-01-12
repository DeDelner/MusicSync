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
        self.ipAddress = UserDefaults.standard.object(forKey: "ipAddress") as? String
        self.entityId = UserDefaults.standard.object(forKey: "entityId") as? String
        self.sensivity = UserDefaults.standard.object(forKey: "sensivity") as? Float ?? 1.0
        self.offset = UserDefaults.standard.object(forKey: "offset") as? Float ?? 0.0
        self.maxElapsedTime = UserDefaults.standard.object(forKey: "maxElapsedTime") as? Double ?? 0.2
        self.instantEffectThreshold = UserDefaults.standard.object(forKey: "instantEffectThreshold") as? Float ?? 0.3
    }
    
    @Published var ipAddress: String? {
        didSet {
            UserDefaults.standard.set(ipAddress, forKey: "ipAddress")
        }
    }
    
    @Published var entityId: String? {
        didSet {
            UserDefaults.standard.set(entityId, forKey: "entityId")
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
    
    @Published var maxElapsedTime: Double {
        didSet {
            UserDefaults.standard.set(maxElapsedTime, forKey: "maxElapsedTime")
        }
    }
    
    @Published var instantEffectThreshold: Float {
        didSet {
            UserDefaults.standard.set(instantEffectThreshold, forKey: "instantEffectThreshold")
        }
    }

}
