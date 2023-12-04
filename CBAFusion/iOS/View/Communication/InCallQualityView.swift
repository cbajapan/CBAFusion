//
//  InCallQualityView.swift
//  CBAFusion
//
//  Created by Cole M on 9/13/23.
//

import SwiftUI

struct InCallQualityView: View {
    
    @EnvironmentObject var fcsdkService: FCSDKCallService
    @State var quality: CGFloat = 0
    
    var body: some View {
        ZStack(alignment: .leading) {
            Rectangle()
                .foregroundColor(.red)
                .frame(height: 30)
            Rectangle()
                .foregroundColor(.green)
                .frame(width: self.quality, height: 30)
                .animation(.easeInOut)
        }
        .cornerRadius(12)
        .valueChanged(value: self.fcsdkService.callQuality) { newValue in
            self.quality = (300 * (CGFloat(newValue) * 0.01))
        }
        .frame(width: 300, height: 30)
    }
}


struct InCallQualityView_Previews: PreviewProvider {
    static var previews: some View {
        InCallQualityView()
    }
}
