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
    var stateCancellable: Cancellable?
    let pathState = NWPathState()
    
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
        
        
        stateCancellable = pathState.publisher(for: \.pathStatus) as? Cancellable
        monitor.pathUpdateHandler = { [weak self] state in
            guard let self else { return }
            switch state.status {
            case .requiresConnection:
                print("Requires Connection")
            case .satisfied:
                print("Network satisfied")
            case .unsatisfied:
                print("Network unsatisfied")
            default:
                break
            }
            DispatchQueue.main.async {
                self.pathState.pathStatus = state.status
                self.pathState.pathType = self.checkInterfaceType(state)
            }
        }
        let queue = DispatchQueue(label: "NWPathMonitor")
        monitor.start(queue: queue)
    }
    
    deinit {
        stateCancellable = nil
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
    
    
    func networkStatus() -> Bool {
        if monitor.currentPath.status == .satisfied {
            print("Connected")
            return true
        } else {
            print("Disconnected")
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
    @Published var pathType: NWInterface.InterfaceType?
}
