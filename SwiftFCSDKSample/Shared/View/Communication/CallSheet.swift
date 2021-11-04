//
//  CallSheet.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/8/21.
//

import SwiftUI

struct CallSheet: View {
    
    @Binding var destination: String
    @State var showFullSheet: ActiveSheet?
    @Binding var hasVideo: Bool
    @State private var string = ""
    @Environment(\.presentationMode) private var presentationMode
    @State private var orientation = UIDeviceOrientation.unknown

    var body: some View {
        
        GeometryReader { geometry in
            ScrollView {
                if orientation.isLandscape && orientation.isFlat || orientation.isLandscape {
                    VStack(alignment: .leading) {
                        HStack(alignment: .bottom) {
                            Text("End Point:")
                            TextField("Destination...", text: self.$destination)
                        }
                        Toggle("Want Video?", isOn: self.$hasVideo)
                    }
                    .padding()
                    .frame(height: geometry.size.height * 1)
                } else {
                VStack {
                    HStack(alignment: .bottom) {
                        Text("End Point:")
                        TextField("Destination...", text: self.$destination)
                    }
                    Toggle("Want Video?", isOn: self.$hasVideo)
                }
                .padding()
                VStack {
                    DialPad(string: $string, legacyDTMF: .constant(false))
                        .padding()
                        .frame(width: geometry.size.width * 0.8, height: geometry.size.height * 0.8)
                }
                }
            }
        }
        .onRotate { newOrientation in
            orientation = newOrientation
        }
        .onChange(of: self.string, perform: { s in
            self.destination = s
        })
        .navigationBarTitle("Let's Talk")
        .navigationBarItems(leading:
                                Button(action: {
            self.presentationMode.wrappedValue.dismiss()
        }, label: {
            Text("Cancel")
                .foregroundColor(Color.red)
        }
                                      ), trailing:
                                Button(action: {
            self.showFullSheet = .communincationSheet
        }, label: {
            Text("Connect")
                .foregroundColor(Color.blue)
        }))
        .navigationBarBackButtonHidden(true)
        .fullScreenCover(item: self.$showFullSheet) { sheet in
            switch sheet {
            case .communincationSheet:
                Communication(destination: self.$destination, hasVideo: self.$hasVideo, isOutgoing: .constant(true))
            }
        }
    }
}

struct DeviceRotationViewModifier: ViewModifier {
    let action: (UIDeviceOrientation) -> Void

    func body(content: Content) -> some View {
        content
            .onAppear()
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
                action(UIDevice.current.orientation)
            }
    }
}

// A View wrapper to make the modifier easier to use
extension View {
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
    }
}
