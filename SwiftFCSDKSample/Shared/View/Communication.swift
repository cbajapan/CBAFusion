//
//  Communication.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import SwiftUI

struct Communication: View {
    var body: some View {
        ZStack {
            CommunicationViewControllerRepresenable()
        }.background(Color.white).ignoresSafeArea(.all)
    }
}

struct Communication_Previews: PreviewProvider {
    static var previews: some View {
        Communication()
    }
}
