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
    @State private var isChecked: Bool = false
    @EnvironmentObject var authenticationServices: AuthenticationService
    @EnvironmentObject var aedService: AEDService
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
        NavigationView  {
            Form {
                Section(header: Text("Topic")) {
                    TextField("Topic Name", text: $topicName)
                    TextField("Expiry", text: $expiry)
                }
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
                
                Section(header: Text("Connected Topics")) {
                    List {
                        ForEach(self.aedService.topicList, id: \.id) { topic in
                            TopicCell(topic: topic.name ?? "No Topic Name", isChecked: self.$isChecked)
                                    .onTapGesture {
                                        Task {
                                        await self.didTapTopic(topic)
                                        }
                                        if self.isChecked == true {
                                            self.isChecked = false
                                        } else {
                                            self.isChecked = true
                                        }
                                    }
                                
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
                Section(header: Text("Console")) {
                    AutoSizingTextView(text: self.$console, height: self.$messageHeight, placeholder: self.$placeholder)
                        .frame(width: geometry.size.width - 80, height: self.messageHeight < 350 ? self.messageHeight : 350)
                        .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                        .background(colorScheme == .dark ? Color.black : Color.white)
                        .font(.body)
                }
                .background(colorScheme == .dark ? Color.black : Color.white)
                .listRowBackground(colorScheme == .dark ? Color.black : Color.white)
                .onChange(of: self.aedService.consoleMessage) { newValue in
                    self.console += "\n\(newValue)"
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                ToolbarItem(placement: .principal, content: {
                    Text("Application Event Distribution")
                })})
        }
        }
    }
    
    func disconnectOrDeleteTopic(_ topic: ACBTopic?, delete: Bool) async {
        if self.aedService.currentTopic == topic {
            self.aedService.currentTopic = nil
        }
        
        if topic?.connected != nil {
            topic?.disconnect(withDeleteFlag: delete)
            self.aedService.topicList.removeAll(where: { $0 == topic })
            print(self.aedService.topicList)
            await MainActor.run {
            let msg = "Topic \(topic?.name ?? "") disconnected."
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
        
    }

    @MainActor
    func didTapTopic(_ topic: ACBTopic) async {
        self.aedService.currentTopic = self.authenticationServices.acbuc?.aed?.createTopic(withName: topic.name ?? "", delegate: self.aedService)
        let msg = "Current topic is \(self.aedService.currentTopic?.name ?? "")."
        self.console += "\n\(msg)"
    }
    
    @MainActor
    func connectToTopic() async {
        let expiry = Int(self.expiry) ?? 0
        self.aedService.currentTopic = self.authenticationServices.acbuc?.aed?.createTopic(withName: self.topicName, expiryTime: expiry, delegate: self.aedService)
        self.topicName = ""
        self.expiry = ""
    }
    
    @MainActor
    func publishData() async {
        self.aedService.currentTopic?.submitData(withKey: self.key, value: self.value)
        self.key = ""
        self.value = ""
    }
    
    @MainActor
    func deleteData() async {
        self.aedService.currentTopic?.deleteData(withKey: self.key)
        self.key = ""
        self.value = ""
    }
    
    @MainActor
    func sendMessage() async {
        self.aedService.currentTopic?.sendAedMessage(self.messageText)
        self.messageText = ""
    }
}

struct AED_Previews: PreviewProvider {
    static var previews: some View {
        AED()
    }
}

