//
//  AEDService.swift
//  CBAFusion
//
//  Created by Ryan Walker on 11/21/21.
//

import Foundation
import FCSDKiOS
import Logging

class AEDService : NSObject, ObservableObject, ACBTopicDelegate {
    
    @Published var currentTopic: ACBTopic?
    @Published var topicList: [ACBTopic] = []
    @Published var consoleMessage: String = ""
    var expiryClause: String = ""
    var logger: Logger
    
    
    override init() {
        self.logger = Logger(label: "\(Constants.BUNDLE_IDENTIFIER) - AEDService - ")
    }
    
    func topic(_ topic: ACBTopic, didConnectWithData data: AedData) {
        Task {
            await MainActor.run {
                topicList.append(topic)
                currentTopic = topic
                let topicExpiry = data.timeout ?? 0
                
                if topicExpiry > 0 {
                    expiryClause = "expires in \(String(describing: topicExpiry)) mins"
                }
                else{
                    expiryClause = "no expiry"
                }
            }
            guard let name = currentTopic?.name else { return }
            await MainActor.run {
                var msg = "Topic '\(name)' connected succesfully (\(expiryClause))."
                self.consoleMessage = msg
                msg = "Current topic is '\(name)'. Topic Data:"
                self.consoleMessage = msg
            }
        }
        guard let topicData = data.topicData else { return }
        
        for data in topicData{
            self.logger.info("Key:'\(data.key ?? "")' Value:'\(data.value ?? "")'")
        }
    }
    
    func topic(_ topic: ACBTopic, didDeleteWithMessage message: String) {
        Task {
            let msg: String = "\(message) for topic '\(String(describing: topic.name))'."
            await MainActor.run {
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didSubmitWithKey key: String, value: String, version: Int) {
        Task {
            let msg: String = "Data with k:\(key) v: \(value) in topic \(String(describing: topic.name)) submitted. Version: \(version)"
            await MainActor.run {
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didDeleteDataSuccessfullyWithKey key: String, version: Int) {
        Task {
            let msg: String = "Data with k:\(key) in topic \(String(describing: topic.name)) deleted. Version: \(version)"
            await MainActor.run {
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didSendMessageSuccessfullyWithMessage message: String) {
        Task {
            let msg: String = "Sent message - \(message) for topic '\(String(describing: topic.name))'."
            await MainActor.run {
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didNotConnectWithMessage message: String) {
        Task {
            let msg: String = "Connect Failed - \(message) for topic '\(String(describing: topic.name))'."
            await MainActor.run {
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didNotDeleteWithMessage message: String) {
        Task {
            let msg: String = "Delete Failed - \(message) for topic '\(String(describing: topic.name))'."
            await MainActor.run {
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didNotSubmitWithKey key: String, value: String, message: String) {
        Task {
            let msg: String = "Publish Data Failed - \(message) for topic '\(String(describing: topic.name))'."
            await MainActor.run {
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didNotDeleteDataWithKey key: String, message: String) {
        Task {
            let msg: String = "Delete Data Failed -\(message) for topic '\(String(describing: topic.name))'."
            await MainActor.run {
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didNotSendMessage originalMessage: String, message: String) {
        Task {
            let msg: String = "Send Message Failed - \(message) for topic '\(String(describing: topic.name))'."
            await MainActor.run {
                self.consoleMessage = msg
            }
        }
    }
    
    func topicDidDelete(_ topic: ACBTopic) {
        Task {
            let msg: String = "Topic '\(String(describing: topic.name))' has been deleted."
            await MainActor.run {
                self.consoleMessage = msg
                topicList.removeAll(where: { $0 == topic }) 
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didUpdateWithKey key: String, value: String, version: Int, deleted: Bool) {
        Task {
            let msg: String = "Topic \(String(describing: topic.name)) updated, k:\(key) v: \(value). Version: \(version)"
            await MainActor.run {
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didReceiveMessage message: String) {
        Task {
            let msg: String = "Received Message - \(message) for topic '\(String(describing: topic.name))'."
            await MainActor.run {
                self.consoleMessage = msg
            }
        }
    } 
}
