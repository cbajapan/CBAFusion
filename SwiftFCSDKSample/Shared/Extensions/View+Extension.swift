////
////  View+Extension.swift
////  SwiftFCSDKSample
////
////  Created by Cole M on 9/1/21.
////
//
//import UIKit
//import SwiftUI
//
//
//#if canImport(UIKit)
//extension View {
//
//    func hideKeyboard() {
//        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
//    }
//    
//    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
//        self.modifier(DeviceRotationViewModifier(action: action))
//    }
//}
//
//struct DeviceRotationViewModifier: ViewModifier {
//    let action: (UIDeviceOrientation) -> Void
//
//    func body(content: Content) -> some View {
//        content
//            .onAppear()
//            .onReceive(NotificationCenter.default.publisher(for: UIDevice.orientationDidChangeNotification)) { _ in
//                action(UIDevice.current.orientation)
//            }
//    }
//    
//    static func isPortrait(orientation: UIDeviceOrientation) -> Bool {
//        var currentOrientation: Bool?
//        if orientation.isPortrait {
//            currentOrientation = true
//        }
//        guard let o = currentOrientation else {return false}
//        return o
//    }
//    
//    static func isLandscape(orientation: UIDeviceOrientation) -> Bool {
//        var currentOrientation: Bool?
//        if orientation.isLandscape {
//            currentOrientation = true
//        }
//        guard let o = currentOrientation else {return false}
//        return o
//    }
//     static func isFlat(orientation: UIDeviceOrientation) -> Bool {
//        var currentOrientation: Bool?
//        if orientation.isFlat {
//            currentOrientation = true
//        }
//        guard let o = currentOrientation else {return false}
//        return o
//    }
//}
//#endif
//
