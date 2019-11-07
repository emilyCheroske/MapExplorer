//
//  MapAreaCell.swift
//  MaineExplorer
//
//  Created by Emily Cheroske on 11/6/19.
//  Copyright © 2019 Emily Cheroske. All rights reserved.
//

import UIKit

class MapAreaCell: UITableViewCell {

    @IBOutlet weak var MapAreaThumbnail: UIImageView!
    @IBOutlet weak var MapAreaHeader: UILabel!
    @IBOutlet weak var MapAreaDescription: UILabel!
    @IBOutlet weak var ProgressBar: UIProgressView!
    @IBOutlet weak var DownloadButton: UIButton!
    
    var downloadAction: ((UITableViewCell) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        ProgressBar.progress = 0
        ProgressBar.isHidden = true
    }

    @IBAction func Download(_ sender: Any) {
        downloadAction?(self)
    }
}
