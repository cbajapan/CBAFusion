//
//  CallSheet.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/8/21.
//

import SwiftUI

struct CallSheet: View {
    
    @Binding var destination: String
    @Binding var hasVideo: Bool
    @Binding var callStarted: Bool
    @Binding var showFullSheet: ActiveSheet?
    @Environment(\.presentationMode) private var presentationMode

    var body: some View {
        NavigationView {
            Form {
                HStack(alignment: .bottom) {
                    Text("End Point:")
                    TextField("Destination...", text: self.$destination)
                }
                Toggle("Want Video?", isOn: self.$hasVideo)
            }
            .navigationTitle("Let's Talk")
            .navigationBarItems(leading:
                                    Button(action: {
                self.presentationMode.wrappedValue.dismiss()
            }, label: {
                Text("Cancel")
                    .foregroundColor(Color.red)
            }),
                                trailing:
                                    Button(action: {
                
                Task {
                    await self.makeCall()
                }
            }, label: {
                Text("Connect")
                    .foregroundColor(Color.blue)
            })
            )
        }
    }
    
    func makeCall() async {
        self.presentationMode.wrappedValue.dismiss()
        self.callStarted = true
        self.showFullSheet = .communincationSheet
        print(self.hasVideo, "HAS VIDEO")
    }
}

//struct CallSheet_Previews: PreviewProvider {
//    static var previews: some View {
//        CallSheet(callStarted: .constant(false), showFullSheet: .constant(.callSheet))
//    }
//}


struct CallDetails {
    var destination = ""
    var hasVideo = false
    var delay = 0

    var isValid: Bool {
        destination.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false
    }
}
