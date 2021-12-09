//
//  StartCallConvertible.swift
//  CBAFusion
//
//  Created by Cole M on 10/8/21.
//

import Foundation

protocol StartCallConvertible {

    var startCallHandle: String? { get }
    var video: Bool? { get }

}

extension StartCallConvertible {

    var video: Bool? {
        return nil
    }

}
