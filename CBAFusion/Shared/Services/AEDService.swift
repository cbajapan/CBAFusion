//
//  AEDService.swift
//  CBAFusion
//
//  Created by Ryan Walker on 11/21/21.
//

import Foundation
import FCSDKiOS
import Logging

//final class AEDService : NSObject, ObservableObject, ACBTopicDelegate, @unchecked Sendable {
//    
//    @Published var currentTopic: ACBTopic?
//    @Published var topicList: [ACBTopic] = []
//    @Published var consoleMessage: String = ""
//    var expiryClause: String = ""
//    let logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - AEDService - ")
//    
//    func topic(_ topic: ACBTopic, didConnectWithData data: AedData) {
//        Task { @MainActor [weak self] in
//            guard let self else { return }
//            topicList.append(topic)
//            currentTopic = topic
//            let topicExpiry = data.timeout ?? 0
//            
//            if topicExpiry > 0 {
//                expiryClause = "expires in \(String(describing: topicExpiry)) mins"
//            }
//            else{
//                expiryClause = "no expiry"
//            }
//            guard let name = currentTopic?.name else { return }
//            var msg = "Topic '\(name)' connected succesfully (\(expiryClause))."
//            self.consoleMessage = msg
//            msg = "Current topic is '\(name)'. Topic Data:"
//            self.consoleMessage = msg
//        }
//        guard let topicData = data.topicData else { return }
//        
//        for data in topicData{
//            self.logger.info("Key:'\(data.key ?? "")' Value:'\(data.value ?? "")'")
//        }
//    }
//    
//    func topic(_ topic: ACBTopic, didDeleteWithMessage message: String) {
//        Task { @MainActor [weak self] in
//            guard let self else { return }
//            let msg: String = "\(message) for topic '\(String(describing: topic.name))'."
//            self.consoleMessage = msg
//        }
//    }
//    
//    func topic(_ topic: ACBTopic, didSubmitWithKey key: String, value: String, version: Int) {
//        Task { @MainActor [weak self] in
//            guard let self else { return }
//            let msg: String = "Data with k:\(key) v: \(value) in topic \(String(describing: topic.name)) submitted. Version: \(version)"
//            self.consoleMessage = msg
//        }
//    }
//    
//    func topic(_ topic: ACBTopic, didDeleteDataSuccessfullyWithKey key: String, version: Int) {
//        Task { @MainActor [weak self] in
//            guard let self else { return }
//            let msg: String = "Data with k:\(key) in topic \(String(describing: topic.name)) deleted. Version: \(version)"
//            self.consoleMessage = msg
//        }
//    }
//    
//    func topic(_ topic: ACBTopic, didSendMessageSuccessfullyWithMessage message: String) {
//        Task { @MainActor [weak self] in
//            guard let self else { return }
//            let msg: String = "Sent message - \(message) for topic '\(String(describing: topic.name))'."
//            self.consoleMessage = msg
//        }
//    }
//    
//    func topic(_ topic: ACBTopic, didNotConnectWithMessage message: String) {
//        Task { @MainActor [weak self] in
//            guard let self else { return }
//            let msg: String = "Connect Failed - \(message) for topic '\(String(describing: topic.name))'."
//            self.consoleMessage = msg
//        }
//    }
//    
//    func topic(_ topic: ACBTopic, didNotDeleteWithMessage message: String) {
//        Task { @MainActor [weak self] in
//            guard let self else { return }
//            let msg: String = "Delete Failed - \(message) for topic '\(String(describing: topic.name))'."
//            self.consoleMessage = msg
//        }
//    }
//    
//    func topic(_ topic: ACBTopic, didNotSubmitWithKey key: String, value: String, message: String) {
//        Task { @MainActor [weak self] in
//            guard let self else { return }
//            let msg: String = "Publish Data Failed - \(message) for topic '\(String(describing: topic.name))'."
//            self.consoleMessage = msg
//        }
//    }
//    
//    func topic(_ topic: ACBTopic, didNotDeleteDataWithKey key: String, message: String) {
//        Task { @MainActor [weak self] in
//            guard let self else { return }
//            let msg: String = "Delete Data Failed -\(message) for topic '\(String(describing: topic.name))'."
//            self.consoleMessage = msg
//        }
//    }
//    
//    func topic(_ topic: ACBTopic, didNotSendMessage originalMessage: String, message: String) {
//        Task { @MainActor [weak self] in
//            guard let self else { return }
//            let msg: String = "Send Message Failed - \(message) for topic '\(String(describing: topic.name))'."
//            self.consoleMessage = msg
//        }
//    }
//    
//    func topicDidDelete(_ topic: ACBTopic) {
//        Task { @MainActor [weak self] in
//            guard let self else { return }
//            let msg: String = "Topic '\(String(describing: topic.name))' has been deleted."
//            self.consoleMessage = msg
//            topicList.removeAll(where: { $0 == topic })
//        }
//    }
//    
//    func topic(_ topic: ACBTopic, didUpdateWithKey key: String, value: String, version: Int, deleted: Bool) {
//        Task { @MainActor [weak self] in
//            guard let self else { return }
//            let msg: String = "Topic \(String(describing: topic.name)) updated, k:\(key) v: \(value). Version: \(version)"
//            self.consoleMessage = msg
//        }
//    }
//    
//    func topic(_ topic: ACBTopic, didReceiveMessage message: String) {
//        Task { @MainActor [weak self] in
//            guard let self else { return }
//            let msg: String = "Received Message - \(message) for topic '\(String(describing: topic.name))'."
//            self.consoleMessage = msg
//        }
//    }
//}


final class AEDService: NSObject, ObservableObject, ACBTopicDelegate, @unchecked Sendable {
    
    // MARK: - Published Properties
    @Published var currentTopic: ACBTopic?
    @Published var topicList: [ACBTopic] = []
    @Published var consoleMessage: String = ""
    
    // MARK: - Properties
    var expiryClause: String = ""
    let logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - AEDService - ")
    
    // MARK: - ACBTopicDelegate Methods
    
    func topic(_ topic: ACBTopic, didConnectWithData data: AedData) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.handleTopicConnection(topic: topic, data: data)
        }
        logTopicData(data.topicData)
    }
    
    func topic(_ topic: ACBTopic, didDeleteWithMessage message: String) {
        updateConsoleMessage("Deleted - \(message) for topic '\(topic.name)'.")
    }
    
    func topic(_ topic: ACBTopic, didSubmitWithKey key: String, value: String, version: Int) {
        updateConsoleMessage("Data submitted - k:\(key) v:\(value) for topic '\(topic.name)'. Version: \(version)")
    }
    
    func topic(_ topic: ACBTopic, didDeleteDataSuccessfullyWithKey key: String, version: Int) {
        updateConsoleMessage("Data deleted - k:\(key) for topic '\(topic.name)'. Version: \(version)")
    }
    
    func topic(_ topic: ACBTopic, didSendMessageSuccessfullyWithMessage message: String) {
        updateConsoleMessage("Sent message - \(message) for topic '\(topic.name)'.")
    }
    
    func topic(_ topic: ACBTopic, didNotConnectWithMessage message: String) {
        updateConsoleMessage("Connect Failed - \(message) for topic '\(topic.name)'.")
    }
    
    func topic(_ topic: ACBTopic, didNotDeleteWithMessage message: String) {
        updateConsoleMessage("Delete Failed - \(message) for topic '\(topic.name)'.")
    }
    
    func topic(_ topic: ACBTopic, didNotSubmitWithKey key: String, value: String, message: String) {
        updateConsoleMessage("Publish Data Failed - \(message) for topic '\(topic.name)'.")
    }
    
    func topic(_ topic: ACBTopic, didNotDeleteDataWithKey key: String, message: String) {
        updateConsoleMessage("Delete Data Failed - \(message) for topic '\(topic.name)'.")
    }
    
    func topic(_ topic: ACBTopic, didNotSendMessage originalMessage: String, message: String) {
        updateConsoleMessage("Send Message Failed - \(message) for topic '\(topic.name)'.")
    }
    
    func topicDidDelete(_ topic: ACBTopic) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.consoleMessage = "Topic '\(topic.name)' has been deleted."
            self.topicList.removeAll { $0 == topic }
        }
    }
    
    func topic(_ topic: ACBTopic, didUpdateWithKey key: String, value: String, version: Int, deleted: Bool) {
        updateConsoleMessage("Topic '\(topic.name)' updated - k:\(key) v:\(value). Version: \(version)")
    }
    
    func topic(_ topic: ACBTopic, didReceiveMessage message: String) {
        updateConsoleMessage("Received Message - \(message) for topic '\(topic.name)'.")
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
    
    private func logTopicData(_ topicData: [TopicData]?) {
        guard let topicData = topicData else { return }
        for data in topicData {
            logger.info("Key: '\(data.key ?? "nil")' Value: '\(data.value ?? "nil")'")
        }
    }
    
    private func updateConsoleMessage(_ message: String) {
        Task { @MainActor [weak self] in
            guard let self = self else { return }
            self.consoleMessage = message
        }
    }
}
