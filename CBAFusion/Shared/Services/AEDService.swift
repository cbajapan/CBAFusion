//
//  AEDService.swift
//  CBAFusion
//
//  Created by Ryan Walker on 11/21/21.
//

import Foundation
import FCSDKiOS
import Logging

@MainActor
final class AEDService: NSObject, ObservableObject, ACBTopicDelegate {
    
    // MARK: - Published Properties
    @Published var currentTopic: ACBTopic?
    @Published var topicList: [ACBTopic] = []
    @Published var consoleMessage: String = ""
    
    // MARK: - Properties
    var expiryClause: String = ""
    let logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - AEDService - ")
    
    // MARK: - ACBTopicDelegate Methods
    
    nonisolated func topic(_ topic: ACBTopic, didConnectWithData data: AedData) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.handleTopicConnection(topic: topic, data: data)
        }
        logTopicData(data.topicData)
    }
    
    nonisolated func topic(_ topic: ACBTopic, didDeleteWithMessage message: String) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.updateConsoleMessage("Deleted - \(message) for topic '\(topic.name)'.")
        }
    }
    
    nonisolated func topic(_ topic: ACBTopic, didSubmitWithKey key: String, value: String, version: Int) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.updateConsoleMessage("Data submitted - k:\(key) v:\(value) for topic '\(topic.name)'. Version: \(version)")
        }
    }
    
    nonisolated func topic(_ topic: ACBTopic, didDeleteDataSuccessfullyWithKey key: String, version: Int) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.updateConsoleMessage("Data deleted - k:\(key) for topic '\(topic.name)'. Version: \(version)")
        }
    }
    
    nonisolated func topic(_ topic: ACBTopic, didSendMessageSuccessfullyWithMessage message: String) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.updateConsoleMessage("Sent message - \(message) for topic '\(topic.name)'.")
        }
    }
    
    nonisolated func topic(_ topic: ACBTopic, didNotConnectWithMessage message: String) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.updateConsoleMessage("Connect Failed - \(message) for topic '\(topic.name)'.")
        }
    }
    
    nonisolated func topic(_ topic: ACBTopic, didNotDeleteWithMessage message: String) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.updateConsoleMessage("Delete Failed - \(message) for topic '\(topic.name)'.")
        }
    }
    
    nonisolated func topic(_ topic: ACBTopic, didNotSubmitWithKey key: String, value: String, message: String) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.updateConsoleMessage("Publish Data Failed - \(message) for topic '\(topic.name)'.")
        }
    }
    
    nonisolated func topic(_ topic: ACBTopic, didNotDeleteDataWithKey key: String, message: String) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.updateConsoleMessage("Delete Data Failed - \(message) for topic '\(topic.name)'.")
        }
    }
    
    nonisolated func topic(_ topic: ACBTopic, didNotSendMessage originalMessage: String, message: String) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.updateConsoleMessage("Send Message Failed - \(message) for topic '\(topic.name)'.")
        }
    }
    
    nonisolated func topicDidDelete(_ topic: ACBTopic) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.consoleMessage = "Topic '\(topic.name)' has been deleted."
            self.topicList.removeAll { $0 == topic }
        }
    }
    
    nonisolated func topic(_ topic: ACBTopic, didUpdateWithKey key: String, value: String, version: Int, deleted: Bool) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.updateConsoleMessage("Topic '\(topic.name)' updated - k:\(key) v:\(value). Version: \(version)")
        }
    }
    
    nonisolated func topic(_ topic: ACBTopic, didReceiveMessage message: String) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.updateConsoleMessage("Received Message - \(message) for topic '\(topic.name)'.")
        }
    }
    
    // MARK: - Private Methods
    
    private func handleTopicConnection(topic: ACBTopic, data: AedData) {
        topicList.append(topic)
        currentTopic = topic
        
        let topicExpiry = data.timeout ?? 0
        expiryClause = topicExpiry > 0 ? "expires in \(topicExpiry) mins" : "no expiry"
        
        let name = topic.name
        consoleMessage = "Topic '\(name)' connected successfully (\(expiryClause))."
        consoleMessage += "\nCurrent topic is '\(name)'. Topic Data:"
    }
    
    nonisolated private func logTopicData(_ topicData: [TopicData]?) {
        guard let topicData = topicData else { return }
        for data in topicData {
            logger.info("Key: '\(data.key ?? "nil")' Value: '\(data.value ?? "nil")'")
        }
    }
    
    private func updateConsoleMessage(_ message: String) {
        consoleMessage = message
    }
}
