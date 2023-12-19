//
//  ContentView.swift
//  CBAFusion
//
//  Created by Cole M on 8/30/21.
//

import SwiftUI
import NIOTransportServices
import Network

struct ContentView: View {
    
    @EnvironmentObject private var authenticationService: AuthenticationService
    @EnvironmentObject private var fcsdkCallService: FCSDKCallService
    @EnvironmentObject private var contactService: ContactService
    @EnvironmentObject private var monitor: NetworkMonitor
    @Environment(\.colorScheme) var colorScheme
    @State var animateCommunication = false
    @State var animateAED = false
    @State private var tappedShowBackground = false
    @State var currentStatus: NWPath.Status?
    @State var currentType: NWInterface.InterfaceType?
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Spacer()
                VStack(spacing: 0) {
                    if self.authenticationService.sessionID != "" {
                        if self.authenticationService.currentTabIndex == 1 {
                            AED()
                        } else {
                            Contacts()
                        }
                    } else {
                        if self.animateCommunication {
                            Welcome(animateCommunication: self.$animateCommunication, animateAED: self.$animateAED)
                        } else {
                            Welcome(animateCommunication: self.$animateCommunication, animateAED: self.$animateAED)
                        }
                    }
                    Divider()
                    ZStack{
                        HStack {
                            ForEach(0..<3, id: \.self) { num in
                                HStack {
                                    Button(action: {
                                        if num == 0 {
                                            self.authenticationService.selectedParentIndex = num
                                            self.authenticationService.currentTabIndex = num
                                            self.animateCommunication = true
                                            self.animateAED = false
                                        } else if num == 1 {
                                            self.authenticationService.selectedParentIndex = num
                                            self.authenticationService.currentTabIndex = num
                                            self.animateCommunication = false
                                            self.animateAED = true
                                        } else if num == 2 {
                                            self.authenticationService.showSettingsSheet = true
                                        }
                                    }, label: {
                                        Spacer()
                                        if num == 0 {
                                            VStack {
                                                Image(systemName: "video.fill")
                                                    .foregroundColor(self.authenticationService.currentTabIndex == num ? .blue : colorScheme == .dark ? .white : .gray)
                                                    .font(.system(size: 30))
                                                    .frame(width: 30, height: 30, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                                                Text("Communication")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(self.authenticationService.currentTabIndex == num ? .blue : colorScheme == .dark ? .white : .gray)
                                            }
                                        } else if num == 1 {
                                            VStack {
                                                Image(systemName: "plus.message.fill")
                                                    .foregroundColor(self.authenticationService.currentTabIndex == num ? .blue : colorScheme == .dark ? .white : .gray)
                                                    .font(.system(size: 30))
                                                    .frame(width: 30, height: 30, alignment: .center)
                                                Text("AED")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(self.authenticationService.currentTabIndex == num ? .blue : colorScheme == .dark ? .white : .gray)
                                            }
                                        } else if num == 2 {
                                            VStack {
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(self.authenticationService.currentTabIndex == num ? .blue : colorScheme == .dark ? .white : .gray)
                                                    .font(.system(size: 30))
                                                    .frame(width: 30, height: 30, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                                                Text(self.authenticationService.sessionID != "" ? "Settings" : "Authenticate")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(self.authenticationService.currentTabIndex == num ? .blue : colorScheme == .dark ? .white : .gray)
                                            }
                                        }
                                        Spacer()
                                    })
                                }
                                .padding(.top, 12)
                                .padding(.bottom, 12)
                            }
                        }
                    }
                    .background(Color(uiColor: .systemGray6))
                    .padding(.bottom, proxy.safeAreaInsets.bottom)
                    .edgesIgnoringSafeArea(.all)
                    .sheet(isPresented: self.$authenticationService.showSettingsSheet, onDismiss:  {
                        if tappedShowBackground {
                            self.fcsdkCallService.showBackgroundSelectorSheet = true
                        }
                    }, content: {
                        if self.authenticationService.sessionID != "" {
                            SettingsSheet(tappedShowBackground: $tappedShowBackground)
                                .environmentObject(authenticationService)
                                .environmentObject(fcsdkCallService)
                                .environmentObject(contactService)
                        } else {
                            Authentication()
                                .environmentObject(authenticationService)
                                .environmentObject(monitor)
                                .environmentObject(contactService)
                        }
                    })
                    .fullScreenSheet(isPresented: self.$fcsdkCallService.showBackgroundSelectorSheet, onDismiss: {
                        self.fcsdkCallService.showBackgroundSelectorSheet = false
                        self.tappedShowBackground = false
                    }, content: {
                        if #available(iOS 15, *) {
                            BackgroundSelector()
                        }
                    })
                    .onAppear {
                        self.authenticationService.currentTabIndex = 0
                        self.authenticationService.selectedParentIndex = 0
                        let eventLoop = NIOTSEventLoopGroup().next()
                        Task {
                            let store = try await SQLiteStore.create(on: eventLoop)
                            contactService.delegate = store
                            try await contactService.fetchContacts()
                            // We want to make sure all calls are inactive on Appear
                                  for contact in self.contactService.contacts ?? [] {
                                      for call in contact.calls ?? [] {
                                          if call.activeCall == true {
                                              call.activeCall = false
                                              await self.contactService.editCall(fcsdkCall: call)
                                          }
                                      }
                                  }
                        }
                        if self.authenticationService.sessionID != "" {
                        } else {
                            self.animateCommunication = true
                            self.animateAED = false
                            self.authenticationService.showSettingsSheet = true
                        }
                    }
                }.edgesIgnoringSafeArea(.bottom)
            }.edgesIgnoringSafeArea(.all)
        }
        .onReceive(monitor.pathState.$pathStatus) { newStatus in
            if let newStatus = newStatus {
                if currentStatus != newStatus {
                    currentStatus = newStatus
                    switch newStatus {
                    case .requiresConnection:
                        break
                    case .satisfied:
                        break
                    case .unsatisfied:
                        break
                    default:
                        break
                    }
//                    authenticationService.acbuc?.setNetworkReachable(false)
                }
            }
        }
        .onReceive(monitor.pathState.$pathType) { type in
            if let type = type {
                if currentType != type {
                    currentType = type
                    Task {
                        switch type {
                        case .other:
                            break
                        case .wifi:
                            if monitor.networkStatus() {
                                await setReachability()
                            }
                        case .cellular:
                            if monitor.networkStatus() {
                                await setReachability()
                            }
                        case .wiredEthernet:
                            break
                        case .loopback:
                            break
                        @unknown default:
                            break
                        }
                    }
                }
            }
        }

    }
    func setReachability() async {
//        await authenticationService.acbuc?.setNetworkReachable(false)
//        await authenticationService.acbuc?.setNetworkReachable(true)
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}

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
