//
//  MapListViewController.swift
//  MaineExplorer
//
//  Created by Emily Cheroske on 11/5/19.
//  Copyright © 2019 Emily Cheroske. All rights reserved.
//

import UIKit
import ArcGIS
import SwiftyJSON

class MapListViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, OfflineMapArea {

    private var maps = [AGSMap]()
    private var popupView = PopupViewController()
    private var offlineMapTask: AGSOfflineMapTask?
    private var selectedMap : AGSMap?
    private var currentJobs = [AGSPreplannedMapArea: AGSDownloadPreplannedOfflineMapJob]()
    var localMapPackages = [AGSMobileMapPackage]()
    
    @IBOutlet var mapList: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        configurePopupView()
        
        // Assign tableview delegates and data sources
        self.mapList.delegate = self
        self.mapList.dataSource = self
        self.mapList.register(UINib(nibName: "CustomMapCell", bundle: nil), forCellReuseIdentifier: "MapCell")
        self.mapList.separatorStyle = .none
        
        // Popup View delegate
        popupView.delegate = self
        
        view.sendSubviewToBack(self.mapList) /* Will cover up the popup if we don't send back */
        
        // Get our maps from our singleton map clss
        self.maps = MapClass.GetMaps()
    }
    
    // ************************************
    //MARK: - TableView DataSource Methods
    // ************************************
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MapCell", for: indexPath) as! CustomMapCell
        
        maps[indexPath.row].load(completion: {(error) in
            if let error = error {
                print(error.localizedDescription)
                return
            }
            
            cell.CustomMapCellHeader.text = self.maps[indexPath.row].item?.title
            
            self.maps[indexPath.row].item?.thumbnail?.load(completion: {(error) in
                if let error = error {
                    print(error.localizedDescription)
                    return
                }
                cell.ThumbnailImage.image = self.maps[indexPath.row].item?.thumbnail?.image
            })
        })
        
        // Define what to do when the user pushes the button to go to the map
        cell.mapTapAction = { (cell) in
            self.selectedMap = self.maps[indexPath.row]
            self.performSegue(withIdentifier: "openMap", sender: self)
        }
        
        // Define what to do when the user taps 'View Map Areas'
        cell.areaTapAction = { (cell) in
            self.openPopup(at: indexPath)
        }
        
        return cell
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.maps.count
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        openPopup(at: indexPath)
    }
    
    // ************************************
    //MARK: - Popup Related Methods
    // ************************************
    
    func openPopup(at indexPath : IndexPath) {
        if let title = maps[indexPath.row].item?.title {
            popupView.setHeaderText(text: title)
        }
        
        if let snippet = maps[indexPath.row].item?.snippet {
            popupView.setDescription(text: snippet)
        }
        
        // create the offline map task from selected map
        self.offlineMapTask = AGSOfflineMapTask(onlineMap: (maps[indexPath.row]))
                        
        // get all of the preplanned map areas in the web map and pass to our popup view
        self.offlineMapTask?.getPreplannedMapAreas(completion: {[weak self] (mapAreas, error) in
             if let error = error {
                print(error.localizedDescription)
             }
            
             guard mapAreas != nil else {
                  print("No map areas")
                  return
             }
           
             if let mapAreas = mapAreas {
                self?.popupView.setTableSource(items: mapAreas)
            }
        })
        
        UIView.animate(withDuration: 0.10) { [weak self] in
            let frame = self?.view.frame
            let yComponent = UIScreen.main.bounds.height - CGFloat(self!.popupView.popupInitialHeight)
            self?.popupView.view.frame = CGRect(x: 0, y: yComponent, width: frame!.width, height: frame!.height)
        }
    }
    
    func configurePopupView() {
        
        self.addChild(self.popupView)
        self.view.addSubview(self.popupView.view)
        self.popupView.didMove(toParent: self)

        // Adjust bottomSheet frame and initial position.
        let height = view.frame.height
        let width  = view.frame.width
        popupView.view.frame = CGRect(x: 0, y: self.view.frame.maxY, width: width, height: height)
    }
    
    // ************************************
    //MARK: - Download Map Area Methods
    // ************************************
    
    func downloadMapArea(mapArea: AGSPreplannedMapArea, tableIndex: IndexPath) {
        var localPackage : AGSMobileMapPackage?
        
        for mapPackage in localMapPackages {
            if mapPackage.fileURL.path.contains(mapArea.portalItemIdentifier) {
                localPackage = mapPackage
            }
        }
        
        if let mapPackage = localPackage {
            self.selectedMap = mapPackage.maps.first
            performSegue(withIdentifier: "openMap", sender: nil)
        } else {
            downloadPreplannedMapArea(mapArea, at: tableIndex)
        }
    }
    
    private func downloadPreplannedMapArea(_ area: AGSPreplannedMapArea, at indexPath: IndexPath) {
        guard currentJobs[area] == nil else { return }
        
        if offlineMapTask == nil {
            offlineMapTask = AGSOfflineMapTask(onlineMap: MapClass.map)
        }
        
        guard let task = offlineMapTask else { return }
        
        try? FileManager.default.removeItem(at: area.mapPackageURL)
        
        let job = task.downloadPreplannedOfflineMapJob(with: area, downloadDirectory: area.mapPackageURL)
        currentJobs[area] = job
        
        /* Grab our popup cell and display loading progress */
        let cell = popupView.table.cellForRow(at: indexPath) as? MapAreaCell
        cell?.ProgressBar.isHidden = false
        cell?.ProgressBar.observedProgress = job.progress
        
        job.start(statusHandler: nil) { [weak self] (result, error) in
            guard let self = self else { return }
            
            if let result = result {
                /* Hide Download Progress Bar and change icon to a view icon */
                cell?.ProgressBar.isHidden = true
                cell?.DownloadButton.setImage(UIImage(systemName: "eye"), for: .normal)
                
                self.downloadPreplannedOfflineMapJob(job, didFinishWith: .success(result))
            } else if let error = error {
                self.downloadPreplannedOfflineMapJob(job, didFinishWith: .failure(error))
            }
        }
    }
    
    func downloadPreplannedOfflineMapJob(_ job: AGSDownloadPreplannedOfflineMapJob, didFinishWith result: Result<AGSDownloadPreplannedOfflineMapResult, Error>) {
        
        switch result {
            case .success(let result):
                let localMapPackage = result.mobileMapPackage
                
                localMapPackages.append(localMapPackage)
                
                /* Select the result of our downloaded map and open in Map View*/
                selectedMap = result.offlineMap
                
                performSegue(withIdentifier: "openMap", sender: self)
            
            case .failure(let error):
                print("Couldn't download the map area: \(error.localizedDescription)")
        }
        
    }
    
    // ************************************
    //MARK: - Prepare for Segue Method
    // ************************************
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if(segue.identifier == "openMap") {
            let destinationVC = segue.destination as! ViewController
            destinationVC.map = self.selectedMap
        }
    }
}

private extension AGSPreplannedMapArea {
    var mapPackageURL: URL {
        let documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        return documentsDirectoryURL.appendingPathComponent(portalItemIdentifier).appendingPathExtension("mmpk")
    }
    
    var portalItemIdentifier: String {
        return portalItem?.itemID ?? "-"
    }
}
