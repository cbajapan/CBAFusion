//
//  BackgroundModel.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit

/// A model representing an image with its title, full-size image, and thumbnail.
///
/// The `ImageModel` struct is used to encapsulate the properties of an image,
/// including a unique identifier, a title, the full-size image, and a thumbnail
/// version of the image. It conforms to the `Identifiable`, `Hashable`, and
/// `Sendable` protocols, making it suitable for use in SwiftUI views and
/// collections that require unique identification and hashing capabilities.
struct ImageModel: Identifiable, Hashable, Sendable {
    
    /// A unique identifier for the image model.
    let id = UUID()
    
    /// The title of the image.
    var title: String
    
    /// The full-size image.
    var image: UIImage
    
    /// The thumbnail version of the image.
    var thumbnail: UIImage
    
    /// Hashes the essential components of the image model into the provided hasher.
    ///
    /// This method is used to provide a hash value for the `ImageModel` instance,
    /// allowing it to be used in collections that require hashing, such as sets or
    /// as dictionary keys.
    ///
    /// - Parameter hasher: The hasher to use for combining the hash values.
    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
