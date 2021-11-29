//
//  AEDService.swift
//  SwiftFCSDKSample
//
//  Created by Ryan Walker on 11/21/21.
//

import Foundation
import FCSDKiOS

class AEDService : NSObject, ObservableObject, ACBTopicDelegate {
    
    @Published var currentTopic : ACBTopic?
    @Published var topicList : [ACBTopic] = []
    
    func topic(_ topic: ACBTopic, didConnectWithData data: AedData) {
            topicList.append(topic)
            //topicListView.reloadData()
            currentTopic = topic
        //let topicExpiry = (data.timeout as? NSNumber)?.intValue ?? 0
        let topicExpiry = data.timeout ?? 0
        
        var expiryClause: String = ""
        if topicExpiry > 0{
            expiryClause = "expires in \(String(describing: topicExpiry)) mins"
        }
        else{
            expiryClause = "no expiry"
        }
        
        var msg = "Topic '\(currentTopic?.name ?? "")' connected succesfully (\(expiryClause))."
            print(msg)
            msg = "Current topic is '\(currentTopic?.name ?? "")'. Topic Data:"
            print(msg)

        guard let topicData = data.data else { return }
                
        for data in topicData{
            print("Key:'\(data.key ?? "")' Value:'\(data.value ?? "")'")
        }
    }
    
    func topic(_ topic: ACBTopic, didDeleteWithMessage message: String) {
        let msg: String = "\(message) for topic '\(String(describing: topic.name))'."
        print(msg)
    }
    
    func topic(_ topic: ACBTopic, didSubmitWithKey key: String, value: String, version: Int) {
        let msg: String = "Data with k:\(key) v: \(value) in topic \(String(describing: topic.name)) submitted. Version: \(version)"
        print(msg)
    }
    
    func topic(_ topic: ACBTopic, didDeleteDataSuccessfullyWithKey key: String, version: Int) {
        let msg: String = "Data with k:\(key) in topic \(String(describing: topic.name)) deleted. Version: \(version)"
        print(msg)
    }
    
    func topic(_ topic: ACBTopic, didSendMessageSuccessfullyWithMessage message: String) {
        let msg: String = "Sent message - \(message) for topic '\(String(describing: topic.name))'."
        print(msg)
    }
    
    func topic(_ topic: ACBTopic, didNotConnectWithMessage message: String) {
        let msg: String = "Connect Failed - \(message) for topic '\(String(describing: topic.name))'."
        print(msg)
    }
    
    func topic(_ topic: ACBTopic, didNotDeleteWithMessage message: String) {
        let msg: String = "Delete Failed - \(message) for topic '\(String(describing: topic.name))'."
        print(msg)
    }
    
    func topic(_ topic: ACBTopic, didNotSubmitWithKey key: String, value: String, message: String) {
        let msg: String = "Publish Data Failed - \(message) for topic '\(String(describing: topic.name))'."
        print(msg)
    }
    
    func topic(_ topic: ACBTopic, didNotDeleteDataWithKey key: String, message: String) {
        let msg: String = "Delete Data Failed -\(message) for topic '\(String(describing: topic.name))'."
        print(msg)
    }
    
    func topic(_ topic: ACBTopic, didNotSendMessage originalMessage: String, message: String) {
        let msg: String = "Send Message Failed - \(message) for topic '\(String(describing: topic.name))'."
        print(msg)
    }
    
    func topicDidDelete(_ topic: ACBTopic?) {
        let msg: String = "Topic '\(String(describing: topic?.name))' has been deleted."
        print(msg)
    }
    
    func topic(_ topic: ACBTopic, didUpdateWithKey key: String, value: String, version: Int, deleted: Bool) {
        let msg: String = "Topic \(String(describing: topic.name)) updated, k:\(key) v: \(value). Version: \(version)"
        print(msg)
    }
    
    func topic(_ topic: ACBTopic, didReceiveMessage message: String) {
        let msg: String = "Received Message - \(message) for topic '\(String(describing: topic.name))'."
        print(msg)
    }
    
    
}
