//
//  OfflineMapStorageHelper.swift
//  MapTest
//
//  Created by Echo on 10/25/19.
//  Copyright © 2019 Echo. All rights reserved.
//

import Foundation

fileprivate let defaults = UserDefaults.standard
fileprivate let offlineMapKey = "OfflineMapKey"
fileprivate let offlineMapSizeKey = "OfflineMapSizeKey"

struct OfflineMapStorageHelper {
    
    static func markMapSavedById(_ id: String) {
        defaults.set(id, forKey: offlineMapKey)
    }
    
    static func getSavedMapId() -> String? {
        guard let id = defaults.string(forKey: offlineMapKey) else {
            return nil
        }
        
        return id
    }
    
    static func isMapSavedById(_ id: String) -> Bool {
        if defaults.string(forKey: offlineMapKey) != nil {
            return true
        } else {
            return false
        }
    }
    
    static func removeMapSavedMarkById(_ id: String) {
        defaults.set(nil, forKey: offlineMapKey)
    }
    
    static func saveMapSizeInfo(_ sizeInfo: String) {
        defaults.set(sizeInfo, forKey: offlineMapSizeKey)
    }
    
    static func getSavedMapSizeInfo() -> String {
        guard let info = defaults.string(forKey: offlineMapSizeKey) else {
            return ""
        }
        
        return info
    }

}
