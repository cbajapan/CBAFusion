//
//  DialPad.swift
//  CBAFusion
//
//  Created by Cole M on 11/4/21.
//

import SwiftUI
import FCSDKiOS

/// A view representing a dial pad for entering DTMF codes.
struct DialPad: View {
    @Binding var string: String
    @Binding var legacyDTMF: Bool
    @EnvironmentObject var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var callKitManager: CallKitManager
    
    var body: some View {
        VStack {
            // Create rows of keys for the dial pad
            KeyPadRow(keys: ["1", "2", "3"])
            KeyPadRow(keys: ["4", "5", "6"])
            KeyPadRow(keys: ["7", "8", "9"])
            KeyPadRow(keys: ["*", "0", "#"])
            KeyPadRow(keys: ["+", "⌫"])
        }
        .environment(\.keyPadButtonAction, self.keyWasPressed(_:))
    }
    
    /// Handles the key press action.
    /// - Parameter key: The key that was pressed.
    private func keyWasPressed(_ key: String) {
        Task {
            await press(key)
        }
    }
    
    /// Processes the key press and performs the appropriate action.
    /// - Parameter key: The key that was pressed.
    func press(_ key: String) async {
        guard let call = self.fcsdkCallService.fcsdkCall?.call else {
            handleLocalKeyPress(key)
            return
        }
        
        if self.legacyDTMF {
            // Play DTMF code using legacy method
            call.playDTMFCode(key, localPlayback: true)
        } else {
            // Send DTMF using CallKit
            await self.callKitManager.sendDTMF(uuid: self.fcsdkCallService.fcsdkCall!.id, digit: key)
        }
    }
    
    /// Handles local key presses when there is no active call.
    /// - Parameter key: The key that was pressed.
    private func handleLocalKeyPress(_ key: String) {
        switch key {
        case "⌫":
            // Handle backspace
            if !string.isEmpty {
                string.removeLast()
            }
            if string.isEmpty {
                string = "0"
            }
        case _ where string == "0":
            // Replace "0" with the pressed key
            string = key
        default:
            // Append the pressed key to the string
            string.append(key)
        }
    }
}

/// A view representing a row of keys in the dial pad.
struct KeyPadRow: View {
    var keys: [String]
    
    var body: some View {
        HStack {
            ForEach(keys, id: \.self) { key in
                KeyPadButton(key: key)
            }
        }
    }
}

/// A button representing a single key in the dial pad.
struct KeyPadButton: View {
    var key: String
    
    var body: some View {
        Button(action: { self.action(self.key) }) {
            Color.clear
                .overlay(Circle().stroke(Color.blue))
                .overlay(Text(key).font(.largeTitle))
                .frame(width: 80, height: 80) // Set a fixed size for the button
        }
    }
    
    enum ActionKey: EnvironmentKey {
        static var defaultValue: (String) -> Void { { _ in } }
    }
    
    @Environment(\.keyPadButtonAction) var action: (String) -> Void
}

extension EnvironmentValues {
    var keyPadButtonAction: (String) -> Void {
        get { self[KeyPadButton.ActionKey.self] }
        set { self[KeyPadButton.ActionKey.self] = newValue }
    }
}

#if DEBUG
struct KeyPadButton_Previews: PreviewProvider {
    static var previews: some View {
        KeyPadButton(key: "8")
            .padding()
            .frame(width: 80, height: 80)
            .previewLayout(.sizeThatFits)
    }
}
#endif
  
