//
//  BackgroundModel.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit

struct ImageModel: Identifiable, Hashable {
    let id = UUID()
    var title: String
    var image: UIImage
    var thumbnail: UIImage
    
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
