//
//  UIImage+Extension.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit

extension UIImage {
    func resizedImage(with title: String, to size: CGSize) -> UIImage {
          let image = UIGraphicsImageRenderer(size: size).image { _ in
            draw(in: CGRect(origin: .zero, size: size))
          }
        image.title = title
        return image
      }
}
