//
//  AutoResizingTextView.swift
//  SwiftFCSDKSample
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
        view.isEditable = false
        view.isScrollEnabled = true
        view.text = self.placeholder
        view.font = .systemFont(ofSize: 18)
        view.textColor = .gray
        view.delegate = context.coordinator
        return view
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        DispatchQueue.main.async {
            withAnimation {
                self.height = uiView.contentSize.height
            }
        }
    }
    
    class Coordinator:NSObject, UITextViewDelegate {
        var parent: AutoSizingTextView
        
        init(parent: AutoSizingTextView) {
            self.parent = parent
        }
        
        func textViewDidBeginEditing(_ textView: UITextView) {
            if self.parent.text == "" {
                textView.text = ""
                textView.textColor = .white
            }
        }
        
        func textViewDidEndEditing(_ textView: UITextView) {
            if self.parent.text == "" {
                textView.text = parent.placeholder
                textView.textColor = .gray
            }
        }
        
        func textViewDidChange(_ textView: UITextView) {
            DispatchQueue.main.async {
                self.parent.height = textView.contentSize.height
                self.parent.text = textView.text
            }
        }
    }
}


