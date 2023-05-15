//
//  NetworkMonitor.swift
//  CBAFusion
//
//  Created by Cole M on 9/1/21.
//

import Foundation
import Network
import AVFoundation
import OSLog
import Combine

class NetworkMonitor: ObservableObject {
    
    let monitor: NWPathMonitor
    var logger: Logger
    var stateCancellable: Cancellable?
    let pathState = NWPathState()
    
    init(type: RequiredInterfaceType) {
        self.logger = Logger(subsystem: "\(Constants.BUNDLE_IDENTIFIER)", category: "Network Monitor")
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
            guard let strongSelf = self else { return }
            switch state.status {
            case .requiresConnection:
                strongSelf.logger.trace("Requires Connection")
            case .satisfied:
                strongSelf.logger.trace("Connection satisfied")
            case .unsatisfied:
                strongSelf.logger.trace("Connection unsatisfied")
            default:
                break
            }
            strongSelf.pathState.pathStatus = state.status
        }
        let queue = DispatchQueue(label: "NWPathMonitor")
        monitor.start(queue: queue)
    }
    
    deinit {
        stateCancellable = nil
    }
    
    func networkStatus() -> Bool {
        if monitor.currentPath.status == .satisfied {
            logger.info("Connected")
            return true
        } else {
            logger.info("Disconnected")
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
    @Published var pathStatus: NWPath.Status?
}
