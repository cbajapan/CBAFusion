//
//  BackgroundViewModel.swift
//  CBAFusion
//
//  Created by Cole M on 1/23/23.
//

import UIKit

struct BackgroundsViewModel: Hashable {
    var id = UUID()
    var title: String
    var image: UIImage
    var thumbnail: UIImage
    
    init(imageModel: ImageModel) {
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

struct DisplayImageObject: Equatable {
    let id = UUID()
    var image1: UIImage?
    var image2: UIImage?
}

final class Backgrounds: ObservableObject {
    
    static let shared = Backgrounds()
    
    @Published var displayImage: DisplayImageObject?
    let imageProcessor = ImageProcessor()
    
    init() {
        Task { @MainActor [weak self] in
            guard let self else { return }
            async let image1 = self.imageProcessor.addImage("bedroom1", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
            async let image2 = self.imageProcessor.addImage("bedroom2", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
            async let image3 = self.imageProcessor.addImage("dining_room11", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
            async let image4 = self.imageProcessor.addImage("entrance1", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
            async let image5 = self.imageProcessor.addImage("garden", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
            async let image6 = self.imageProcessor.addImage("guest_room1", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
            async let image7 = self.imageProcessor.addImage("guest_room8", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
            async let image8 = self.imageProcessor.addImage("lounge", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
            async let image9 = self.imageProcessor.addImage("porch", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
            async let image10 = self.imageProcessor.addImage("remove", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
            async let image11 = self.imageProcessor.addImage("blur", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
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
            
            displayImage = await DisplayImageObject(image1: image1?.0, image2: image2?.1)
        }
    }
    
    func searchImages(with query: String?) async -> [BackgroundsViewModel] {
        return await imageProcessor.backgroundsViewModel.filter ({ $0.search(query) })
    }
}


internal actor ImageProcessor {
    var backgroundsViewModel = [BackgroundsViewModel]()
    func resize(_ name: String, to size: CGSize) async -> UIImage? {
        guard let image = UIImage(named: name) else { return nil }
        guard let ciimage = CIImage(image: image) else { return nil }
        guard let pb = recreatePixelBuffer(from: ciimage) else { return nil }
        guard let cgImage = try? createCGImage(from: pb, for: size) else { return nil }
        return UIImage(cgImage: cgImage)
    }
    
    func addImage(_ image: String, size: CGSize, thumbnail: CGSize) async -> (UIImage, UIImage)? {
        guard let resizedImage = await self.resize(image, to: size) else { return nil }
        guard let thumbnailImage = await self.resize(image, to: thumbnail) else { return nil }
        await MainActor.run {
            resizedImage.title = image
        }
        self.backgroundsViewModel.append(
            BackgroundsViewModel(
                imageModel: ImageModel(
                    title: image,
                    image: resizedImage,
                    thumbnail: thumbnailImage
                )
            )
        )
        return (resizedImage, thumbnailImage)
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

let ciContext = CIContext(options: [.useSoftwareRenderer: false, .cacheIntermediates: false])

internal func recreatePixelBuffer(from image: CIImage) -> CVPixelBuffer? {
    var pixelBuffer: CVPixelBuffer? = nil
    
    CVPixelBufferCreate(
        kCFAllocatorDefault,
        Int(image.extent.width),
        Int(image.extent.height),
        kCVPixelFormatType_32BGRA,
        pixelAttributes,
        &pixelBuffer
    )
    
    guard let pixelBuffer = pixelBuffer else { return nil }
    ciContext.render(image, to: pixelBuffer)
    return pixelBuffer
}

