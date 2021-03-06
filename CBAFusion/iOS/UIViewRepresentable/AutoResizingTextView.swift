//
//  AutoResizingTextView.swift
//  CBAFusion
//
//  Created by Cole M on 9/1/21.
//

import SwiftUI


struct AutoSizingTextView : UIViewRepresentable {
    
    @Binding var text: String
    @Binding var height: CGFloat
    @Binding var placeholder: String
    
    func makeCoordinator() -> Coordinator {
        return AutoSizingTextView.Coordinator(parent: self)
    }
    
    
    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.isEditable = false
        view.isScrollEnabled = true
        view.text = self.placeholder
        view.font = .systemFont(ofSize: 14, weight: .regular)
        view.backgroundColor = .black
        view.textColor = .white
        view.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = self.text
        Task {
            await MainActor.run {
                withAnimation {
                    self.height = uiView.contentSize.height
                    if uiView.text.count > 0 {
                        let location = uiView.text.count - 1
                        let bottom = NSMakeRange(location, 1)
                        uiView.scrollRangeToVisible(bottom)
                    }
                }
            }
        }
    }
    
    class Coordinator:NSObject, UITextViewDelegate {
        var parent: AutoSizingTextView
        
        init(parent: AutoSizingTextView) {
            self.parent = parent
        }
        
        func textViewDidChange(_ textView: UITextView) {
            Task {
                await MainActor.run {
                    self.parent.height = textView.contentSize.height
                    self.parent.text = textView.text
                }
            }
        }
    }
}


