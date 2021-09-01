//
//  TopicCell.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/1/21.
//

import SwiftUI

struct TopicCell: View {
    
    var topic: String
    @State private var isChecked: Bool = false
    
    var body: some View {
        if #available(iOS 15.0, *) {
            HStack {
                Text(topic)
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            print("Deleting conversation")
                        } label: {
                            Label("Delete", systemImage: "trash.fill")
                        }
                    }
                Spacer()
                if self.isChecked {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color.green)
                }
            }
            .onTapGesture(count: 1) {
                if self.isChecked == true {
                    self.isChecked = false
                } else {
                    self.isChecked = true
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}

struct TopicCell_Previews: PreviewProvider {
    static var previews: some View {
        TopicCell(topic: "Topic 1")
    }
}
