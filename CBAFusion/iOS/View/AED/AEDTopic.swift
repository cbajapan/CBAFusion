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
    @State var name: String = ""
    @State var checked: Bool = false
    @Binding var console: String
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var aedService: AEDService
    
    var body: some View {
        HStack{
            if #available(iOS 15, *) {
                Text(name)
                    .onAppear {
                                self.name = topic.name
                            }
            } else {
                Text(name)
                    .valueChanged(value: topic.name) { newValue in
                        self.name = newValue
                    }
            }
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
    
   
    func didTapTopic(_ topic: ACBTopic) async {
        if !topic.name.isEmpty {
            let uc = authenticationService.uc
            self.aedService.currentTopic = uc?.aed.createTopic(withName: topic.name, delegate: self.aedService)
            let msg = "Current topic is \(self.aedService.currentTopic?.name ?? "")."
            self.console += "\n\(msg)"
        } else {
            await MainActor.run {
                self.authenticationService.showErrorAlert = true
                self.authenticationService.errorMessage = "Topic Name is empty"
            }
        }
    }
}
