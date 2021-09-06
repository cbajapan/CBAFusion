//
//  Welcome.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/2/21.
//

import SwiftUI

struct Welcome: View {
    
    @Binding var animateCommunication: Bool
    @Binding var animateAED: Bool
    
    var body: some View {
        VStack {
            Spacer()
            Text("FCSDK-iOS")
                .font(.system(size: 30))
                .fontWeight(.bold)
            Text("By CBA-Japan")
                .fontWeight(.light)
                .font(.system(size: 20))
                .padding(.leading, 10)
            Spacer()
            if self.animateCommunication {
                Text("Please Login to start communicating")
            }
            if self.animateAED {
                Text("Please Login to start Application Event Distribution")
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}

struct Welcome_Previews: PreviewProvider {
    static var previews: some View {
        Welcome(animateCommunication: .constant(false), animateAED: .constant(false))
    }
}
