//
//  BackgroundHeader.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit

class BackgroundHeader: UICollectionReusableView {
    let label: UILabel = {
        let txt = UILabel()
        txt.textColor = .white
        txt.textAlignment = .left
        return txt
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(label)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        label.frame = bounds
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
