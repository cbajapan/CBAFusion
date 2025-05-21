//
//  BackgroundSelector.swift
//  CBAFusion
//
//  Created by Cole M on 1/3/23.
//

import SwiftUI
import FCSDKiOS

@available(iOS 15, *)
/// A view that allows users to select and set a virtual background for video calls.
struct BackgroundSelector: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fcsdkService: FCSDKCallService
    @EnvironmentObject var backgroundObserver: BackgroundObserver
    
    @State private var uiImage: UIImage?
    @State private var imageProcessor: ImageProcessor?

    var body: some View {
        VStack {
            // Header with a dismiss button
            headerView
            
            Spacer()
            
            // Display the selected background image
            backgroundImageView
            
            // Button to set the selected background
            setBackgroundButton
            
            Spacer()
            
            // Virtual background controller for additional options
            VirtualBackgroundController(backgroundObserver: backgroundObserver)
                .padding(.top, 40)
                .padding(.leading, 20)
                .padding(.bottom, 100)
        }
        .task {
            // Load images when the view appears
            imageProcessor = ImageProcessor(backgroundObserver: backgroundObserver)
            await imageProcessor?.loadImages()
        }
        .onDisappear {
            // Clean up images when the view disappears
            Task {
                await imageProcessor?.removeImages()
            }
        }
    }
    
    /// A view representing the header with a dismiss button.
    private var headerView: some View {
        HStack {
            Button {
                presentationMode.wrappedValue.dismiss()
            } label: {
                Image(systemName: "xmark")
            }
            Spacer()
        }
        .padding()
    }
    
    /// A view that displays the currently selected background image.
    private var backgroundImageView: some View {
        Group {
            if #available(iOS 16.0, *) {
                Image(uiImage: uiImage ?? UIImage(named: "bedroom1")!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onReceive(backgroundObserver.$displayImage) { image in
                        updateUIImage(with: image)
                    }
                    .frame(maxWidth: 300, maxHeight: 225)
                    .cornerRadius(12)
            } else {
                DisplayImage()
                    .frame(maxWidth: 300, maxHeight: 225)
                    .cornerRadius(12)
            }
        }
        .padding()
    }
    
    /// Updates the UIImage based on the received display image.
    /// - Parameter image: The new display image object.
    private func updateUIImage(with image: DisplayImageObject?) {
        if let image = image {
            uiImage = image.image1
        } else if let firstImage = backgroundObserver.backgroundsViewModel.first {
            uiImage = firstImage.image
            backgroundObserver.displayImage = DisplayImageObject(image1: firstImage.image, image2: firstImage.thumbnail)
        }
    }
    
    /// A button that sets the selected background image.
    private var setBackgroundButton: some View {
        Button("Set Background") {
            Task { @MainActor in
                await setBackground()
            }
            presentationMode.wrappedValue.dismiss()
        }
    }
    
    /// Sets the background based on the selected image.
    private func setBackground() async {
        guard let displayImage = backgroundObserver.displayImage else { return }
        
        if displayImage.image1?.title == "remove" {
            await fcsdkService.removeBackground()
        } else if let uiImage = displayImage.image1 {
            if displayImage.image1?.title == "blur" {
                await fcsdkService.setBackgroundImage(mode: .blur)
            } else {
                await fcsdkService.setBackgroundImage(uiImage, mode: .image)
            }
        }
        fcsdkService.showBackgroundSelectorSheet = false
    }
}
