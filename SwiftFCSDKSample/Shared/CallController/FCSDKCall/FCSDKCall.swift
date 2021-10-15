//
//  FCSDKCall.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/22/21.
//

import Foundation
import SwiftFCSDK

final class FCSDKCall: NSObject {

    var handle: String
    var hasVideo: Bool
//    var previewView: SamplePreviewVideoCallView
    var previewView: ACBView
    var remoteView: ACBView
//    var remoteView: SampleBufferVideoCallView
    var uuid: UUID
    var acbuc: ACBUC
    var call: ACBClientCall? = nil
    
    
    init(
        handle: String,
        hasVideo: Bool,
//        previewView: SamplePreviewVideoCallView,
        previewView: ACBView,
        remoteView: ACBView,
//        remoteView: SampleBufferVideoCallView,
        uuid: UUID,
        acbuc: ACBUC,
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


class FCSDKCallViewModel {
    
    var fcsdkCall: FCSDKCall
    
    init(fcsdkCall: FCSDKCall) {
        self.fcsdkCall = fcsdkCall
    }
    var handle: String {
        return fcsdkCall.handle
    }
    var hasVideo: Bool {
        return fcsdkCall.hasVideo
    }
//    var previewView: SamplePreviewVideoCallView {
//        return fcsdkCall.previewView
//    }
//    var remoteView: SampleBufferVideoCallView {
//        return fcsdkCall.remoteView
//    }
    var previewView: ACBView {
        return fcsdkCall.previewView
    }
    var remoteView: ACBView {
        return fcsdkCall.remoteView
    }
    var uuid: UUID {
        return fcsdkCall.uuid
    }
    var acbuc: ACBUC {
        return fcsdkCall.acbuc
    }
    
    var call: ACBClientCall? {
        return fcsdkCall.call
    }
}

