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

actor NetworkMonitor {
    
    private var monitor: NWPathMonitor?
    private var continuation: AsyncStream<NWPath>.Continuation?
    
    func startMonitor(type: RequiredInterfaceType) -> AsyncStream<NWPath> {
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
        
        self.monitor = monitor
        let queue = DispatchQueue(label: "NWPathMonitor")
        
        let stream = AsyncStream<NWPath> { continuation in
            self.continuation = continuation
            monitor.pathUpdateHandler = { path in
                continuation.yield(path)
            }
        }
        
        monitor.start(queue: queue)
        return stream
    }
    
    func stopMonitor() {
        monitor?.cancel()
        continuation?.finish()
        monitor = nil
        continuation = nil
    }
    
    func checkInterfaceType(_ path: NWPath) -> NWInterface.InterfaceType {
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

@MainActor
class NWPathState: NSObject, ObservableObject {
    @Published var pathStatus: NWPath.Status?
    @Published var pathType: NWInterface.InterfaceType?
    
    private var networkMonitor: NetworkMonitor?
    private var monitorTask: Task<Void, Never>?
    
    func startMonitoring(type: RequiredInterfaceType) {
        networkMonitor = NetworkMonitor()
        monitorTask = Task {
            guard let stream = await networkMonitor?.startMonitor(type: type) else { return }
            
            for await path in stream {
                self.pathStatus = path.status
                self.pathType = await networkMonitor?.checkInterfaceType(path)
            }
        }
    }
    
    func stopMonitoring() {
        monitorTask?.cancel()
        Task {
            await networkMonitor?.stopMonitor()
        }
        networkMonitor = nil
        monitorTask = nil
    }
}
