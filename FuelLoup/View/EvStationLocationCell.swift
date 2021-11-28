//
//  EvStationLocationCell.swift
//  FuelLoup
//
//  Created by Tomasz Milczarek on 18/11/2021.
//

import UIKit

class EvStationLocationCell: UITableViewCell {
    
    // MARK: - IB
    @IBOutlet weak var evStationimageView: UIImageView!
    @IBOutlet weak var name: UILabel!
    @IBOutlet weak var address: UILabel!
    @IBOutlet weak var distance: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        selectionStyle = .none
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }

}
