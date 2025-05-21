//
//  BackgroundHeader.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit

/// A custom UICollectionReusableView that serves as a header with a label.
class BackgroundHeader: UICollectionReusableView {
    
    // UILabel to display the header text
    let label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.textAlignment = .left
        label.translatesAutoresizingMaskIntoConstraints = false // Enable Auto Layout
        return label
    }()
    
    // Initializer for the header view
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure() // Configure the header's subviews
    }
    
    // Required initializer for decoding from storyboard or xib
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Configure the header view's layout
    private func configure() {
        addSubview(label) // Add the label to the header view
        setupConstraints() // Set up constraints for the label
    }
    
    // Set up layout constraints for the label
    private func setupConstraints() {
        NSLayoutConstraint.activate([
            label.topAnchor.constraint(equalTo: topAnchor),
            label.leadingAnchor.constraint(equalTo: leadingAnchor),
            label.trailingAnchor.constraint(equalTo: trailingAnchor),
            label.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
}
