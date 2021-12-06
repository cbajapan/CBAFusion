//
//  console.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 12/2/21.
//

import SwiftUI
import FCSDKiOS

struct Console: View {
    
    @Binding var topicName: String
    @Binding var expiry: String
    @State var console = ""
    @State var messageHeight: CGFloat = 0
    @State var key = ""
    @State var value = ""
    @State private var messageText = ""
    @State private var placeholder = ""
    @State private var isChecked: Bool = false
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var aedService: AEDService
    @EnvironmentObject var authenticationService: AuthenticationService
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                HStack(alignment: .top) {
                    Form {
                        Section(header: Text("Data")) {
                            TextField("Key", text: $key)
                            TextField("Value", text: $value)
                            Button {
                                Task {
                                    await self.publishData()
                                }
                            } label: {
                                Text("Publish")
                            }
                            
                            
                            Button {
                                Task {
                                    await self.deleteData()
                                }
                            } label: {
                                Text("Delete")
                            }
                        }
                        Section(header: Text("Message")) {
                            TextField("Your message", text: $messageText)
                            Button {
                                Task {
                                    await self.sendMessage()
                                }
                            } label: {
                                Text("Send")
                            }
                        }
                    }
                    Spacer()
                        .frame(width: geometry.size.width / 2, alignment: .topLeading)
                }.frame(height: geometry.size.height / 2)
                Divider()
                VStack(alignment: .leading) {
                    Text("Console").foregroundColor(.gray)
                        .padding()
                    AutoSizingTextView(text: self.$console, height: self.$messageHeight, placeholder: self.$placeholder)
                        .padding()
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .font(.body)
                }
            } .padding(EdgeInsets(top: 0, leading: 0, bottom: 10, trailing: 0))
        }
        .onAppear {
            Task {
                await self.connectToTopic()
            }
        }
        .onChange(of: self.aedService.consoleMessage) { newValue in
            print(newValue, "New Value")
            self.console += "\n\(newValue)"
        }
    }
    
    @MainActor
    func didTapTopic(_ topic: ACBTopic) async {
        if self.topicName.count > 0 {
            self.aedService.currentTopic = self.authenticationService.acbuc?.aed?.createTopic(withName: topic.name, delegate: self.aedService)
            let msg = "Current topic is \(self.aedService.currentTopic?.name ?? "")."
            self.console += "\n\(msg)"
        } else {
            self.authenticationService.showErrorAlert = true
            self.authenticationService.errorMessage = "Topic Name is empty"
        }
    }
    
    @MainActor
    func connectToTopic() async {
        if self.topicName.count > 0 {
            let expiry = Int(self.expiry) ?? 0
            self.aedService.currentTopic = self.authenticationService.acbuc?.aed?.createTopic(withName: self.topicName, expiryTime: expiry, delegate: self.aedService)
            self.topicName = ""
            self.expiry = ""
        } else {
            self.authenticationService.showErrorAlert = true
            self.authenticationService.errorMessage = "Please enter a Topic Name"
        }
    }
    
    @MainActor
    func publishData() async {
        if self.key.count > 0 && self.value.count > 0 {
            self.aedService.currentTopic?.submitData(withKey: self.key, value: self.value)
            self.key = ""
            self.value = ""
        } else {
            self.authenticationService.showErrorAlert = true
            self.authenticationService.errorMessage = "Please enter a Key Value Pair"
        }
    }
    
    @MainActor
    func deleteData() async {
        if self.key.count > 0 {
            self.aedService.currentTopic?.deleteData(withKey: self.key)
            self.key = ""
            self.value = ""
        } else {
            self.authenticationService.showErrorAlert = true
            self.authenticationService.errorMessage = "Please enter a Key to delete"
        }
    }
    
    @MainActor
    func sendMessage() async {
        if self.messageText.count > 0 {
            self.aedService.currentTopic?.sendAedMessage(self.messageText)
            self.messageText = ""
        } else {
            self.authenticationService.showErrorAlert = true
            self.authenticationService.errorMessage = "Please enter a Message"
        }
    }
}
