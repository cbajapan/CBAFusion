//
//  FCSDKCallViewModel.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 10/18/21.
//

import Foundation
import FCSDKiOS

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
    var previewView: SamplePreviewVideoCallView? {
        return fcsdkCall.previewView
    }
    var remoteView: SampleBufferVideoCallView? {
        return fcsdkCall.remoteView
    }
    var uuid: UUID {
        return fcsdkCall.uuid
    }
    var acbuc: ACBUC? {
        return fcsdkCall.acbuc
    }
    
    var call: ACBClientCall? {
        return fcsdkCall.call
    }
}

