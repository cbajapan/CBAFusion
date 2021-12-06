//
//  AEDService.swift
//  SwiftFCSDKSample
//
//  Created by Ryan Walker on 11/21/21.
//

import Foundation
import FCSDKiOS

class AEDService : NSObject, ObservableObject, ACBTopicDelegate {
    
    @Published var currentTopic: ACBTopic?
    @Published var topicList: [ACBTopic] = []
    @Published var consoleMessage: String = ""
    
    func topic(_ topic: ACBTopic, didConnectWithData data: AedData) {
        Task {
            await MainActor.run {
                topicList.append(topic)
                currentTopic = topic
                let topicExpiry = data.timeout ?? 0
                
                var expiryClause: String = ""
                if topicExpiry > 0 {
                    expiryClause = "expires in \(String(describing: topicExpiry)) mins"
                }
                else{
                    expiryClause = "no expiry"
                }
                
                var msg = "Topic '\(currentTopic?.name ?? "")' connected succesfully (\(expiryClause))."
                self.consoleMessage = msg
                msg = "Current topic is '\(currentTopic?.name ?? "")'. Topic Data:"
                self.consoleMessage = msg
            }
        }
        guard let topicData = data.topicData else { return }
        
        for data in topicData{
            print("Key:'\(data.key ?? "")' Value:'\(data.value ?? "")'")
        }
    }
    
    func topic(_ topic: ACBTopic, didDeleteWithMessage message: String) {
        Task {
            await MainActor.run {
                let msg: String = "\(message) for topic '\(String(describing: topic.name))'."
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didSubmitWithKey key: String, value: String, version: Int) {
        Task {
            await MainActor.run {
                let msg: String = "Data with k:\(key) v: \(value) in topic \(String(describing: topic.name)) submitted. Version: \(version)"
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didDeleteDataSuccessfullyWithKey key: String, version: Int) {
        Task {
            await MainActor.run {
                let msg: String = "Data with k:\(key) in topic \(String(describing: topic.name)) deleted. Version: \(version)"
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didSendMessageSuccessfullyWithMessage message: String) {
        Task {
            await MainActor.run {
                let msg: String = "Sent message - \(message) for topic '\(String(describing: topic.name))'."
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didNotConnectWithMessage message: String) {
        Task {
            await MainActor.run {
                let msg: String = "Connect Failed - \(message) for topic '\(String(describing: topic.name))'."
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didNotDeleteWithMessage message: String) {
        Task {
            await MainActor.run {
                let msg: String = "Delete Failed - \(message) for topic '\(String(describing: topic.name))'."
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didNotSubmitWithKey key: String, value: String, message: String) {
        Task {
            await MainActor.run {
                let msg: String = "Publish Data Failed - \(message) for topic '\(String(describing: topic.name))'."
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didNotDeleteDataWithKey key: String, message: String) {
        Task {
            await MainActor.run {
                let msg: String = "Delete Data Failed -\(message) for topic '\(String(describing: topic.name))'."
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didNotSendMessage originalMessage: String, message: String) {
        Task {
            await MainActor.run {
                let msg: String = "Send Message Failed - \(message) for topic '\(String(describing: topic.name))'."
                self.consoleMessage = msg
            }
        }
    }
    
    func topicDidDelete(_ topic: ACBTopic?) {
        Task {
            await MainActor.run {
                let msg: String = "Topic '\(String(describing: topic?.name))' has been deleted."
                self.consoleMessage = msg
                topicList.removeAll(where: { $0 == topic }) 
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didUpdateWithKey key: String, value: String, version: Int, deleted: Bool) {
        Task {
            await MainActor.run {
                let msg: String = "Topic \(String(describing: topic.name)) updated, k:\(key) v: \(value). Version: \(version)"
                self.consoleMessage = msg
            }
        }
    }
    
    func topic(_ topic: ACBTopic, didReceiveMessage message: String) {
        Task {
            await MainActor.run {
                let msg: String = "Received Message - \(message) for topic '\(String(describing: topic.name))'."
                self.consoleMessage = msg
            }
        }
    } 
}
