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

@MainActor
final class BackgroundObserver: ObservableObject {
    @Published var displayImage: DisplayImageObject?
    @Published var backgroundsViewModel: [BackgroundsViewModel] = []
    
    func searchImages(with query: String?) async -> [BackgroundsViewModel] {
        return backgroundsViewModel.filter ({ $0.search(query) })
    }
}

@MainActor
internal final class ImageProcessor {
    let backgroundObserver: BackgroundObserver
    
    deinit {
        print("RECLAIMED MEMORY IN IMAGE PROCESSOR")
    }
    
    init(backgroundObserver: BackgroundObserver) {
        self.backgroundObserver = backgroundObserver
    }
    
    func loadImages() async {
        async let image1 = self.addImage("bedroom1", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
        async let image2 = self.addImage("bedroom2", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
        async let image3 = self.addImage("dining_room11", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
        async let image4 = self.addImage("entrance1", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
        async let image5 = self.addImage("garden", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
        async let image6 = self.addImage("guest_room1", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
        async let image7 = self.addImage("guest_room8", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
        async let image8 = self.addImage("lounge", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
        async let image9 = self.addImage("porch", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
        async let image10 = self.addImage("remove", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
        async let image11 = self.addImage("blur", size: CGSize(width: 1280, height: 720), thumbnail: CGSize(width: 300, height: 225))
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
        await self.setImage(image: image1?.0, thumbnail: image1?.1)
    }
    
    func removeImages() async {
        backgroundObserver.displayImage = nil
        backgroundObserver.backgroundsViewModel.removeAll()
    }

    let metalManager = MetalManager()
    func addImage(_ image: String, size: CGSize, thumbnail: CGSize) async -> (UIImage, UIImage)? {
        guard let resizedImage = await metalManager.processImageWithMetal(image: UIImage(named: image)!, newSize: size) else { return nil }
        guard let thumbnailImage = await metalManager.processImageWithMetal(image: UIImage(named: image)!, newSize: thumbnail) else { return nil }
            resizedImage.title = image
            backgroundObserver.backgroundsViewModel.append(
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
    
    func setImage(image: UIImage?, thumbnail: UIImage?) {
        backgroundObserver.displayImage = DisplayImageObject(image1: image, image2: thumbnail)
    }
}

struct MetalManager: @unchecked Sendable {
    let device: MTLDevice
    let commandQueue: MTLCommandQueue
    let library: MTLLibrary!
    let textureLoader: MTKTextureLoader

    init() {
        guard let device = MTLCreateSystemDefaultDevice() else {
            fatalError("Metal is not supported on this device")
        }
        self.device = device
        library = device.makeDefaultLibrary()
        self.commandQueue = device.makeCommandQueue()!
        self.textureLoader = MTKTextureLoader(device: device)
    }

    func resizeImage(sourceTexture: MTLTexture, newSize: CGSize) async -> MTLTexture? {
        let filter = MPSImageLanczosScale(device: device)
        let originalScale = CGFloat(sourceTexture.width) / CGFloat(sourceTexture.height)
        var newSize = newSize
        if (newSize.width / newSize.height) > originalScale {
            newSize.height = newSize.width / originalScale
        }

        let scaleX = Double(newSize.width) / Double(sourceTexture.width)
        let scaleY = Double(newSize.height) / Double(sourceTexture.height)
        let destTextureDescriptor = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: sourceTexture.pixelFormat,
                                                                             width: Int(newSize.width),
                                                                             height: Int(newSize.height),
                                                                             mipmapped: false)
        destTextureDescriptor.usage = [.shaderRead, .shaderWrite]
        guard let destTexture = device.makeTexture(descriptor: destTextureDescriptor) else {
            print("Error creating destination texture")
            return nil
        }
        let translateX = (Double(destTextureDescriptor.width) - Double(sourceTexture.width) * scaleX) / 2
        let translateY = (Double(destTextureDescriptor.height) - Double(sourceTexture.height) * scaleY) / 2

        let transform = MPSScaleTransform(
            scaleX: scaleX,
            scaleY: scaleY,
            translateX: translateX,
            translateY: translateY
        )
        let transformPointer = UnsafeMutablePointer<MPSScaleTransform>.allocate(capacity: 1)
        transformPointer.initialize(to: transform)
        filter.scaleTransform = UnsafePointer(transformPointer)
        defer {
            transformPointer.deallocate()
        }
        let commandBuffer = commandQueue.makeCommandBuffer()
        filter.encode(commandBuffer: commandBuffer!, sourceTexture: sourceTexture, destinationTexture: destTexture)
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()

        return destTexture
    }

    func processImageWithMetal(image: UIImage?, newSize: CGSize) async -> UIImage? {
        
        guard let sourceImage = image, let cgImage = sourceImage.cgImage else {
            print("Invalid source image")
            return nil
        }
        do {
            let texture = try await textureLoader.newTexture(cgImage: cgImage, options: nil)
            let resizedTexture = await resizeImage(sourceTexture: texture, newSize: newSize)
            guard let resizedTexture = resizedTexture else {
                print("Error resizing image")
                return nil
            }
            let imageSize = CGSize(width: resizedTexture.width, height: resizedTexture.height)
            let hasAlpha = cgImage.alphaInfo != .none || sourceImage.imageOrientation == .upMirrored || sourceImage.imageOrientation == .downMirrored || sourceImage.imageOrientation == .leftMirrored || sourceImage.imageOrientation == .rightMirrored
            return await imageFromTexture(texture: resizedTexture, imageSize: imageSize, bitsPerPixel: cgImage.bitsPerPixel, hasAlpha: hasAlpha)
        } catch {
            print("Error processing image with Metal: \(error.localizedDescription)")
            return nil
        }
    }

    private func imageFromTexture(texture: MTLTexture, imageSize: CGSize, bitsPerPixel: Int, hasAlpha: Bool) async -> UIImage {
        let region = MTLRegion(origin: MTLOrigin(x: 0, y: 0, z: 0),
                               size: MTLSize(width: texture.width, height: texture.height, depth: 1))
        let bytesPerRow = (texture.width * bitsPerPixel) / 8
        let imageByteCount = bytesPerRow * texture.height
        var bytes = [UInt8](repeating: 0, count: imageByteCount)
        
        texture.getBytes(&bytes, bytesPerRow: bytesPerRow, from: region, mipmapLevel: 0)
        
        
        let bitmapInfo: CGBitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.noneSkipFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
        
        guard let provider = CGDataProvider(data: NSData(bytes: &bytes, length: bytes.count * MemoryLayout<UInt8>.size)) else {
            fatalError("Error creating CGDataProvider")
        }
        
        if let cgImage = CGImage(width: texture.width, height: texture.height, bitsPerComponent: 8, bitsPerPixel: 32, bytesPerRow: bytesPerRow, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: bitmapInfo, provider: provider, decode: nil, shouldInterpolate: true, intent: .defaultIntent) {
            return UIImage(cgImage: cgImage)
        } else {
            fatalError("Error creating CGImage")
        }
    }
}
