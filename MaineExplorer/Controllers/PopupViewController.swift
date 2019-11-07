//
//  PopupViewController
//  MaineExplorer
//
//  Created by Emily Cheroske on 11/5/19.
//  Copyright © 2019 Emily Cheroske. All rights reserved.
//

import UIKit
import ArcGIS

protocol OfflineMapArea {
    func downloadMapArea(mapArea : AGSPreplannedMapArea, tableIndex : IndexPath)
}

class PopupViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    /* Text properties */
    var button : UIButton?
    var headerText : UILabel?
    var descriptionText : UILabel?
    var table : UITableView = UITableView()
    
    var mapAreas = [AGSPreplannedMapArea]()
    
    var delegate : OfflineMapArea?
    
    var popupInitialHeight : Int = 330
    
    var buttonIsRotated: Bool = true {
        didSet {
            UIView.animate(withDuration: 0.25) {
                if self.buttonIsRotated {
                    self.button!.transform = CGAffineTransform.identity
                } else {
                    self.button!.transform = CGAffineTransform(rotationAngle: -CGFloat.pi)
                }
            }
        }
    }
    
    func setHeaderText(text : String) {
        self.headerText?.text = text
    }
    
    func setDescription(text : String) {
        self.descriptionText?.text = text
    }
    
    func setTableSource(items : [AGSPreplannedMapArea]) {
        self.mapAreas = items
        
        /* Load the map areas */
        //TODO: Add in a spinner/activity indicator here
        for mapArea in mapAreas {
            mapArea.load(completion: {(error) in
                if let error = error {
                    print(error.localizedDescription)
                }
            })
        }
        
        self.table.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* Attach gestures */
        let swipeUp = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeUp.direction = UISwipeGestureRecognizer.Direction.up
        self.view.addGestureRecognizer(swipeUp)

        let swipeDown = UISwipeGestureRecognizer(target: self, action: #selector(self.respondToSwipeGesture))
        swipeDown.direction = UISwipeGestureRecognizer.Direction.down
        self.view.addGestureRecognizer(swipeDown)
        
        /* Table View Setup */
        table.delegate = self
        table.dataSource = self
        table.register(UINib(nibName: "MapAreaCell", bundle: nil), forCellReuseIdentifier: "reusableCell")
    }

    override func viewWillAppear(_ animated: Bool) {
       super.viewWillAppear(animated)
        
        /* NOTE -- Maybe refactor this piece, maybe prepare view in another lifecycle method because
         this method get's triggered even if the popup is open and we come back from another view. Hence, the reason
         we only call prepareBackgroundView() if content hasn't already been added to the view - to avoid duplicating. */
        if(view.subviews.count == 0) {
            prepareBackgroundView()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    //********************************
    //MARK: Setup Swipe Gestures
    //********************************
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {

        if let swipeGesture = gesture as? UISwipeGestureRecognizer {

            switch swipeGesture.direction {
                case UISwipeGestureRecognizer.Direction.right:
                    print("Swiped right")
                case UISwipeGestureRecognizer.Direction.down:
                    swipeDown()
                case UISwipeGestureRecognizer.Direction.left:
                    print("Swiped left")
                case UISwipeGestureRecognizer.Direction.up:
                    swipeUp()
                default:
                    break
            }
        }
    }
    
    func swipeUp() {
        UIView.animate(withDuration: 0.10, delay: 0.0, options: [.curveEaseInOut], animations: {
                let frame = self.view.frame
                let yComponent = UIScreen.main.bounds.height - 750
                self.view.frame = CGRect(x: 0, y: yComponent, width: frame.width, height: frame.height)
            },
        completion: nil)
    }
    
    func swipeDown() {
        UIView.animate(withDuration: 0.10, delay: 0.0, options: [.curveEaseInOut], animations: {
                let frame = self.view.frame
                let yComponent = UIScreen.main.bounds.height - CGFloat(self.popupInitialHeight)
                self.view.frame = CGRect(x: 0, y: yComponent, width: frame.width, height: frame.height)
            },
        completion: nil)
    }
    
    //********************************
    //MARK: Set up the UI of the Popup
    //********************************
    func prepareBackgroundView(){
        let blurEffect = UIBlurEffect.init(style: .dark)
        let visualEffect = UIVisualEffectView.init(effect: blurEffect)
        let bluredView = UIVisualEffectView.init(effect: blurEffect)
        bluredView.contentView.addSubview(visualEffect)

        visualEffect.frame = UIScreen.main.bounds
        bluredView.frame = UIScreen.main.bounds
        bluredView.layer.shadowColor = UIColor.black.cgColor
        bluredView.layer.shadowColor = UIColor.black.cgColor
        bluredView.layer.shadowOpacity = 0.5
        bluredView.layer.shadowOffset = .zero
        bluredView.layer.shadowRadius = 5

        view.insertSubview(bluredView, at: 0)
        
        /* Swipe down handle */
        let handle = UIView(frame: CGRect(x: self.view.frame.width/2 - 30, y: 10, width: 60, height: 4))
        handle.backgroundColor = UIColor.gray
        handle.layer.cornerRadius = 3
        
        /* Add close button */
        button = UIButton(frame: CGRect(x: self.view.frame.width - 50, y: 15, width: 40, height: 40))
        button!.setImage(UIImage(systemName: "xmark"), for: .normal)
        button!.tintColor = UIColor.lightText
        button!.addTarget(self, action: #selector(didButtonClick), for: .touchUpInside)
        
        /* Add the header text */
        headerText = UILabel(frame: CGRect(x: 10, y: 45, width: self.view.frame.width - 80, height: 40))
        headerText!.font = UIFont(name: "Helvetica Neue", size: 30)
        headerText!.textColor = UIColor.lightText
        headerText!.text = "Big Dipper"
        
        /* Add the portal snippet description text */
        descriptionText = UILabel(frame: CGRect(x: 15, y: 70, width: self.view.frame.width - 30, height: 80))
        descriptionText!.font = UIFont(name: "Helvetica Neue", size: 13)
        descriptionText!.textColor = UIColor.lightText
        descriptionText!.text = "[32.9876, -143.9765]"
        descriptionText!.numberOfLines = 3
        descriptionText!.lineBreakMode = .byWordWrapping
        
        /* Add in the table */
        table.translatesAutoresizingMaskIntoConstraints = false
        table.frame = CGRect(x: 0, y: 200, width: self.view.frame.width, height: 400)
        
        view.addSubview(handle)
        view.addSubview(button!)
        view.addSubview(headerText!)
        view.addSubview(descriptionText!)
        view.addSubview(table)
    }
    
    /* Add a fun animation to our button */
    @objc func didButtonClick(_ sender : UIButton) {
        
        self.buttonIsRotated = !self.buttonIsRotated
        
        UIView.animate(withDuration: 0.25, delay: 0.25, options: [.curveEaseInOut], animations: {
                let frame = self.view.frame
                let yComponent = UIScreen.main.bounds.height
                self.view.frame = CGRect(x: 0, y: yComponent, width: frame.width, height: frame.height)
            },
        completion: nil)
    }
    
    //********************************
    //MARK: Table View Related Methods
    //********************************
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        self.delegate?.downloadMapArea(mapArea: mapAreas[indexPath.row], tableIndex: indexPath)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return mapAreas.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "reusableCell", for: indexPath) as! MapAreaCell
        
        let mapArea = mapAreas[indexPath.row]
        
        if let portalItem = mapArea.portalItem {
            cell.MapAreaHeader.text = portalItem.title
            cell.MapAreaDescription.text = portalItem.snippet
               
            portalItem.thumbnail?.load(completion: { (error) in
                if let error = error {
                    print(error.localizedDescription)
                }
                cell.MapAreaThumbnail.image = portalItem.thumbnail?.image
            })
               
            cell.downloadAction = { (cell) in
               self.delegate?.downloadMapArea(mapArea: mapArea, tableIndex: indexPath)
            }
        }
        
        return cell
    }
}
