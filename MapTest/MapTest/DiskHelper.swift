//
//  DiskHelper.swift
//  MapTest
//
//  Created by Echo on 10/25/19.
//  Copyright © 2019 Echo. All rights reserved.
//

import Foundation

struct DiskHelper {
    
    static let minimumRequiredDiskSpace: Int64 = 100 * 1024 * 1024 // 100Mb
    
    // The return result is bytes
    static func getAvailableDiskSpace() -> Int64 {
        // Mapbox saves its offline map into Application Support directory
        let fileURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        do {
            let values = try fileURL.resourceValues(forKeys: [.volumeAvailableCapacityForImportantUsageKey])
            if let capacity = values.volumeAvailableCapacityForImportantUsage {
                return capacity
            } else {
                print("Capacity is unavailable")
                return 0
            }
        } catch {
            print("Error retrieving capacity: \(error.localizedDescription)")
            return 0
        }
    }
    
    static func remainingDiskSpaceDescription() -> String {        
        let remainingSpace = getAvailableDiskSpace()
        return "Available Space: \(ByteCountFormatter.string(fromByteCount: remainingSpace, countStyle: .file))"
    }
    
    static func getMinimumRequiredDiskSpaceDescription() -> String {
        return (ByteCountFormatter.string(fromByteCount: self.minimumRequiredDiskSpace, countStyle: .file))
    }
    
    static func hasMinimumDiskSpace() -> Bool {
        return getAvailableDiskSpace() >= minimumRequiredDiskSpace
    }    
}
