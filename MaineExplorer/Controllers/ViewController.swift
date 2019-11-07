//
//  ViewController.swift
//  MaineExplorer
//
//  Created by Emily Cheroske on 11/5/19.
//  Copyright © 2019 Emily Cheroske. All rights reserved.
//

import UIKit
import ArcGIS

class ViewController: UIViewController {
    @IBOutlet weak var mapView: AGSMapView!
    
    public var map: AGSMap?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if let selectedMap = map {
            self.mapView.map = selectedMap
        } else {
            self.mapView.map = MapClass.map // default to Main map in map class
        }
        
    }
}

