//
//  View+Extension.swift
//  CBAFusion
//
//  Created by Cole M on 9/1/21.
//

import UIKit
import SwiftUI
import Combine

#if canImport(UIKit)
extension View {

    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
    
    func onRotate(perform action: @escaping (UIDeviceOrientation) -> Void) -> some View {
        self.modifier(DeviceRotationViewModifier(action: action))
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
    
    static func isPortrait(orientation: UIDeviceOrientation) -> Bool {
        var currentOrientation: Bool?
        if orientation.isPortrait {
            currentOrientation = true
        }
        guard let o = currentOrientation else {return false}
        return o
    }
    
    static func isLandscape(orientation: UIDeviceOrientation) -> Bool {
        var currentOrientation: Bool?
        if orientation.isLandscape {
            currentOrientation = true
        }
        guard let o = currentOrientation else {return false}
        return o
    }
     static func isFlat(orientation: UIDeviceOrientation) -> Bool {
        var currentOrientation: Bool?
        if orientation.isFlat {
            currentOrientation = true
        }
        guard let o = currentOrientation else {return false}
        return o
    }
}
#endif

extension View {
    /// A backwards compatible wrapper for iOS 14 `onChange`
    @ViewBuilder func valueChanged<T: Equatable>(value: T, onChange: @escaping (T) -> Void) -> some View {
        if #available(iOS 14.0, *) {
            self.onChange(of: value, perform: onChange)
        } else {
            self.onReceive(Just(value)) { (value) in
                onChange(value)
            }
        }
    }
    
    
    @ViewBuilder func navigationTitle(title: String) -> some View {
        if #available(iOS 14.0, *) {
            self.navigationTitle(title)
        } else {
            self.navigationBarTitle(Text(title), displayMode: .inline)
        }
    }
    
    @ViewBuilder func fullScreenSheet<Content>(isPresented: Binding<Bool>, onDismiss: (() -> Void)? = nil, @ViewBuilder content: @escaping () -> Content) -> some View where Content : View {
        if #available(iOS 14.0, *) {
            self.fullScreenCover(isPresented: isPresented, onDismiss: onDismiss, content: content)
        } else {
            self.sheet(isPresented: isPresented, onDismiss: onDismiss, content: content)
        }
    }
}



// Toolbar.swift
import SwiftUI
import UIKit
import Foundation

struct Toolbar: UIViewRepresentable {
    typealias UIViewType = UIToolbar
    var items: [UIBarButtonItem]
    var toolbar: UIToolbar
    
    init(items: [UIBarButtonItem]) {
        self.toolbar = UIToolbar()
        self.items = items
    }

    func makeUIView(context: UIViewRepresentableContext<Toolbar>) -> UIToolbar {
        toolbar.setItems(self.items, animated: true)
        toolbar.barStyle = .default
        toolbar.sizeToFit()
        return toolbar
    }
    
    func updateUIView(_ uiView: UIToolbar, context: UIViewRepresentableContext<Toolbar>) {
    }
    
    func makeCoordinator() -> Toolbar.Coordinator {
        Coordinator(self)
    }
    
    final class Coordinator: NSObject, UIToolbarDelegate, UIBarPositioning {
        var toolbar: Toolbar
        var barPosition: UIBarPosition
        
        init(_ toolbar: Toolbar) {
            self.toolbar = toolbar
            self.barPosition = .top
        }
        
        private func position(for: UIToolbar) -> UIBarPosition {
            return .top
        }
    }
}
