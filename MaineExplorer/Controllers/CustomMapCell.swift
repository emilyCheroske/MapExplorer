//
//  CustomMapCell.swift
//  MaineExplorer
//
//  Created by Emily Cheroske on 11/5/19.
//  Copyright © 2019 Emily Cheroske. All rights reserved.
//

import UIKit

class CustomMapCell: UITableViewCell {

    @IBOutlet weak var CustomMapCellHeader: UILabel!
    @IBOutlet weak var ThumbnailImage: UIImageView!
    
    var mapTapAction: ((UITableViewCell) -> Void)?
    var areaTapAction: ((UITableViewCell) -> Void)?
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
    }
    
    @IBAction func MapAreasButtonTapped(_ sender: Any) {
        areaTapAction?(self)
    }
    
    @IBAction func MapButtonTapped(_ sender: Any) {
        mapTapAction?(self)
    }
}
