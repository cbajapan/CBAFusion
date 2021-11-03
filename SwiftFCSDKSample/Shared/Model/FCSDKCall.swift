//
//  FCSDKCall.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/22/21.
//

import Foundation
import FCSDKiOS

final class FCSDKCall: NSObject {

    var handle: String
    var hasVideo: Bool
    var previewView: SamplePreviewVideoCallView? = nil
    var remoteView: SampleBufferVideoCallView? = nil
    var uuid: UUID
    var acbuc: ACBUC? = nil
    var call: ACBClientCall? = nil
    
    
    init(
        handle: String,
        hasVideo: Bool,
        previewView: SamplePreviewVideoCallView? = nil,
        remoteView: SampleBufferVideoCallView? = nil,
        uuid: UUID,
        acbuc: ACBUC? = nil,
        call: ACBClientCall? = nil
    ) {
        self.handle = handle
        self.hasVideo = hasVideo
        self.previewView = previewView
        self.remoteView = remoteView
        self.uuid = uuid
        self.acbuc = acbuc
        self.call = call
    }
}
