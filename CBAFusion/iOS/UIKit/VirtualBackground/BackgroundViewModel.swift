//
//  BackgroundViewModel.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit

final class Backgrounds: ObservableObject {
    
    @Published var displayImage: (UIImage, UIImage)?
    var backgroundsViewModel = [BackgroundsViewModel]()
    
    struct BackgroundsViewModel: Hashable, Identifiable {
        var id: UUID?
        var title: String
        var image: UIImage
        var thumbnail: UIImage
        
        init(imageModel: ImageModel) {
            self.id = imageModel.id
            self.title = imageModel.title
            self.image = imageModel.image
            self.thumbnail = imageModel.thumbnail
        }
        
        
        static func == (lhs: BackgroundsViewModel, rhs: BackgroundsViewModel) -> Bool {
            return lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
        
        func search(_ filter: String?) -> Bool {
            guard let filterText = filter else { return true }
            if filterText.isEmpty { return true }
            let lowercasedFilter = filterText.lowercased()
            return title.lowercased().contains(lowercasedFilter)
        }
    }
    
    //We must run the image adding detached from the MainActor
    func addImage(_ image: String, size: CGSize, thumbnail: CGSize) async -> (UIImage, UIImage)? {
        let image = Task.detached { () -> (UIImage, UIImage)? in
            guard let resizedImage = await ImageProcessor.resize(image, to: size) else { return nil }
            guard let thumbnailImage = await ImageProcessor.resize(image, to: thumbnail) else { return nil }
            resizedImage.title = image
            self.backgroundsViewModel.append(BackgroundsViewModel(imageModel: ImageModel(title: image, image: resizedImage, thumbnail: thumbnailImage)))
            return (resizedImage, thumbnailImage)
        }
        return await image.value
    }
    
    
    func searchImages(with query: String?) -> [BackgroundsViewModel] {
        return backgroundsViewModel.filter ({ $0.search(query) })
    }
}
    
    
    internal actor ImageProcessor {
        static func resize(_ name: String, to size: CGSize) async -> UIImage? {
            let image = UIImage(named: name)
            guard let ciimage = CIImage(image: image!) else { return nil}
            let pb = recreatePixelBuffer(from: ciimage)
            let cgImage = try? createCGImage(from: pb!, for: size)
            return UIImage(cgImage: cgImage!)
        }
    }
    

    import Accelerate
    internal func createCGImage(
        from pixelBuffer: CVPixelBuffer,
        for size: CGSize,
        aspectRatio: CGFloat = 0,
        scale: Bool = false
    ) throws -> CGImage? {
        
        // Define the image format
        guard var format = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.last.rawValue),
            renderingIntent: .defaultIntent
        ) else {
            throw vImage.Error.invalidImageFormat
        }
        var error: vImage_Error
        var sourceBuffer = vImage_Buffer()
        
        
        
        guard let inputCVImageFormat = vImageCVImageFormat.make(buffer: pixelBuffer) else { throw vImage.Error.invalidCVImageFormat }
        vImageCVImageFormat_SetColorSpace(inputCVImageFormat, CGColorSpaceCreateDeviceRGB())
        
        error = vImageBuffer_InitWithCVPixelBuffer(
            &sourceBuffer,
            &format,
            pixelBuffer,
            inputCVImageFormat,
            nil,
            vImage_Flags(kvImageNoFlags)
        )
        
        guard error == kvImageNoError else {
            throw vImage.Error(vImageError: error)
        }
        
        var width: CGFloat = 0
        var height: CGFloat = 0
        //We always scale the image and center it according to the tallest height of the parent view, if we dont scale the size will fill the parent view
        if scale {
            height = size.height
            width = size.height * aspectRatio
        } else {
            height = size.height
            width = size.width
        }
        
        var destinationBuffer = try vImage_Buffer(width: Int(width), height:  Int(height), bitsPerPixel: format.bitsPerPixel)
        // Scale the image
        error = vImageScale_ARGB8888(&sourceBuffer,
                                     &destinationBuffer,
                                     nil,
                                     vImage_Flags(kvImageHighQualityResampling))
        guard error == kvImageNoError else {
            throw vImage.Error(vImageError: error)
        }
        
        var resizedImage: CGImage?
        // Center the image
            resizedImage = try destinationBuffer.createCGImage(format: format)
        
        defer {
            sourceBuffer.free()
            destinationBuffer.free()
        }
        guard let resizedImage = resizedImage else { return nil }
        return resizedImage
    }

    import Vision
    private let pixelAttributes = [
        kCVPixelBufferIOSurfacePropertiesKey: [
            kCVPixelBufferCGImageCompatibilityKey: true,
            kCVPixelBufferCGBitmapContextCompatibilityKey: true,
            kCVPixelBufferMetalCompatibilityKey: true,
            kCMSampleAttachmentKey_DisplayImmediately: true
        ]
    ] as? CFDictionary

    internal func recreatePixelBuffer(from image: CIImage) -> CVPixelBuffer? {
        autoreleasepool {
            var pixelBuffer: CVPixelBuffer? = nil
            
            CVPixelBufferCreate(
                kCFAllocatorDefault,
                Int(image.extent.width),
                Int(image.extent.height),
                kCVPixelFormatType_32BGRA,
                pixelAttributes,
                &pixelBuffer
            )
            let ciContext = CIContext(options: [.useSoftwareRenderer: false])
            guard let pixelBuffer = pixelBuffer else { return nil }
            ciContext.render(image, to: pixelBuffer)
            return pixelBuffer
        }
    }

