//
//  NetworkMonitor.swift
//  CBAFusion
//
//  Created by Cole M on 9/1/21.
//

import Foundation
import Network
import AVFoundation
import Logging
import Combine

class NetworkMonitor: ObservableObject {
    
    let monitor: NWPathMonitor
    var logger: Logger
    var stateCancellable: Cancellable?
    let pathState = NWPathState()
    
    init(type: RequiredInterfaceType) {
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - Network Monitor - ")
        switch type {
        case .cell:
            self.monitor = NWPathMonitor(requiredInterfaceType: .cellular)
        case .wired:
            self.monitor = NWPathMonitor(requiredInterfaceType: .wiredEthernet)
        case .wireless:
            self.monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        case .all:
            self.monitor = NWPathMonitor()
        }
        
        
        stateCancellable = pathState.publisher(for: \.pathStatus) as? Cancellable
        monitor.pathUpdateHandler = { [weak self] state in
            guard let strongSelf = self else {return}
            strongSelf.pathState.pathStatus = state.status
        }
        
        Task {
//        for await status in pathState.$pathStatus.values {
//            switch status {
//            case .satisfied:
//                logger.trace("We're connected!")
//            case .unsatisfied:
//                logger.trace("No connection. \(status)")
//            case .requiresConnection:
//                logger.trace("Connection Needed")
//            @unknown default:
//                break
//            }
//            guard status != .unsatisfied, status != .requiresConnection else { break }
//        }
        }
        let queue = DispatchQueue(label: "NWPathMonitor")
        monitor.start(queue: queue)
    }
    
    deinit {
        stateCancellable = nil
    }
    
    func networkStatus() -> Bool {
        if monitor.currentPath.status == .satisfied {
            return true
        } else {
            return false
        }
    }
    
}
enum RequiredInterfaceType {
    case cell
    case wired
    case wireless
    case all
}


class NWPathState: NSObject, ObservableObject {
    @Published public var pathStatus: NWPath.Status = .requiresConnection
}
