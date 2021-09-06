//
//  Session.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import SwiftUI

struct Session: View {
    
    @Environment(\.presentationMode) var presentationMode
    @Binding var currentTabIndex: Int
    @Binding var showSubscriptionsSheet: Bool
    var parentTabIndex: Int
    
    var body: some View {
        VStack {
            Button {
                print("Logout")
            } label: {
                Text("Logout")
                    .font(.title2)
                    .bold()
            }

        }
        .onAppear {
            self.currentTabIndex = self.parentTabIndex
        }
    }
}

struct Session_Previews: PreviewProvider {
    static var previews: some View {
        Session(currentTabIndex: .constant(0), showSubscriptionsSheet: .constant(false), parentTabIndex: 0)
    }
}
