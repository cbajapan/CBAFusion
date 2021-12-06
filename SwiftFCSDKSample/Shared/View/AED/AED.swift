//
//  AED.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import SwiftUI
import FCSDKiOS

struct AED: View{
    
    @State var topicName = ""
    @State var expiry = ""
    @State var key = ""
    @State var value = ""
    @State private var messageText = ""
    @State private var placeholder = ""
    @State private var messageHeight: CGFloat = 0
    @State private var keyboardHeight: CGFloat = 0
    @State private var console: String = ""
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var aedService: AEDService
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView  {
                Form {
                    Section(header: Text("Connected Topics")) {
                        List {
                            ForEach(self.aedService.topicList, id: \.self) { topic in
                                AEDTopic(topic: topic, console: self.$console)
                                .swipeActions(edge: .trailing) {
                                    Button("Delete") {
                                        Task {
                                            await self.disconnectOrDeleteTopic(topic, delete: true)
                                        }
                                    }
                                    .tint(.red)
                                }
                                .swipeActions(edge: .leading) {
                                    Button("Disconnect") {
                                        Task {
                                            await self.disconnectOrDeleteTopic(topic, delete: false)
                                        }
                                    }
                                    .tint(.green)
                                }
                            }
                        }
                    }
                    Section(header: Text("Topic")) {
                        TextField("Topic Name", text: $topicName)
                        TextField("Expiry", text: $expiry)
                            .keyboardType(.numberPad)
                    }
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        Button {
                            Task {
                                await self.connectToTopic()
                            }
                        } label: {
                            Text("Connect")
                        }
                        .buttonStyle(.borderless)
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
                    if UIDevice.current.userInterfaceIdiom == .phone {
                        Section(header: Text("Console")) {
                            AutoSizingTextView(text: self.$console, height: self.$messageHeight, placeholder: self.$placeholder)
                                .frame(width: geometry.size.width - 80, height: self.messageHeight < 350 ? self.messageHeight : 350)
                                .font(.body)
                                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                                .background(colorScheme == .dark ? Color.black : Color.white)
                                .background(colorScheme == .dark ? Color.black : Color.white)
                                .listRowBackground(colorScheme == .dark ? Color.black : Color.white)
                        }

                    } else {
                        NavigationLink(destination: Console(topicName: self.$topicName, expiry: self.$expiry)) {
                            Text("Connect")
                                .foregroundColor(.blue)
                        }
                    }
                }
                .navigationBarTitleDisplayMode(.inline)
                .toolbar(content: {
                    ToolbarItem(placement: .principal, content: {
                        Text("Application Event Distribution")
                    })})
            }
            .onChange(of: self.aedService.consoleMessage) { newValue in
                self.console += "\n\(newValue)"
            }
            .alert(self.authenticationService.errorMessage, isPresented: self.$authenticationService.showErrorAlert, actions: {
                Button("OK", role: .cancel) {
                    self.authenticationService.showErrorAlert = false
                }
            })
        }.onTapGesture {
            hideKeyboard()
        }
    }
    
    func disconnectOrDeleteTopic(_ topic: ACBTopic?, delete: Bool) async {
        guard let topic = topic else {return}
        if !topic.name.isEmpty {
            if self.aedService.currentTopic == topic {
                self.aedService.currentTopic = nil
            }
            
            if topic.connected {
                topic.disconnect(withDeleteFlag: delete)
                self.aedService.topicList.removeAll(where: { $0 == topic })
                print(self.aedService.topicList)
                await MainActor.run {
                    let msg = "Topic \(topic.name) disconnected."
                    self.aedService.consoleMessage = msg
                }
            } else {
                await MainActor.run {
                    let msg = "Topic \(self.aedService.currentTopic?.name ?? "") already disconnected."
                    self.aedService.consoleMessage = msg
                }
            }
            
            if self.aedService.currentTopic == nil && self.aedService.topicList.count > 0 {
                self.aedService.currentTopic = topic
                self.aedService.currentTopic = self.aedService.topicList.first
            }
        } else {
            self.authenticationService.showErrorAlert = true
            self.authenticationService.errorMessage = "Topic Name is empty"
        }
        
    }
    
    @MainActor
    func connectToTopic() async {
        if !self.topicName.isEmpty{
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
        if !self.key.isEmpty && !self.value.isEmpty {
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
        if !self.key.isEmpty {
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
        if !self.messageText.isEmpty{
            self.aedService.currentTopic?.sendAedMessage(self.messageText)
            self.messageText = ""
        } else {
            self.authenticationService.showErrorAlert = true
            self.authenticationService.errorMessage = "Please enter a Message"
        }
    }
}

struct AED_Previews: PreviewProvider {
    static var previews: some View {
        AED()
    }
}

