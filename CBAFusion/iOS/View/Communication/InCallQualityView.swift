//
//  InCallQualityView.swift
//  CBAFusion
//
//  Created by Cole M on 9/13/23.
//

import SwiftUI

/// A view that displays the current call quality during a video call.
/// The quality is represented as a progress bar, with red indicating poor quality
/// and green indicating good quality.
struct InCallQualityView: View {
    
    @EnvironmentObject var fcsdkService: FCSDKCallService // Environment object for call service
    @State private var quality: CGFloat = 0 // State variable to hold the current quality value

    var body: some View {
        ZStack(alignment: .leading) {
            // Background rectangle representing poor quality
            Rectangle()
                .foregroundColor(.red)
                .frame(height: 30)
            
            // Foreground rectangle representing current quality
            Rectangle()
                .foregroundColor(.green)
                .frame(width: self.quality, height: 30)
                .animation(.easeInOut) // Animate changes in quality
        }
        .cornerRadius(12) // Rounded corners for the quality indicator
        .valueChanged(value: self.fcsdkService.callQuality) { newValue in
            // Update the quality based on the new value from the call service
            self.quality = (300 * (CGFloat(newValue) * 0.01))
        }
        .frame(width: 300, height: 30) // Fixed size for the quality view
    }
}

/// Preview provider for InCallQualityView to visualize the component in Xcode's canvas.
struct InCallQualityView_Previews: PreviewProvider {
    static var previews: some View {
        InCallQualityView()
            .environmentObject(FCSDKCallService()) // Provide a mock environment object for preview
    }
}
