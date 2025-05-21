//
//  BackgroundItemCell.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit

/// A custom UICollectionViewCell that displays a poster image.
class BackgroundItemCell: UICollectionViewCell {
    
    // Reuse identifier for the cell
    static let reuseIdentifier = "background-item-cell-reuse-identifier"
    
    // UIImageView to display the poster image
    let posterImage: UIImageView = {
        let imageView = UIImageView()
        imageView.layer.backgroundColor = UIColor(red: 10/255, green: 18/255, blue: 20/255, alpha: 1).cgColor
        imageView.contentMode = .scaleAspectFill
        imageView.layer.cornerRadius = 10
        imageView.clipsToBounds = true
        return imageView
    }()
    
    // Initializer for the cell
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure() // Configure the cell's subviews
    }
    
    // Required initializer for decoding from storyboard or xib
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Constraint for indentation (if needed in the future)
    fileprivate var indentConstraint: NSLayoutConstraint! = nil
    fileprivate let inset: CGFloat = 10 // Padding for the cell
}

// MARK: - Configuration
extension BackgroundItemCell {
    
    /// Configures the cell's subviews and layout constraints.
    func configure() {
        addSubview(posterImage) // Add the poster image view to the cell
        setupConstraints() // Set up constraints for the poster image
    }
    
    /// Sets up the layout constraints for the poster image view.
    private func setupConstraints() {
        posterImage.translatesAutoresizingMaskIntoConstraints = false // Enable Auto Layout
        NSLayoutConstraint.activate([
            posterImage.topAnchor.constraint(equalTo: topAnchor),
            posterImage.leadingAnchor.constraint(equalTo: leadingAnchor),
            posterImage.trailingAnchor.constraint(equalTo: trailingAnchor),
            posterImage.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -20) // Adjust bottom padding
        ])
    }
}
