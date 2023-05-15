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
        ScrollView {
            VStack {
                Spacer()
                if #available(iOS 16.0, *) {
                    Image(uiImage: uiImage ?? UIImage(named: "bedroom1")!)
                        .task {
                            if let hasImage = backgrounds.backgroundsViewModel.first(where: { $0.thumbnail == uiImage }) {
                                uiImage = hasImage.thumbnail
                                backgrounds.displayImage = (hasImage.image, hasImage.thumbnail)
                            } else {
                                if let firstImage = backgrounds.backgroundsViewModel.first {
                                    uiImage = firstImage.image
                                    backgrounds.displayImage = (firstImage.image, firstImage.thumbnail)
                                }
                            }
                        }
                        .padding(EdgeInsets(top: 150, leading: 0, bottom: 0, trailing: 0))
                        .frame(width: 300, height: 225)
                        .cornerRadius(12)
                } else {
                    DisplayImage()
                        .frame(width: 300, height: 225)
                        .padding(EdgeInsets(top: 150, leading: 0, bottom: 0, trailing: 0))
                }
                Button("Set Background") {
                    //Get data from image asset
                    Task { @MainActor in
                        if backgrounds.displayImage?.0.title == "remove" {
                            await self.fcsdkService.removeBackground()
                        } else {
                            if let uiImage = backgrounds.displayImage?.0 {
                                if backgrounds.displayImage?.0.title == "blur" {
                                    await self.fcsdkService.setBackgroundImage(mode: .blur)
                                } else {
                                    await self.fcsdkService.setBackgroundImage(uiImage, mode: .image)
                                }
                            }
                        }
                    }
                    presentationMode.wrappedValue.dismiss()
                }
                
                Spacer()
                VStack {
                    if #available(iOS 16.0, *) {
                        ScrollView(.horizontal, showsIndicators: false) {
                            Grid {
                                GridRow {

                                    ForEach(backgrounds.backgroundsViewModel) { model in

                                        Button {
                                            self.uiImage = model.thumbnail
                                            backgrounds.displayImage = (model.image, model.thumbnail)
                                        } label: {
                                            Image(uiImage: model.thumbnail)
                                                .resizable()
                                                .frame(width: 225, height: 180)
                                                .cornerRadius(12)
                                        }
                                    }
                                }
                            }
                        }
                    } else {
                        VirtualBackgroundController(backgrounds: self._backgrounds)
                    }
                }
                .padding(EdgeInsets(top: 40, leading: 20, bottom: 100, trailing: 0))
            }
        }
    }
}
