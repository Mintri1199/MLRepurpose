//
//  LinkPreviewCell.swift
//  MLRepurpose
//
//  Created by Jackson Ho on 1/9/20.
//  Copyright © 2020 Jackson Ho. All rights reserved.
//

import UIKit

class LinkPreviewCell: UITableViewCell {
    let loading = UIActivityIndicatorView(style: .medium)
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        loading.center = contentView.center
        loading.hidesWhenStopped = true
        loading.startAnimating()
        layer.cornerRadius = 15
        addSubview(loading)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)
        // Configure the view for the selected state
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        contentView.frame = contentView.frame.inset(by: UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10))
    }

}
