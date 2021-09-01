//
//  UIView+Extension.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/1/21.
//

import Foundation
import UIKit

extension UIView {
    
    
    func greaterThanHeightAnchors(top: NSLayoutYAxisAnchor?, leading: NSLayoutXAxisAnchor?, bottom: NSLayoutYAxisAnchor?, trailing: NSLayoutXAxisAnchor?, paddingTop: CGFloat, paddingLeft: CGFloat, paddingBottom: CGFloat, paddingRight: CGFloat, width: CGFloat, height: CGFloat) {
          translatesAutoresizingMaskIntoConstraints = false
          if let top = top {
              self.topAnchor.constraint(equalTo: top, constant: paddingTop).isActive = true
          }
          if let leading = leading {
              self.leadingAnchor.constraint(equalTo: leading, constant: paddingLeft).isActive = true
          }
          if let bottom = bottom {
              self.bottomAnchor.constraint(equalTo: bottom, constant: -paddingBottom).isActive = true
          }
          if let trailing = trailing {
              self.trailingAnchor.constraint(equalTo: trailing, constant: -paddingRight).isActive = true
          }
          if width != 0 {
            widthAnchor.constraint(equalToConstant: width).isActive = true
          }
          if height != 0 {
            heightAnchor.constraint(greaterThanOrEqualToConstant: height).isActive = true
          }
      }
    
}
