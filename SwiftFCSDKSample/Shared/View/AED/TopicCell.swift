//
//  TopicCell.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/1/21.
//

import SwiftUI

struct TopicCell: View {
    
    var topic: String
    @Binding var isChecked: Bool
    
    var body: some View {
        if #available(iOS 15.0, *) {
            HStack {
                Text(topic)
                Spacer()
                if self.isChecked {
                    Image(systemName: "checkmark")
                        .foregroundColor(Color.green)
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
}
