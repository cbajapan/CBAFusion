//
//  BackgroundSelector.swift
//  CBAFusion
//
//  Created by Cole M on 1/3/23.
//

import SwiftUI
import FCSDKiOS


@available(iOS 15, *)
struct BackgroundSelector: View {
    
    @Environment(\.presentationMode) var presentationMode
    @EnvironmentObject var fcsdkService: FCSDKCallService
    @EnvironmentObject var backgroundObserver: BackgroundObserver
    @State var uiImage: UIImage?
    @State var imageProcessor: ImageProcessor?

    var body: some View {
        VStack {
            HStack {
                Button {
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: "xmark")
                }
                Spacer()
            }
            .padding()
            Spacer()
            if #available(iOS 16.0, *) {
                Image(uiImage: uiImage ?? UIImage(named: "bedroom1")!)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .onReceive(backgroundObserver.$displayImage, perform: { image in
                        if let image = image {
                            uiImage = image.image1
                        }
                        if let hasImage = backgroundObserver.displayImage {
                            uiImage = hasImage.image2
                        } else {
                                if let firstImage = backgroundObserver.backgroundsViewModel.first {
                                    uiImage = firstImage.image
                                    backgroundObserver.displayImage = DisplayImageObject(image1: firstImage.image, image2: firstImage.thumbnail)
                                }
                            }
                    })
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .frame(maxWidth: 300, maxHeight: 225)
                    .cornerRadius(12)
            } else {
                DisplayImage()
                    .frame(maxWidth: 300, maxHeight: 225)
                    .padding(EdgeInsets(top: 0, leading: 0, bottom: 0, trailing: 0))
                    .cornerRadius(12)
            }
            Button("Set Background") {
                //Get data from image asset
                Task { @MainActor in
                    if backgroundObserver.displayImage?.image1?.title == "remove" {
                        await self.fcsdkService.removeBackground()
                    } else {
                        if let uiImage = backgroundObserver.displayImage?.image1 {
                            if backgroundObserver.displayImage?.image1?.title == "blur" {
                                await self.fcsdkService.setBackgroundImage(mode: .blur)
                            } else {
                                await self.fcsdkService.setBackgroundImage(uiImage, mode: .image)
                            }
                        }
                    }
                    fcsdkService.showBackgroundSelectorSheet = false
                }
                presentationMode.wrappedValue.dismiss()
            }
            
            Spacer()
            VirtualBackgroundController(backgroundObserver: backgroundObserver)
                .padding(EdgeInsets(top: 40, leading: 20, bottom: 100, trailing: 0))
        }
        .task {
            imageProcessor = ImageProcessor(backgroundObserver: backgroundObserver)
            await imageProcessor?.loadImages()
        }
        .onDisappear {
            Task {
                await imageProcessor?.removeImages()
            }
        }
    }
}

