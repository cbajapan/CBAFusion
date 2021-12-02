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
            }
                Divider()
                VStack(alignment: .leading) {
                    Text("Console").foregroundColor(.gray)
                        AutoSizingTextView(text: self.$console, height: self.$messageHeight, placeholder: self.$placeholder)
                            .frame(width: geometry.size.width - 60, height: self.messageHeight < 500 ? self.messageHeight : 275)
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
            self.aedService.consoleMessage = """
        v=0
        o=- 1853389483892641236 2 IN IP4 127.0.0.1
        s=-
        t=0 0
        a=group:BUNDLE 0 1 2
        a=extmap-allow-mixed
        a=msid-semantic: WMS
        m=audio 9 UDP/TLS/RTP/SAVPF 111 103 9 0 8 105 13 110 113 126
        c=IN IP4 0.0.0.0
        a=rtcp:9 IN IP4 0.0.0.0
        a=ice-ufrag:T8wI
        a=ice-pwd:74DOQaNlIFRqVPkrcNM6Ttth
        a=ice-options:trickle
        a=fingerprint:sha-256 DD:3F:20:AB:26:1F:21:CD:8D:C0:C9:41:F6:9A:0E:D5:EB:57:6A:96:97:AC:1F:C5:CB:E8:C9:D6:67:F1:00:B9
        a=setup:active
        a=mid:0
        a=extmap:1 urn:ietf:params:rtp-hdrext:ssrc-audio-level
        a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time
        a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01
        a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid
        a=extmap:5 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id
        a=extmap:6 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id
        a=recvonly
        a=rtcp-mux
        a=rtpmap:111 opus/48000/2
        a=rtcp-fb:111 transport-cc
        a=fmtp:111 minptime=10;useinbandfec=1
        a=rtpmap:103 ISAC/16000
        a=rtpmap:9 G722/8000
        a=rtpmap:0 PCMU/8000
        a=rtpmap:8 PCMA/8000
        a=rtpmap:105 CN/16000
        a=rtpmap:13 CN/8000
        a=rtpmap:110 telephone-event/48000
        a=rtpmap:113 telephone-event/16000
        a=rtpmap:126 telephone-event/8000
        m=video 9 UDP/TLS/RTP/SAVPF 96 97 98 99 100 101 102 125 104 124 106 107 108 109 127
        c=IN IP4 0.0.0.0
        a=rtcp:9 IN IP4 0.0.0.0
        a=ice-ufrag:T8wI
        a=ice-pwd:74DOQaNlIFRqVPkrcNM6Ttth
        a=ice-options:trickle
        a=fingerprint:sha-256 DD:3F:20:AB:26:1F:21:CD:8D:C0:C9:41:F6:9A:0E:D5:EB:57:6A:96:97:AC:1F:C5:CB:E8:C9:D6:67:F1:00:B9
        a=setup:active
        a=mid:1
        a=extmap:14 urn:ietf:params:rtp-hdrext:toffset
        a=extmap:2 http://www.webrtc.org/experiments/rtp-hdrext/abs-send-time
        a=extmap:13 urn:3gpp:video-orientation
        a=extmap:3 http://www.ietf.org/id/draft-holmer-rmcat-transport-wide-cc-extensions-01
        a=extmap:12 http://www.webrtc.org/experiments/rtp-hdrext/playout-delay
        a=extmap:11 http://www.webrtc.org/experiments/rtp-hdrext/video-content-type
        a=extmap:7 http://www.webrtc.org/experiments/rtp-hdrext/video-timing
        a=extmap:8 http://www.webrtc.org/experiments/rtp-hdrext/color-space
        a=extmap:4 urn:ietf:params:rtp-hdrext:sdes:mid
        a=extmap:5 urn:ietf:params:rtp-hdrext:sdes:rtp-stream-id
        a=extmap:6 urn:ietf:params:rtp-hdrext:sdes:repaired-rtp-stream-id
        a=recvonly
        a=rtcp-mux
        a=rtcp-rsize
        a=rtpmap:96 H264/90000
        a=rtcp-fb:96 goog-remb
        a=rtcp-fb:96 transport-cc
        a=rtcp-fb:96 ccm fir
        a=rtcp-fb:96 nack
        a=rtcp-fb:96 nack pli
        a=fmtp:96 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=640c1f
        a=rtpmap:97 rtx/90000
        a=fmtp:97 apt=96
        a=rtpmap:98 H264/90000
        a=rtcp-fb:98 goog-remb
        a=rtcp-fb:98 transport-cc
        a=rtcp-fb:98 ccm fir
        a=rtcp-fb:98 nack
        a=rtcp-fb:98 nack pli
        a=fmtp:98 level-asymmetry-allowed=1;packetization-mode=1;profile-level-id=42e01f
        a=rtpmap:99 rtx/90000
        a=fmtp:99 apt=98
        a=rtpmap:100 H264/90000
        a=rtcp-fb:100 goog-remb
        a=rtcp-fb:100 transport-cc
        a=rtcp-fb:100 ccm fir
        a=rtcp-fb:100 nack
        a=rtcp-fb:100 nack pli
        a=fmtp:100 level-asymmetry-allowed=1;packetization-mode=0;profile-level-id=640c1f
        a=rtpmap:101 rtx/90000
        a=fmtp:101 apt=100
        a=rtpmap:102 H264/90000
        a=rtcp-fb:102 goog-remb
        a=rtcp-fb:102 transport-cc
        a=rtcp-fb:102 ccm fir
        a=rtcp-fb:102 nack
        a=rtcp-fb:102 nack pli
        a=fmtp:102 level-asymmetry-allowed=1;packetization-mode=0;profile-level-id=42e01f
        a=rtpmap:125 rtx/90000
        a=fmtp:125 apt=102
        a=rtpmap:104 VP8/90000
        a=rtcp-fb:104 goog-remb
        a=rtcp-fb:104 transport-cc
        a=rtcp-fb:104 ccm fir
        a=rtcp-fb:104 nack
        a=rtcp-fb:104 nack pli
        a=rtpmap:124 rtx/90000
        a=fmtp:124 apt=104
        a=rtpmap:106 VP9/90000
        a=rtcp-fb:106 goog-remb
        a=rtcp-fb:106 transport-cc
        a=rtcp-fb:106 ccm fir
        a=rtcp-fb:106 nack
        a=rtcp-fb:106 nack pli
        a=fmtp:106 profile-id=0
        a=rtpmap:107 rtx/90000
        a=fmtp:107 apt=106
        a=rtpmap:108 red/90000
        a=rtpmap:109 rtx/90000
        a=fmtp:109 apt=108
        a=rtpmap:127 ulpfec/90000
        m=application 9 UDP/DTLS/SCTP webrtc-datachannel
        c=IN IP4 0.0.0.0
        a=ice-ufrag:T8wI
        a=ice-pwd:74DOQaNlIFRqVPkrcNM6Ttth
        a=ice-options:trickle
        a=fingerprint:sha-256 DD:3F:20:AB:26:1F:21:CD:8D:C0:C9:41:F6:9A:0E:D5:EB:57:6A:96:97:AC:1F:C5:CB:E8:C9:D6:67:F1:00:B9
        a=setup:active
        a=mid:2
        a=sctp-port:5000
        a=max-message-size:262144
"""
        }
        .onChange(of: self.aedService.consoleMessage) { newValue in
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
