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
    @Environment(\.presentationMode) private var presentationMode
    
    var body: some View {
            Form {
                HStack(alignment: .bottom) {
                    Text("End Point:")
                    TextField("Destination...", text: self.$destination)
                }
                Toggle("Want Video?", isOn: self.$hasVideo)
            }
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

