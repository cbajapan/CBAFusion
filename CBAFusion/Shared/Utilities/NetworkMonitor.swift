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

class NetworkMonitor: ObservableObject {
    
    let monitor: NWPathMonitor
    var logger: Logger
    
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
        
        
        monitor.pathUpdateHandler = { [weak self] path in
            guard let strongSelf = self else { return }
            switch path.status {
            case .satisfied:
                guard let strongSelf = self else { return }
                strongSelf.logger.info("We're connected!")
            case .unsatisfied:
                    guard let strongSelf = self else { return }
                    strongSelf.logger.info("No connection. \(path.unsatisfiedReason)")
            case .requiresConnection:
                guard let strongSelf = self else { return }
                strongSelf.logger.info("Connection Needed")
            @unknown default:
                break
            }
            strongSelf.logger.info("Available interface: - \(path.availableInterfaces)")
            strongSelf.logger.info("Path is Expensive - \(path.isExpensive)")
            strongSelf.logger.info("Gateways \(path.gateways)")
            strongSelf.logger.info("In low data mode \(path.isConstrained)")
            strongSelf.logger.info("Local Endpoint \(String(describing: path.localEndpoint))")
            strongSelf.logger.info("Remote Endpoint \(String(describing: path.remoteEndpoint))")
            strongSelf.logger.info("Supports DNS \(path.supportsDNS)")
            strongSelf.logger.info("Supports IPv4 \(path.supportsIPv4)")
            strongSelf.logger.info("Supports IPv6 \(path.supportsIPv6)")
        }
        
        let queue = DispatchQueue(label: "NWPathMonitor")
        monitor.start(queue: queue)
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
