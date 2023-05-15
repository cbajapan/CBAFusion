//
//  BackgroundModel.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit

struct ImageModel: Identifiable {
    let id = UUID()
    var title: String
    var image: UIImage
    var thumbnail: UIImage
}
