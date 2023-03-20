//
//  DialPad.swift
//  CBAFusion
//
//  Created by Cole M on 11/4/21.
//

import SwiftUI
import FCSDKiOS

struct DialPad: View {
    @Binding
    //@FCSDKTransportActor
    var string: String
    @Binding
    //@FCSDKTransportActor
    var legacyDTMF: Bool
    @EnvironmentObject
    //@FCSDKTransportActor
    var fcsdkCallService: FCSDKCallService
    @EnvironmentObject var callKitManager: CallKitManager
    
    var body: some View {
        VStack {
            KeyPadRow(keys: ["1", "2", "3"])
            KeyPadRow(keys: ["4", "5", "6"])
            KeyPadRow(keys: ["7", "8", "9"])
            KeyPadRow(keys: ["*", "0", "#"])
            KeyPadRow(keys: ["+", "⌫"])
        }.environment(\.keyPadButtonAction, self.keyWasPressed(_:)) }
    
    private func keyWasPressed(_ key: String) {
        Task {
            await press(key)
        }
    }
    
   //@FCSDKTransportActor
    func press(_ key: String) async {
        if self.fcsdkCallService.fcsdkCall?.call != nil {
            if self.legacyDTMF {
                self.fcsdkCallService.fcsdkCall?.call?.playDTMFCode(key, localPlayback: true)
            } else {
                // Really should use this and let Apple handle DTMF Stuff, but if you want you can use the Legacy way with no problem
                Task {
                    await self.callKitManager.sendDTMF(uuid: self.fcsdkCallService.fcsdkCall!.id, digit: key)
                }
            }
        } else {
            switch key {
            case "⌫":
                string.removeLast()
                if string.isEmpty { string = "0" }
            case _ where string == "0": string = key
            default: string.append(key)
            }
        }
    }
}


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

struct KeyPadButton: View {
    var key: String
    
    var body: some View {
        Button(action: { self.action(self.key) }) {
            Color.clear
                .overlay(Circle().stroke(Color.blue))
                .overlay(Text(key))
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
