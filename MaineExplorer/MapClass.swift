//
//  MapClass.swift
//  MaineExplorer
//
//  Created by Emily Cheroske on 11/5/19.
//  Copyright © 2019 Emily Cheroske. All rights reserved.
//
import ArcGIS

class MapClass {
    
    private var offlineMapTask: AGSOfflineMapTask?
    
    static let map : AGSMap = AGSMap(url: URL(string: "https://www.arcgis.com/home/webmap/viewer.html?webmap=3bc3179f17da44a0ac0bfdac4ad15664")!)!
    
    static func GetMaps() -> [AGSMap] {
        print(map.basemap.name)
        return [map]
    }
    
}
