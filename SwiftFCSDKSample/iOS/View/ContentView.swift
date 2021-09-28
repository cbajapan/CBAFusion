//
//  ContentView.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/30/21.
//

import SwiftUI


extension AnyTransition {
    static var moveAndFade: AnyTransition {
        AnyTransition.slide
    }
}

struct ContentView: View {
    
    @EnvironmentObject private var authenticationService: AuthenticationService
    @State var selectedParentIndex: Int = 0
    @State var showSubscriptionsSheet = false
    @State var currentTabIndex = 0
    @State var animateCommunication = false
    @State var animateAED = false
    
    var body: some View {
        GeometryReader { proxy in
            ZStack {
                Spacer()
                VStack(spacing: 0) {
                    if currentTabIndex == 0 {
                        if self.authenticationService.connectedToSocket {
                            Contacts()
                        } else {
                            if self.animateCommunication {
                                Welcome(animateCommunication: self.$animateCommunication, animateAED: self.$animateAED)
                                    .animation(.easeInOut(duration: 1), value: 1)
                                    .transition(.moveAndFade)
                            }
                        }
                    } else if currentTabIndex == 1 {
                        if self.authenticationService.connectedToSocket {
                            AED()
                        } else {
                            if self.animateAED {
                                Welcome(animateCommunication: self.$animateCommunication, animateAED: self.$animateAED)
                                    .animation(.easeInOut(duration: 1), value: 1)
                                    .transition(.moveAndFade)
                            }
                        }
                    } else {
                        EmptyView()
                    }
                    Divider()
                    ZStack{
                        HStack {
                            ForEach(0..<3, id: \.self) { num in
                                HStack {
                                    Button(action: {
                                        if num == 0 {
                                            print("Num == \(num)")
                                            self.selectedParentIndex = num
                                            self.currentTabIndex = num
                                            self.animateCommunication = true
                                            self.animateAED = false
                                        } else if num == 1 {
                                            print("Num == \(num)")
                                            self.selectedParentIndex = num
                                            self.currentTabIndex = num
                                            self.animateCommunication = false
                                            self.animateAED = true
                                        } else if num == 2 {
                                            print("Num == \(num)")
                                            self.showSubscriptionsSheet.toggle()
                                        }
                                        print("currentTabIndex == \(currentTabIndex)")
                                    }, label: {
                                        Spacer()
                                        if num == 0 {
                                            VStack {
                                                Image(systemName: "video.fill")
                                                    .foregroundColor(currentTabIndex == num ? .blue : .white)
                                                    .font(.system(size: 30))
                                                    .frame(width: 30, height: 30, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                                                Text("Communication")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(currentTabIndex == num ? .blue : .white)
                                            }
                                        } else if num == 1 {
                                            VStack {
                                                Image(systemName: "plus.message.fill")
                                                    .foregroundColor(currentTabIndex == num ? .blue : .white)
                                                    .font(.system(size: 30))
                                                    .frame(width: 30, height: 30, alignment: .center)
                                                Text("AED")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(currentTabIndex == num ? .blue : .white)
                                            }
                                        } else if num == 2 {
                                            VStack {
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(currentTabIndex == num ? .blue : .white)
                                                    .font(.system(size: 30))
                                                    .frame(width: 30, height: 30, alignment: /*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                                                Text(self.self.authenticationService.connectedToSocket ? "Session" : "Authenticate")
                                                    .font(.system(size: 12))
                                                    .foregroundColor(currentTabIndex == num ? .blue : .white)
                                            }
                                        }
                                        Spacer()
                                    })
                                }
                            }
                        }
                    }
                    
                    .padding(.top, 12)
                    .padding(.bottom, 12)
                    .padding(.bottom, proxy.safeAreaInsets.bottom)
                    .edgesIgnoringSafeArea(.all)
                    .sheet(isPresented: self.$showSubscriptionsSheet) {
                        if self.self.authenticationService.connectedToSocket {
                            SettingsSheet(currentTabIndex: self.$currentTabIndex, showSubscriptionsSheet: self.$showSubscriptionsSheet, parentTabIndex: self.selectedParentIndex)
                        } else {
                            Authentication(currentTabIndex: self.$currentTabIndex, showSubscriptionsSheet: self.$showSubscriptionsSheet, parentTabIndex: self.selectedParentIndex)
                        }
                    }
                    .onAppear {
                        if !self.authenticationService.connectedToSocket {
                            self.currentTabIndex = 0
                            self.animateCommunication = true
                            self.animateAED = false
                            self.showSubscriptionsSheet.toggle()
                        }
                    }
                }.edgesIgnoringSafeArea(.bottom)
            }.edgesIgnoringSafeArea(.all)
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
