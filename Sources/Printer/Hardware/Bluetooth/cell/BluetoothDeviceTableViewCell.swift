//
//  BluetoothDeviceTableViewCell.swift
//  Pods
//
//  Created by Jesus Ervin Chapi Suyo on 17/07/24.
//

import UIKit

class BluetoothDeviceTableViewCell: UITableViewCell {

    @IBOutlet weak var Name: UILabel!
    @IBOutlet weak var Mac: UILabel!
    static let identifier = "BluetoothDeviceTableViewCell"
    static func nib() -> UINib {
        return UINib(nibName: "BluetoothDeviceTableViewCell", bundle: nil)
    }
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
