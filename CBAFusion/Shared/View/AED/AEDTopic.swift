//
//  AEDTopic.swift
//  CBAFusion
//
//  Created by Cole M on 12/6/21.
//

import SwiftUI
import FCSDKiOS

struct AEDTopic: View {
    
    @State var topic: ACBTopic
    @State var checked: Bool = false
    @Binding var console: String
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var aedService: AEDService
    
    var body: some View {
        HStack{
            Text(topic.name)
            Spacer()
            if self.checked {
                Image(systemName: "checkmark")
                    .foregroundColor(Color.green)
            }
        }
        .onTapGesture {
            self.checked.toggle()
            if self.checked {
                Task {
                    await self.didTapTopic(topic)
                }
            }
        }
    }
    
    @MainActor
    func didTapTopic(_ topic: ACBTopic) async {
        if !topic.name.isEmpty {
            self.aedService.currentTopic = self.authenticationService.acbuc?.aed?.createTopic(withName: topic.name, delegate: self.aedService)
            let msg = "Current topic is \(self.aedService.currentTopic?.name ?? "")."
            self.console += "\n\(msg)"
        } else {
            self.authenticationService.showErrorAlert = true
            self.authenticationService.errorMessage = "Topic Name is empty"
        }
    }
}
