//
//  BackgroundViewModel.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit
import Metal
import MetalKit
import MetalPerformanceShaders


/// A view model representing a background image with its title and images.
///
/// The `BackgroundsViewModel` struct encapsulates the properties of a background image,
/// including a unique identifier, a title, the full-size image, and a thumbnail image.
/// It conforms to the `Hashable` protocol to allow instances to be compared and used in collections.
struct BackgroundsViewModel: Hashable {
    /// A unique identifier for the background view model.
    let id = UUID()
    
    /// The title of the background image.
    var title: String
    
    /// The full-size background image.
    var image: UIImage
    
    /// The thumbnail version of the background image.
    var thumbnail: UIImage
    
    /// Initializes a new instance of `BackgroundsViewModel` using an `ImageModel`.
    ///
    /// - Parameter imageModel: An instance of `ImageModel` containing the image data.
    init(imageModel: ImageModel) {
        self.title = imageModel.title
        self.image = imageModel.image
        self.thumbnail = imageModel.thumbnail
    }
    
    // MARK: - Hashable Conformance
    
    /// Compares two `BackgroundsViewModel` instances for equality.
    ///
    /// - Parameters:
    ///   - lhs: The left-hand side instance.
    ///   - rhs: The right-hand side instance.
    /// - Returns: A Boolean value indicating whether the two instances are equal.
    nonisolated static func == (lhs: BackgroundsViewModel, rhs: BackgroundsViewModel) -> Bool {
        return lhs.id == rhs.id
    }
    
    /// Hashes the essential components of the background view model into the provided hasher.
    ///
    /// - Parameter hasher: The hasher to use for combining the hash values.
    nonisolated func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    /// Searches the title for a given filter string.
    ///
    /// - Parameter filter: An optional string to filter the title.
    /// - Returns: A Boolean value indicating whether the title contains the filter text.
    func search(_ filter: String?) -> Bool {
        guard let filterText = filter else { return true }
        if filterText.isEmpty { return true }
        let lowercasedFilter = filterText.lowercased()
        return title.lowercased().contains(lowercasedFilter)
    }
}

/// A structure representing a display image object with two images.
///
/// The `DisplayImageObject` struct is used to hold two optional images for display purposes.
struct DisplayImageObject: Equatable, Sendable {
    /// A unique identifier for the display image object.
    let id = UUID()
    
    /// The first image.
    var image1: UIImage?
    
    /// The second image.
    var image2: UIImage?
}

/// A class that observes and manages background images in a SwiftUI environment.
///
/// The `BackgroundObserver` class conforms to `ObservableObject` and provides
/// published properties for managing the display image and a collection of background view models.
@MainActor
final class BackgroundObserver: ObservableObject {
    /// The currently displayed image object.
    @Published var displayImage: DisplayImageObject?
    
    /// An array of background view models.
    @Published var backgroundsViewModel: [BackgroundsViewModel] = []
    
    /// Searches for images that match a given query asynchronously.
    ///
    /// - Parameter query: An optional search query string.
    /// - Returns: An array of `BackgroundsViewModel` instances that match the query.
    func searchImages(with query: String?) async -> [BackgroundsViewModel] {
        return backgroundsViewModel.filter { $0.search(query) }
    }
}

/// A class responsible for processing images and managing background images.
///
/// The `ImageProcessor` class handles loading, resizing, and managing images
/// for the `BackgroundObserver`.
@MainActor
internal final class ImageProcessor {
    /// The background observer instance that this processor will manage.
    let backgroundObserver: BackgroundObserver
    
    deinit {
        print("RECLAIMED MEMORY IN IMAGE PROCESSOR")
    }
    
    /// Initializes a new instance of `ImageProcessor`.
    ///
    /// - Parameter backgroundObserver: An instance of `BackgroundObserver` to manage.
    init(backgroundObserver: BackgroundObserver) {
        self.backgroundObserver = backgroundObserver
    }
    
    /// Loads images asynchronously and adds them to the background observer.
    func loadImages() async {
        let screenSize = UIScreen.main.bounds.size
        async let image1 = self.addImage("bedroom1", size: screenSize, thumbnail: CGSize(width: 300, height: 225))
        async let image2 = self.addImage("bedroom2", size: screenSize, thumbnail: CGSize(width: 300, height: 225))
        async let image3 = self.addImage("dining_room11", size: screenSize, thumbnail: CGSize(width: 300, height: 225))
        async let image4 = self.addImage("entrance1", size: screenSize, thumbnail: CGSize(width: 300, height: 225))
        async let image5 = self.addImage("garden", size: screenSize, thumbnail: CGSize(width: 300, height: 225))
        async let image6 = self.addImage("guest_room1", size: screenSize, thumbnail: CGSize(width: 300, height: 225))
        async let image7 = self.addImage("guest_room8", size: screenSize, thumbnail: CGSize(width: 300, height: 225))
        async let image8 = self.addImage("lounge", size: screenSize, thumbnail: CGSize(width: 300, height: 225))
        async let image9 = self.addImage("porch", size: screenSize, thumbnail: CGSize(width: 300, height: 225))
        async let image10 = self.addImage("remove", size: screenSize, thumbnail: CGSize(width: 300, height: 225))
        async let image11 = self.addImage("blur", size: screenSize, thumbnail: CGSize(width: 300, height: 225))
        
        // Await all image loading tasks
        _ = await [
            image1,
            image2,
            image3,
            image4,
            image5,
            image6,
            image7,
            image8,
            image9,
            image10,
            image11
        ]
        
        // Set the first loaded image and its thumbnail
        await self.setImage(image: image1?.0, thumbnail: image1?.1, title: image1?.2.title ?? "")
    }
    
    /// Removes all images from the background observer.
    func removeImages() async {
        backgroundObserver.displayImage = nil
        backgroundObserver.backgroundsViewModel.removeAll()
    }
    
    /// Resizes an image to a specified target size while maintaining its aspect ratio.
    ///
    /// - Parameters:
    ///   - image: The original image to resize.
    ///   - targetSize: The desired size for the resized image.
    /// - Returns: The resized image, or `nil` if resizing fails.
    func resizeImage(image: UIImage, targetSize: CGSize) -> UIImage? {
        // Calculate the scaling factor
        let widthRatio  = targetSize.width  / image.size.width
        let heightRatio = targetSize.height / image.size.height
        
        // Determine the scale factor to maintain aspect ratio
        let scaleFactor = min(widthRatio, heightRatio)
        
        // Calculate the new size
        let newSize = CGSize(width: image.size.width * scaleFactor, height: image.size.height * scaleFactor)
        
        // Resize the image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage
    }

    /// Adds an image and its thumbnail to the background observer asynchronously.
    ///
    /// - Parameters:
    ///   - image: The name of the image to load.
    ///   - size: The desired size for the full-size image.
    ///   - thumbnail: The desired size for the thumbnail image.
    /// - Returns: A tuple containing the resized image and thumbnail, or `nil` if loading fails.
    func addImage(_ image: String, size: CGSize, thumbnail: CGSize) async -> (UIImage, UIImage, BackgroundsViewModel)? {
        guard let resizedImage = resizeImage(image: UIImage(named: image)!, targetSize: size) else { return nil }
        guard let thumbnailImage = resizeImage(image: UIImage(named: image)!, targetSize: thumbnail) else { return nil }
        
        // Create and append a new BackgroundsViewModel to the observer
        let model = BackgroundsViewModel(
            imageModel: ImageModel(
                title: image,
                image: resizedImage,
                thumbnail: thumbnailImage
            ))
        backgroundObserver.backgroundsViewModel.append(model)
        
        return (resizedImage, thumbnailImage, model)
    }
    
    /// Sets the display image and thumbnail in the background observer.
    ///
    /// - Parameters:
    ///   - image: The full-size image to display.
    ///   - thumbnail: The thumbnail image to display.
    func setImage(image: UIImage?, thumbnail: UIImage?, title: String) {
        image?.title = title
        backgroundObserver.displayImage = DisplayImageObject(image1: image, image2: thumbnail)
    }
}
