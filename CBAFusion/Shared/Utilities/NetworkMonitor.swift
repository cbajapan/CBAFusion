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
        
        
        monitor.pathUpdateHandler = { path in
            switch path.status {
            case .satisfied:
                self.logger.info("We're connected!")
            case .unsatisfied:
                if #available(iOS 14.2, *) {
                    self.logger.info("No connection. \(path.unsatisfiedReason)")
                } else {
                    self.logger.info("No connection.")
                }
            case .requiresConnection:
                self.logger.info("Connection Needed")
            @unknown default:
                break
            }
            self.logger.info("Available interface: - \(path.availableInterfaces)")
            self.logger.info("Path is Expensive - \(path.isExpensive)")
            self.logger.info("Gateways \(path.gateways)")
            self.logger.info("In low data mode \(path.isConstrained)")
            self.logger.info("Local Endpoint \(String(describing: path.localEndpoint))")
            self.logger.info("Remote Endpoint \(String(describing: path.remoteEndpoint))")
            self.logger.info("Supports DNS \(path.supportsDNS)")
            self.logger.info("Supports IPv4 \(path.supportsIPv4)")
            self.logger.info("Supports IPv6 \(path.supportsIPv6)")
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
