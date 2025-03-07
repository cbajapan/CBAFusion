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

class NetworkMonitor: @unchecked Sendable {
    
    var pathState: NWPathState?
    
    func startMonitor(type: RequiredInterfaceType, pathState: NWPathState) {
        self.pathState = pathState
        var monitor: NWPathMonitor
        switch type {
        case .cell:
            monitor = NWPathMonitor(requiredInterfaceType: .cellular)
        case .wired:
            monitor = NWPathMonitor(requiredInterfaceType: .wiredEthernet)
        case .wireless:
            monitor = NWPathMonitor(requiredInterfaceType: .wifi)
        case .all:
            monitor = NWPathMonitor()
        }
        let queue = DispatchQueue(label: "NWPathMonitor")
        monitor.start(queue: queue)
        monitor.pathUpdateHandler = { state in
            DispatchQueue.main.async { [weak self] in
                guard let self else { return }
                self.pathState?.pathStatus = state.status
//                self.pathState?.pathType = self.checkInterfaceType(state)
            }
        }
    }
    
    private func checkInterfaceType(_ path: NWPath) -> NWInterface.InterfaceType {
        if path.usesInterfaceType(.wifi) {
            return .wifi
        } else if path.usesInterfaceType(.cellular) {
            return .cellular
        } else if path.usesInterfaceType(.loopback) {
            return .loopback
        } else if path.usesInterfaceType(.wiredEthernet) {
            return .wiredEthernet
        }
        return .other
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
    @Published var pathType: NWInterface.InterfaceType?
}
