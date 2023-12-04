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
    @EnvironmentObject var backgrounds: Backgrounds
    @State var uiImage: UIImage?
    
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
                    .onReceive(backgrounds.$displayImage, perform: { image in
                        if let image = image {
                            uiImage = image.image1
                        }
                        if let hasImage = backgrounds.displayImage {
                            uiImage = hasImage.image2
                        } else {
                            if let firstImage = backgrounds.backgroundsViewModel.first {
                                uiImage = firstImage.image
                                backgrounds.displayImage = DisplayImageObject(image1: firstImage.image, image2: firstImage.thumbnail)
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
                    if backgrounds.displayImage?.image1?.title == "remove" {
                        await self.fcsdkService.removeBackground()
                    } else {
                        if let uiImage = backgrounds.displayImage?.image1 {
                            if backgrounds.displayImage?.image1?.title == "blur" {
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
            //                    if #available(iOS 16.0, *) {
            //                        ScrollView(.horizontal, showsIndicators: false) {
            //                            Grid {
            //                                GridRow {
            //
            //                                    ForEach(backgrounds.backgroundsViewModel) { model in
            //
            //                                        Button {
            //                                            self.uiImage = model.thumbnail
            //                                            backgrounds.displayImage = (model.image, model.thumbnail)
            //                                        } label: {
            //                                            Image(uiImage: model.thumbnail)
            //                                                .resizable()
            //                                                .frame(width: 225, height: 180)
            //                                                .cornerRadius(12)
            //                                        }
            //                                    }
            //                                }
            //                            }
            //                        }
            //                    } else {
            
            VirtualBackgroundController()
                .padding(EdgeInsets(top: 40, leading: 20, bottom: 100, trailing: 0))
//        }
        }
    }
}
