//
//  AutoResizingTextView.swift
//  CBAFusion
//
//  Created by Cole M on 9/1/21.
//

import SwiftUI


/// A SwiftUI view that wraps a UITextView and automatically adjusts its height based on the content.
struct AutoSizingTextView: UIViewRepresentable {
    
    // Binding properties for the text, height, and placeholder
    @Binding var text: String
    @Binding var height: CGFloat
    @Binding var placeholder: String
    
    /// Creates a coordinator to manage the interaction between the SwiftUI view and the UIKit view.
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    /// Creates the initial UITextView to be displayed.
    /// - Parameter context: The context in which the view is created.
    /// - Returns: A UITextView configured for auto-sizing.
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.textContainerInset = .zero
        textView.textContainer.lineFragmentPadding = 0
        textView.isEditable = true // Allow editing
        textView.isScrollEnabled = false // Disable scrolling for auto-sizing
        textView.text = self.placeholder
        textView.font = .systemFont(ofSize: 14, weight: .regular)
        textView.backgroundColor = .black
        textView.textColor = .white
        textView.delegate = context.coordinator
        return textView
    }
    
    /// Updates the UITextView when the SwiftUI view's state changes.
    /// - Parameters:
    ///   - uiView: The UITextView to be updated.
    ///   - context: The context in which the view is updated.
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = self.text.isEmpty ? self.placeholder : self.text // Show placeholder if text is empty
        Task {
            await MainActor.run {
                withAnimation {
                    self.height = uiView.contentSize.height // Update height based on content size
                    if uiView.text.count > 0 {
                        let location = uiView.text.count - 1
                        let bottom = NSMakeRange(location, 1)
                        uiView.scrollRangeToVisible(bottom) // Scroll to the bottom if needed
                    }
                }
            }
        }
    }
    
    /// A coordinator class to manage interactions between the SwiftUI view and the UITextView.
    class Coordinator: NSObject, UITextViewDelegate {
        var parent: AutoSizingTextView
        
        /// Initializes the coordinator with a reference to the parent AutoSizingTextView.
        /// - Parameter parent: The parent AutoSizingTextView instance.
        init(parent: AutoSizingTextView) {
            self.parent = parent
        }
        
        /// Called when the text in the UITextView changes.
        /// - Parameter textView: The UITextView that changed.
        func textViewDidChange(_ textView: UITextView) {
            Task {
                await MainActor.run {
                    self.parent.height = textView.contentSize.height // Update height
                    self.parent.text = textView.text // Update text binding
                }
            }
        }
    }
}
