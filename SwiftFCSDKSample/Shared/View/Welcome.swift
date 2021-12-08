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
    @State private var animateTitle: Bool = false
    @State private var animateCaption: Bool = false
    @State private var animateTask: Bool = false
    @State private var rotation = 0.0
    var body: some View {
        VStack {
            Spacer()
            if self.animateTitle {
                VStack {
                    Text("FusionSDK")
                        .font(.system(size: 30))
                        .fontWeight(.bold)
                    
                }
                .animation(.easeInOut(duration: 20), value: 1)
                .transition(.slide)
            }
                    Image("cbaLogo")
                    .rotation3DEffect(.degrees(rotation), axis: (x: 0, y:1, z:0))
            
            if self.animateCaption {
                Text("Powered by Communication Business Avenue inc.")
                    .font(.system(size: 12))
                    .animation(.interactiveSpring(), value: 1)
            }
            Spacer()
            if self.animateTask {
                Text(self.animateCommunication ? "Please Login to start communicating" : "Please Login to start Application Event Distribution")
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 3), value: 1)
                    .transition(.slide)
            }
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            withAnimation(.easeInOut(duration: 2)) {
                self.animateTitle = true
            }
            withAnimation(.easeInOut(duration: 13)) {
                self.animateCaption = true
            }
            withAnimation(.easeInOut(duration: 3)) {
                self.animateTask = true
            }
            withAnimation(.interpolatingSpring(stiffness: 5, damping: 1)) {
                self.rotation += 360
            }
        }
    }
}

struct Welcome_Previews: PreviewProvider {
    static var previews: some View {
        Welcome(animateCommunication: .constant(false), animateAED: .constant(false))
    }
}
