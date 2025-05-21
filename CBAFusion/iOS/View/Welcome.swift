//
//  Welcome.swift
//  CBAFusion
//
//  Created by Cole M on 9/2/21.
//

import SwiftUI

/// A view that displays a welcome screen with animations for the title, logo, and captions.
struct Welcome: View {
    
    @Binding var animateCommunication: Bool
    @Binding var animateAED: Bool
    
    // State variables for managing animations
    @State private var isAnimating = false
    @State private var rotation: Double = 0.0
    
    var body: some View {
        VStack {
            Spacer()
            
            // Title with animation
            titleView
            
            // Logo with 3D rotation effect
            logoView
            
            // Caption with animation
            captionView
            
            Spacer()
            
            // Task prompt with animation
            taskPromptView
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onAppear {
            startAnimations()
        }
    }
    
    /// View for the title with animation.
    private var titleView: some View {
        Group {
            if isAnimating {
                Text("CBAFusion")
                    .font(.system(size: 30))
                    .fontWeight(.bold)
                    .transition(.slide)
                    .animation(.easeInOut(duration: 2), value: isAnimating)
            }
        }
    }
    
    /// View for the logo with a 3D rotation effect.
    private var logoView: some View {
        Image("cbaLogo")
            .rotation3DEffect(.degrees(rotation), axis: (x: 0, y: 1, z: 0))
            .animation(.interpolatingSpring(stiffness: 5, damping: 1), value: rotation)
    }
    
    /// View for the caption with animation.
    private var captionView: some View {
        Group {
            if isAnimating {
                Text("Powered by Communication Business Avenue inc.")
                    .font(.system(size: 12))
                    .animation(.interactiveSpring(), value: isAnimating)
            }
        }
    }
    
    /// View for the task prompt with animation.
    private var taskPromptView: some View {
        Group {
            if isAnimating {
                Text(animateCommunication ? "Please Login to start communicating" : "Please Login to start Application Event Distribution")
                    .multilineTextAlignment(.center)
                    .animation(.easeInOut(duration: 3), value: isAnimating)
                    .transition(.slide)
            }
        }
    }
    
    /// Starts the animations when the view appears.
    private func startAnimations() {
        withAnimation(.easeInOut(duration: 2)) {
            isAnimating = true
        }
        
        // Rotate the logo continuously
        withAnimation(.interpolatingSpring(stiffness: 5, damping: 1)) {
            rotation += 360
        }
    }
}

struct Welcome_Previews: PreviewProvider {
    static var previews: some View {
        Welcome(animateCommunication: .constant(false), animateAED: .constant(false))
    }
}
