//
//  AED.swift
//  CBAFusion
//
//  Created by Cole M on 8/31/21.
//

//import SwiftUI
//import FCSDKiOS
//
//struct AED: View{
//    
//    @State var topicName = ""
//    @State var expiry = ""
//    @State var key = ""
//    @State var value = ""
//    @State private var messageText = ""
//    @State private var placeholder = ""
//    @State private var messageHeight: CGFloat = 0
//    @State private var keyboardHeight: CGFloat = 0
//    @State private var console: String = ""
//    @EnvironmentObject var authenticationService: AuthenticationService
//    @EnvironmentObject var aedService: AEDService
//    @Environment(\.colorScheme) var colorScheme
//    
//    var body: some View {
//        GeometryReader { geometry in
//            NavigationView  {
//                Form {
//                    Section(header: Text("Connected Topics")
//                                .foregroundColor(colorScheme == .dark ? .gray : .black)) {
//                        List {
//                            ForEach(self.aedService.topicList, id: \.self) { topic in
//                                AEDTopic(topic: topic, console: self.$console)
//                                if #available(iOS 15, *) {
//                                    AEDTopic(topic: topic, console: self.$console)
//                                    .swipeActions(edge: .trailing) {
//                                        Button("Delete") {
//                                            Task {
//                                                await self.disconnectOrDeleteTopic(topic, delete: true)
//                                            }
//                                        }
//                                        .tint(.red)
//                                    }
//                                    .swipeActions(edge: .leading) {
//                                        Button("Disconnect") {
//                                            Task {
//                                                await self.disconnectOrDeleteTopic(topic, delete: false)
//                                            }
//                                        }
//                                        .tint(.green)
//                                    }
//                                } else {
//                                    AEDTopic(topic: topic, console: self.$console)
//                                }
//                            }
//                        }
//                    }
//                    Section(header: Text("Topic")
//                                .foregroundColor(colorScheme == .dark ? .gray : .black)) {
//                        TextField("Topic Name", text: $topicName)
//                            .foregroundColor(colorScheme == .dark ? .white : .black)
//                        TextField("Expiry", text: $expiry)
//                            .foregroundColor(colorScheme == .dark ? .white : .black)
//                            .keyboardType(.numberPad)
//                    }
//                    if UIDevice.current.userInterfaceIdiom == .phone {
//                        Button {
//                            Task {
//                                await self.connectToTopic()
//                            }
//                        } label: {
//                            Text("Connect")
//                        }
//                        .buttonStyle(.borderless)
//                    Section(header: Text("Data")) {
//                        TextField("Key", text: $key)
//                        TextField("Value", text: $value)
//                        Button {
//                            Task {
//                                await self.publishData()
//                            }
//                        } label: {
//                            Text("Publish")
//                        }
//
//
//                        Button {
//                            Task {
//                                await self.deleteData()
//                            }
//                        } label: {
//                            Text("Delete")
//                        }
//                    }
//
//                    Section(header: Text("Message")) {
//                        TextField("Your message", text: $messageText)
//                        Button {
//                            Task {
//                                await self.sendMessage()
//                            }
//                        } label: {
//                            Text("Send")
//                        }
//                    }
//                        Section(header: Text("Console")
//                                    .background(colorScheme == .dark ? Color.black : Color(uiColor: .secondarySystemBackground))) {
//                            AutoSizingTextView(text: self.$console, height: self.$messageHeight, placeholder: self.$placeholder)
//                                .frame(width: geometry.size.width - 80, height: self.messageHeight < 350 ? self.messageHeight : 350)
//                                .font(.body)
//                                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
//                                .background(colorScheme == .dark ? Color.black : Color.white)
//                                .background(colorScheme == .dark ? Color.black : Color.white)
//                                .listRowBackground(colorScheme == .dark ? Color.black : Color(uiColor: .secondarySystemBackground))
//                        }
//                        .background(Color.black)
//                    } else {
//                        NavigationLink(destination: Console(topicName: self.$topicName, expiry: self.$expiry)) {
//                            Text("Connect")
//                                .foregroundColor(.blue)
//                        }
//                    }
//                }
//                .background(colorScheme == .dark ? .black : Color(uiColor: .systemGray2))
//                .navigationTitle(title: "Application Event Distribution")
//            }
//            .valueChanged(value: self.aedService.consoleMessage) { newValue in
//                self.console += "\n\(newValue)"
//            }
//            .alert(isPresented:  self.$authenticationService.showErrorAlert, content: {
//                Alert(
//                    title: Text("\(self.authenticationService.errorMessage)"),
//                    message: Text(""),
//                    dismissButton: .cancel(Text("Okay"), action: {
//                        self.authenticationService.showErrorAlert = false
//                    })
//                )
//            })
//        }
//        .onTapGesture(count: 2) {
//            hideKeyboard()
//        }
//    }
//    
//    fileprivate func delete(at offsets: IndexSet) {
////            guard let item = offsets.last else {return}
//    }
//    
//    func disconnectOrDeleteTopic(_ topic: ACBTopic?, delete: Bool) async {
//        guard let topic = topic else {return}
//        if !topic.name.isEmpty {
//            if self.aedService.currentTopic == topic {
//                self.aedService.currentTopic = nil
//            }
//            
//            if topic.connected {
//                await topic.disconnect(withDeleteFlag: delete)
//                self.aedService.topicList.removeAll(where: { $0 == topic })
//                let msg = "Topic \(topic.name) disconnected."
//                await MainActor.run {
//                    self.aedService.consoleMessage = msg
//                }
//            } else {
//                let msg = "Topic \(self.aedService.currentTopic?.name ?? "") already disconnected."
//                await MainActor.run {
//                    self.aedService.consoleMessage = msg
//                }
//            }
//            
//            if self.aedService.currentTopic == nil && self.aedService.topicList.count > 0 {
//                self.aedService.currentTopic = topic
//                self.aedService.currentTopic = self.aedService.topicList.first
//            }
//        } else {
//            self.authenticationService.showErrorAlert = true
//            self.authenticationService.errorMessage = "Topic Name is empty"
//        }
//        
//    }
//    
//    @MainActor
//    func connectToTopic() async {
//        if !self.topicName.isEmpty{
//            let expiry = Int(self.expiry) ?? 0
//            self.aedService.currentTopic = self.authenticationService.uc?.aed.createTopic(withName: self.topicName, expiryTime: expiry, delegate: self.aedService)
//            self.topicName = ""
//            self.expiry = ""
//        } else {
//            self.authenticationService.showErrorAlert = true
//            self.authenticationService.errorMessage = "Please enter a Topic Name"
//        }
//    }
//    
//    @MainActor
//    func publishData() async {
//        if !self.key.isEmpty && !self.value.isEmpty {
//            await self.aedService.currentTopic?.submitData(withKey: self.key, value: self.value)
//            self.key = ""
//            self.value = ""
//        } else {
//            self.authenticationService.showErrorAlert = true
//            self.authenticationService.errorMessage = "Please enter a Key Value Pair"
//        }
//    }
//    
//    @MainActor
//    func deleteData() async {
//        if !self.key.isEmpty {
//            await self.aedService.currentTopic?.deleteData(withKey: self.key)
//            self.key = ""
//            self.value = ""
//        } else {
//            self.authenticationService.showErrorAlert = true
//            self.authenticationService.errorMessage = "Please enter a Key to delete"
//        }
//    }
//    
//    @MainActor
//    func sendMessage() async {
//        if !self.messageText.isEmpty{
//            await self.aedService.currentTopic?.sendAedMessage(self.messageText)
//            self.messageText = ""
//        } else {
//            self.authenticationService.showErrorAlert = true
//            self.authenticationService.errorMessage = "Please enter a Message"
//        }
//    }
//}
//
//struct AED_Previews: PreviewProvider {
//    static var previews: some View {
//        if #available(iOS 15.0, *) {
//            AED()
//        } else {
//            // Fallback on earlier versions
//        }
//    }
//}
//
import SwiftUI
import FCSDKiOS

/// A view that manages Application Event Distribution (AED) topics and messages.
struct AED: View {
    
    // State variables to manage user input and UI state
    @State private var topicName = ""
    @State private var expiry = ""
    @State private var key = ""
    @State private var value = ""
    @State private var messageText = ""
    @State private var console: String = ""
    
    // Environment objects for authentication and AED services
    @EnvironmentObject var authenticationService: AuthenticationService
    @EnvironmentObject var aedService: AEDService
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        GeometryReader { geometry in
            NavigationView {
                Form {
                    // Section for connected topics
                    connectedTopicsSection
                    
                    // Section for creating a new topic
                    createTopicSection
                    
                    // Section for data operations
                    dataOperationsSection
                    
                    // Section for sending messages
                    messageSection
                    
                    // Section for console output
                    consoleSection(geometry: geometry)
                }
                .navigationTitle(title: "Application Event Distribution")
                .background(colorScheme == .dark ? .black : Color(uiColor: .systemGray2))
                .alert(isPresented: $authenticationService.showErrorAlert) {
                    Alert(
                        title: Text(authenticationService.errorMessage),
                        dismissButton: .cancel(Text("Okay"), action: {
                            authenticationService.showErrorAlert = false
                        })
                    )
                }
            }
            .valueChanged(value: self.aedService.consoleMessage) { newValue in
                self.console += "\n\(newValue)"
            }
            .onTapGesture(count: 2) {
                hideKeyboard()
            }
        }
    }
    
    // MARK: - UI Sections
    
    /// Section displaying connected topics.
    private var connectedTopicsSection: some View {
        Section(header: Text("Connected Topics").foregroundColor(colorScheme == .dark ? .gray : .black)) {
            List {
                ForEach(aedService.topicList, id: \.self) { topic in
                    AEDTopic(topic: topic, console: $console)
                        .onTapGesture {
                            // Handle topic selection if needed
                        }
                        .contextMenu {
                            Button("Delete") {
                                Task {
                                    await disconnectOrDeleteTopic(topic, delete: true)
                                }
                            }
                            Button("Disconnect") {
                                Task {
                                    await disconnectOrDeleteTopic(topic, delete: false)
                                }
                            }
                        }
                }
            }
        }
    }
    
    /// Section for creating a new topic.
    private var createTopicSection: some View {
        Section(header: Text("Topic").foregroundColor(colorScheme == .dark ? .gray : .black)) {
            TextField("Topic Name", text: $topicName)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            TextField("Expiry", text: $expiry)
                .keyboardType(.numberPad)
                .foregroundColor(colorScheme == .dark ? .white : .black)
            Button("Connect") {
                Task {
                    await connectToTopic() // Call the async function here
                }
            }
            .buttonStyle(DefaultButtonStyle())
        }
    }
    
    /// Section for data operations (publish and delete).
    private var dataOperationsSection: some View {
        Section(header: Text("Data")) {
            TextField("Key", text: $key)
            TextField("Value", text: $value)
            Button("Publish") {
                Task {
                    await publishData()
                }
            }
            Button("Delete") {
                Task {
                    await deleteData()
                }
            }
        }
    }
    
    /// Section for sending messages.
    private var messageSection: some View {
        Section(header: Text("Message")) {
            TextField("Your message", text: $messageText)
            Button("Send") {
                Task {
                    await sendMessage()
                }
            }
        }
    }
    
    /// Section for displaying console output.
    private func consoleSection(geometry: GeometryProxy) -> some View {
        Section(header: Text("Console").background(colorScheme == .dark ? Color.black : Color(uiColor: .secondarySystemBackground))) {
            AutoSizingTextView(text: $console, height: .constant(0), placeholder: .constant(""))
                .frame(width: geometry.size.width - 80, height: 350)
                .font(.body)
                .foregroundColor(colorScheme == .dark ? Color.white : Color.black)
                .background(colorScheme == .dark ? Color.black : Color.white)
                .listRowBackground(colorScheme == .dark ? Color.black : Color(uiColor: .secondarySystemBackground))
                .padding(10)
        }
    }
    
    // MARK: - Topic Management Functions
    
    /// Disconnects or deletes a topic based on the provided flag.
    func disconnectOrDeleteTopic(_ topic: ACBTopic?, delete: Bool) async {
        guard let topic = topic else { return }
        
        if !topic.name.isEmpty {
            if aedService.currentTopic == topic {
                aedService.currentTopic = nil
            }
            
            if topic.connected {
                await topic.disconnect(withDeleteFlag: delete)
                aedService.topicList.removeAll(where: { $0 == topic })
                let msg = "Topic \(topic.name) disconnected."
                await MainActor.run {
                    aedService.consoleMessage = msg
                }
            } else {
                let msg = "Topic \(aedService.currentTopic?.name ?? "") already disconnected."
                await MainActor.run {
                    aedService.consoleMessage = msg
                }
            }
            
            if aedService.currentTopic == nil && !aedService.topicList.isEmpty {
                aedService.currentTopic = aedService.topicList.first
            }
        } else {
            authenticationService.showErrorAlert = true
            authenticationService.errorMessage = "Topic Name is empty"
        }
    }
    
    /// Connects to a topic with the specified name and expiry.
    @MainActor
    func connectToTopic() async {
        guard !topicName.isEmpty else {
            authenticationService.showErrorAlert = true
            authenticationService.errorMessage = "Please enter a Topic Name"
            return
        }
        
        let expiry = Int(expiry) ?? 0
        aedService.currentTopic = authenticationService.uc?.aed.createTopic(withName: topicName, expiryTime: expiry, delegate: aedService)
        topicName = ""
        self.expiry = ""
    }
    
    /// Publishes data to the current topic.
    @MainActor
    func publishData() async {
        guard !key.isEmpty, !value.isEmpty else {
            authenticationService.showErrorAlert = true
            authenticationService.errorMessage = "Please enter a Key Value Pair"
            return
        }
        
        await aedService.currentTopic?.submitData(withKey: key, value: value)
        key = ""
        value = ""
    }
    
    /// Deletes data from the current topic based on the provided key.
    @MainActor
    func deleteData() async {
        guard !key.isEmpty else {
            authenticationService.showErrorAlert = true
            authenticationService.errorMessage = "Please enter a Key to delete"
            return
        }
        
        await aedService.currentTopic?.deleteData(withKey: key)
        key = ""
        value = ""
    }
    
    /// Sends a message to the current topic.
    @MainActor
    func sendMessage() async {
        guard !messageText.isEmpty else {
            authenticationService.showErrorAlert = true
            authenticationService.errorMessage = "Please enter a Message"
            return
        }
        
        await aedService.currentTopic?.sendAedMessage(messageText)
        messageText = ""
    }
}

// MARK: - Previews

struct AED_Previews: PreviewProvider {
    static var previews: some View {
        AED()
            .environmentObject(AuthenticationService())
            .environmentObject(AEDService())
    }
}
