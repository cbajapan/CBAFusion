//
//  NetworkMonitor.swift
//  CBAFusion
//
//  Created by Cole M on 9/1/21.
//

import Foundation
import Network
import AVFoundation


class NetworkMonitor: ObservableObject {
    
    let monitor: NWPathMonitor
    
    init(type: RequiredInterfaceType) {
        
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
                print("We're connected!")
            case .unsatisfied:
                if #available(iOS 14.2, *) {
                    print("No connection. \(path.unsatisfiedReason)")
                } else {
                    print("No connection.")
                }
            case .requiresConnection:
                print("Connection Needed")
            @unknown default:
                break
            }
            print("Available interface: - ", path.availableInterfaces)
            print("Path is Expensive - ", path.isExpensive)
            print("Gateways", path.gateways)
            print("In low data mode", path.isConstrained)
            print("Local Endpoint", path.localEndpoint ?? "Local Endpoint not available")
            print("Remote Endpoint",path.remoteEndpoint ?? "Remote Endpoint not available")
            print("Supports DNS", path.supportsDNS)
            print("Supports IPv4", path.supportsIPv4)
            print("Supports IPv6", path.supportsIPv6)
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
