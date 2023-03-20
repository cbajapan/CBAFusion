//
//  BackgroundItemCell.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit

class BackgroundItemCell: UICollectionViewCell {
    
    static let reuseIdentifer = "background-item-cell-reuse-identifier"
    let posterImage: UIImageView = {
        let pstImg = UIImageView()
        pstImg.layer.backgroundColor = UIColor(red: 10/255, green: 18/255, blue: 20/255, alpha: 1).cgColor
        pstImg.contentMode = .scaleAspectFill
        pstImg.layer.cornerRadius = 10
        pstImg.clipsToBounds = true
        return pstImg
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        configure()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    fileprivate var indentContraint: NSLayoutConstraint! = nil
    fileprivate let inset = CGFloat(10)
}

extension BackgroundItemCell {
    func configure() {
        addSubview(posterImage)
        posterImage.anchors(
            top: topAnchor,
            leading: leadingAnchor,
            bottom: bottomAnchor,
            trailing: trailingAnchor,
            bottomPadding: 20
        )
    }
}
