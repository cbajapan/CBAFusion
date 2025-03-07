////
////  ContentView.swift
////  CBAFusion
////
////  Created by Cole M on 8/30/21.
////
//
//import SwiftUI
//import Network
//
//struct ContentView: View {
//    
//    @EnvironmentObject private var authenticationService: AuthenticationService
//    @EnvironmentObject private var fcsdkCallService: FCSDKCallService
//    @EnvironmentObject private var contactService: ContactService
//    @EnvironmentObject private var pathState: NWPathState
//    @Environment(\.colorScheme) var colorScheme
//    @State var animateCommunication = false
//    @State var animateAED = false
//    @State private var tappedShowBackground = false
//    @State var currentStatus: NWPath.Status?
//    @State var currentType: NWInterface.InterfaceType?
//    
//    var body: some View {
//        GeometryReader { proxy in
//            ZStack {
//                Spacer()
//                VStack(spacing: 0) {
//                    if self.authenticationService.sessionID != "" {
//                        if self.authenticationService.currentTabIndex == 1 {
//                            AED()
//                        } else {
//                            Contacts()
//                        }
//                    } else {
//                        if self.animateCommunication {
//                            Welcome(animateCommunication: self.$animateCommunication, animateAED: self.$animateAED)
//                        } else {
//                            Welcome(animateCommunication: self.$animateCommunication, animateAED: self.$animateAED)
//                        }
//                    }
//                    Divider()
//                    ZStack{
//                        HStack {
//                            ForEach(0..<3, id: \.self) { num in
//                                HStack {
//                                    Button(action: {
//                                        if num == 0 {
//                                            self.authenticationService.selectedParentIndex = num
//                                            self.authenticationService.currentTabIndex = num
//                                            self.animateCommunication = true
//                                            self.animateAED = false
//                                        } else if num == 1 {
//                                            self.authenticationService.selectedParentIndex = num
//                                            self.authenticationService.currentTabIndex = num
//                                            self.animateCommunication = false
//                                            self.animateAED = true
//                                        } else if num == 2 {
//                                            self.authenticationService.showSettingsSheet = true
//                                        }
//                                    }, label: {
//                                        Spacer()
//                                        if num == 0 {
//                                            VStack {
//                                                Image(systemName: "video.fill")
//                                                    .foregroundColor(self.authenticationService.currentTabIndex == num ? .blue : colorScheme == .dark ? .white : .gray)
//                                                    .font(.system(size: 30))
//                                                    .frame(width: 30, height: 30, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
//                                                Text("Communication")
//                                                    .font(.system(size: 12))
//                                                    .foregroundColor(self.authenticationService.currentTabIndex == num ? .blue : colorScheme == .dark ? .white : .gray)
//                                            }
//                                        } else if num == 1 {
//                                            VStack {
//                                                Image(systemName: "plus.message.fill")
//                                                    .foregroundColor(self.authenticationService.currentTabIndex == num ? .blue : colorScheme == .dark ? .white : .gray)
//                                                    .font(.system(size: 30))
//                                                    .frame(width: 30, height: 30, alignment: .center)
//                                                Text("AED")
//                                                    .font(.system(size: 12))
//                                                    .foregroundColor(self.authenticationService.currentTabIndex == num ? .blue : colorScheme == .dark ? .white : .gray)
//                                            }
//                                        } else if num == 2 {
//                                            VStack {
//                                                Image(systemName: "person.fill")
//                                                    .foregroundColor(self.authenticationService.currentTabIndex == num ? .blue : colorScheme == .dark ? .white : .gray)
//                                                    .font(.system(size: 30))
//                                                    .frame(width: 30, height: 30, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
//                                                Text(self.authenticationService.sessionID != "" ? "Settings" : "Authenticate")
//                                                    .font(.system(size: 12))
//                                                    .foregroundColor(self.authenticationService.currentTabIndex == num ? .blue : colorScheme == .dark ? .white : .gray)
//                                            }
//                                        }
//                                        Spacer()
//                                    })
//                                }
//                                .padding(.top, 12)
//                                .padding(.bottom, 12)
//                            }
//                        }
//                    }
//                    .background(Color(uiColor: .systemGray6))
//                    .padding(.bottom, proxy.safeAreaInsets.bottom)
//                    .edgesIgnoringSafeArea(.all)
//                    .sheet(isPresented: self.$authenticationService.showSettingsSheet, onDismiss:  {
//                        if tappedShowBackground {
//                            self.fcsdkCallService.showBackgroundSelectorSheet = true
//                        }
//                    }, content: {
//                        if self.authenticationService.sessionID != "" {
//                            SettingsSheet(tappedShowBackground: $tappedShowBackground)
//                                .environmentObject(authenticationService)
//                                .environmentObject(fcsdkCallService)
//                                .environmentObject(contactService)
//                        } else {
//                            Authentication()
//                                .environmentObject(authenticationService)
//                                .environmentObject(contactService)
//                        }
//                    })
//                    .fullScreenSheet(isPresented: self.$fcsdkCallService.showBackgroundSelectorSheet, onDismiss: {
//                        self.fcsdkCallService.showBackgroundSelectorSheet = false
//                        self.tappedShowBackground = false
//                    }, content: {
//                        if #available(iOS 15, *) {
//                            BackgroundSelector()
//                        }
//                    })
//                    .onAppear {
//                        self.authenticationService.currentTabIndex = 0
//                        self.authenticationService.selectedParentIndex = 0
//                        Task {
//                            let store = try await Task.detached {
//                                try await SQLiteStore.create()
//                            }.value
//                         
//                            setStore(store: store)
//                            try await contactService.fetchContacts()
//                            // We want to make sure all calls are inactive on Appear
//                                  for contact in self.contactService.contacts ?? [] {
//                                      for call in contact.calls {
//                                          var call = call
//                                          if call.activeCall == true {
//                                              call.activeCall = false
//                                              await self.contactService.editCall(fcsdkCall: call)
//                                          }
//                                      }
//                                  }
//                        }
//                        if self.authenticationService.sessionID != "" {
//                        } else {
//                            self.animateCommunication = true
//                            self.animateAED = false
//                            self.authenticationService.showSettingsSheet = true
//                        }
//                    }
//                }.edgesIgnoringSafeArea(.bottom)
//            }.edgesIgnoringSafeArea(.all)
//        }
//        .onReceive(pathState.$pathStatus) { newStatus in
//            if let newStatus = newStatus {
//                if currentStatus != newStatus {
//                    currentStatus = newStatus
//                    switch newStatus {
//                    case .requiresConnection:
//                        break
//                    case .satisfied:
//                        break
//                    case .unsatisfied:
//                        break
//                    default:
//                        break
//                    }
//                }
//            }
//        }
//        .onReceive(pathState.$pathType) { type in
//            if let type = type {
//                if currentType != type {
//                    currentType = type
//                    Task {
//                        switch type {
//                        case .other:
//                            break
//                        case .wifi:
//                            if pathState.pathStatus == .satisfied {
//                              break
//                            }
//                        case .cellular:
//                            if pathState.pathStatus == .satisfied {
//                                break
//                            }
//                        case .wiredEthernet:
//                            break
//                        case .loopback:
//                            break
//                        @unknown default:
//                            break
//                        }
//                    }
//                }
//            }
//        }
//
//    }
//    
//    @MainActor
//    func setStore(store: SQLiteStore) {
//        contactService.delegate = store
//    }
//}
//
//struct ContentView_Previews: PreviewProvider {
//    static var previews: some View {
//        ContentView()
//    }
//}
//
//extension UIColor {
//    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
//        var red: CGFloat = 0
//        var green: CGFloat = 0
//        var blue: CGFloat = 0
//        var alpha: CGFloat = 0
//        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
//
//        return (red, green, blue, alpha)
//    }
//}
//
//extension Color {
//    init(uiColor: UIColor) {
//        self.init(red: Double(uiColor.rgba.red),
//                  green: Double(uiColor.rgba.green),
//                  blue: Double(uiColor.rgba.blue),
//                  opacity: Double(uiColor.rgba.alpha))
//    }
//}

import SwiftUI
import Network

/// The main content view of the application, managing the display of different screens based on authentication state.
struct ContentView: View {
    
    // Environment objects for managing application state
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var fcsdkCallService: FCSDKCallService
    @EnvironmentObject private var contactService: ContactService
    @EnvironmentObject private var pathState: NWPathState
    @Environment(\.colorScheme) var colorScheme
    
    // State variables for managing animations and UI state
    @State private var animateCommunication = false
    @State private var animateAED = false
    @State private var tappedShowBackground = false
    @State private var currentStatus: NWPath.Status?
    @State private var currentType: NWInterface.InterfaceType?
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Spacer()
                VStack(spacing: 0) {
                    // Display different views based on authentication state
                    if !authenticationService.sessionID.isEmpty {
                        if authenticationService.currentTabIndex == TabIndex.aed.rawValue {
                            AED()
                        } else {
                            Contacts()
                        }
                    } else {
                        Welcome(animateCommunication: $animateCommunication, animateAED: $animateAED)
                    }
                    
                    Spacer()
                    Divider()
                    // Tab bar for navigation
                    tabBar(safeAreaBottom: proxy.safeAreaInsets.bottom)
                        .edgesIgnoringSafeArea(.bottom)
                    // Settings and authentication sheets
                        .sheet(isPresented: $authenticationService.showSettingsSheet, onDismiss: {
                            if tappedShowBackground {
                                fcsdkCallService.showBackgroundSelectorSheet = true
                            }
                        }) {
                            if !authenticationService.sessionID.isEmpty {
                                SettingsSheet(tappedShowBackground: $tappedShowBackground)
                                    .environmentObject(authenticationService)
                                    .environmentObject(fcsdkCallService)
                                    .environmentObject(contactService)
                            } else {
                                Authentication()
                                    .environmentObject(authenticationService)
                                    .environmentObject(contactService)
                            }
                        }
                        .fullScreenSheet(isPresented: $fcsdkCallService.showBackgroundSelectorSheet, onDismiss: {
                            fcsdkCallService.showBackgroundSelectorSheet = false
                            tappedShowBackground = false
                        }) {
                            if #available(iOS 15, *) {
                                BackgroundSelector()
                            }
                        }
                }
                .edgesIgnoringSafeArea(.bottom)
            }
            .edgesIgnoringSafeArea(.all)
        }
        .onAppear {
            setupInitialState()
        }
        .onReceive(pathState.$pathStatus) { newStatus in
            handlePathStatusChange(newStatus)
        }
        .onReceive(pathState.$pathType) { type in
            handlePathTypeChange(type)
        }
    }
    
    /// Sets up the initial state of the view when it appears.
    private func setupInitialState() {
        authenticationService.currentTabIndex = TabIndex.communication.rawValue
        authenticationService.selectedParentIndex = 0
        
        Task {
            do {
                let store = try await SQLiteStore.create()
                setStore(store: store)
                try await contactService.fetchContacts()
                resetActiveCalls()
            } catch {
                // Handle error appropriately (e.g., show an alert)
                print("Error setting up initial state: \(error)")
            }
        }
        
        if authenticationService.sessionID.isEmpty {
            animateCommunication = true
            animateAED = false
            authenticationService.showSettingsSheet = true
        }
    }
    
    /// Resets active calls for all contacts.
    private func resetActiveCalls() {
        guard let contacts = contactService.contacts else { return }
        
        for contact in contacts {
            for var call in contact.calls where call.activeCall == true {
                call.activeCall = false
                Task {
                    await contactService.editCall(fcsdkCall: call)
                }
            }
        }
    }
    
    /// Handles changes in the network path status.
    private func handlePathStatusChange(_ newStatus: NWPath.Status?) {
        guard let newStatus = newStatus, currentStatus != newStatus else { return }
        currentStatus = newStatus
        // Handle specific status cases if needed
    }
    
    /// Handles changes in the network path type.
    private func handlePathTypeChange(_ type: NWInterface.InterfaceType?) {
        guard let type = type, currentType != type else { return }
        currentType = type
        // Handle specific type cases if needed
    }
    
    @ViewBuilder
    private func tabBar(safeAreaBottom: CGFloat) -> some View {
        HStack {
            ForEach(TabIndex.allCases, id: \.self) { tab in
                tabButton(for: tab)
                    .frame(maxWidth: .infinity) // Ensure each button takes equal space
            }
        }
        .background(Color(uiColor: .systemGray6))
        .padding(.bottom, safeAreaBottom) // Use the passed safe area inset
        .frame(height: 80) // Set a fixed height for the tab bar
    }
    
    
    /// Creates a button for the tab bar.
    @ViewBuilder
    private func tabButton(for tab: TabIndex) -> some View {
        Button(action: {
            handleTabSelection(tab.rawValue)
        }) {
            VStack {
                let isSelected = authenticationService.currentTabIndex == tab.rawValue
                let (iconName, title) = createButtonStrings(for: tab)
                
                // Ensure that the Image and Text are always returned
                Image(systemName: iconName)
                    .resizable() // Make the image resizable
                    .scaledToFit() // Maintain aspect ratio
                    .foregroundColor(isSelected ? .blue : colorScheme == .dark ? .white : .gray)
                    .frame(width: 30, height: 30)
                
                Text(title)
                    .font(.system(size: 12))
                    .foregroundColor(isSelected ? .blue : colorScheme == .dark ? .white : .gray)
            }
            .padding(.top, 12)
            .padding(.bottom, 12)
        }
    }

    /// Creates button strings for the tab bar based on the selected tab.
    /// - Parameter tab: The selected tab index.
    /// - Returns: A tuple containing the icon name and title for the tab.
    private func createButtonStrings(for tab: TabIndex) -> (String, String) {
        let iconName: String
        let title: String
        switch tab {
        case .communication:
            iconName = "video.fill"
            title = "Communication"
        case .aed:
            iconName = "plus.message.fill"
            title = "AED"
        case .settings:
            iconName = "person.fill"
            title = authenticationService.sessionID.isEmpty ? "Authenticate" : "Settings"
        }
        return (iconName, title)
    }
    
    /// Handles tab selection actions.
    /// - Parameter index: The index of the selected tab.
    private func handleTabSelection(_ index: Int) {
        authenticationService.selectedParentIndex = index
        authenticationService.currentTabIndex = index
        
        animateCommunication = index == TabIndex.communication.rawValue
        animateAED = index == TabIndex.aed.rawValue
        
        if index == TabIndex.settings.rawValue {
            authenticationService.showSettingsSheet = true
        }
    }
    
    /// Sets the SQLite store for the contact service.
    /// - Parameter store: The SQLite store to be set.
    @MainActor
    private func setStore(store: SQLiteStore) {
        contactService.delegate = store
    }
}

/// Enumeration for tab indices.
enum TabIndex: Int, CaseIterable {
    case communication = 0
    case aed = 1
    case settings = 2
}

/// Preview provider for ContentView.
struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(AuthenticationService())
            .environmentObject(FCSDKCallService())
            .environmentObject(ContactService())
            .environmentObject(NWPathState())
    }
}

// Extensions for UIColor and Color to facilitate color conversion
extension UIColor {
    var rgba: (red: CGFloat, green: CGFloat, blue: CGFloat, alpha: CGFloat) {
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return (red, green, blue, alpha)
    }
}

extension Color {
    init(uiColor: UIColor) {
        self.init(red: Double(uiColor.rgba.red),
                  green: Double(uiColor.rgba.green),
                  blue: Double(uiColor.rgba.blue),
                  opacity: Double(uiColor.rgba.alpha))
    }
}
