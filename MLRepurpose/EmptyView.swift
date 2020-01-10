//
//  EmptyView.swift
//  MLRepurpose
//
//  Created by Jackson Ho on 1/9/20.
//  Copyright © 2020 Jackson Ho. All rights reserved.
//

import UIKit

class EmptyView: UIView {

    private let titleLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLabel()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupLabel() {
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.font = UIFont(name: "HelveticaNeue-Bold", size: 18)
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.text = "No Results 😣"
        titleLabel.textColor = .darkGray
        addSubview(titleLabel)
        titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor, constant: -70).isActive = true
        titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor).isActive = true
    }
}
