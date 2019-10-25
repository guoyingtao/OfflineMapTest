//
//  UserService.swift
//  MapTest
//
//  Created by Echo on 10/24/19.
//  Copyright © 2019 Echo. All rights reserved.
//

import Foundation

struct OfflineMapInfo {
    var id = "" // To be used for checking if the map has been saved locally before.
    var name = ""
    var latitude = 0.0
    var longitude = 0.0
    var fromZoomLevel = 13.0
    var toZoomLevel = 22.0
}

class UserService {
    static var shared = UserService()
    
    func getOfflineMapInfo()-> OfflineMapInfo {
        return OfflineMapInfo(id: "map1", name: "Demo Town", latitude: 39.27428194655781, longitude: -86.65741377829723, fromZoomLevel: 13.0, toZoomLevel: 22.0)
    }
    
    private init() {
        
    }
}
