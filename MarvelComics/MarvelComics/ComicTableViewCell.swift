//
//  ComicTableViewCell.swift
//  MarvelComics
//
//  Created by Administrator on 05/03/2016.
//  Copyright © 2016 mahesh lad. All rights reserved.
//

import UIKit

class ComicTableViewCell: UITableViewCell {

    @IBOutlet weak var comicImageView: UIImageView!
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

        // Configure the view for the selected state
    }
    
}
