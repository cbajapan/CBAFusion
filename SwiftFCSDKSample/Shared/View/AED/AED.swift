//
//  AED.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 8/31/21.
//

import SwiftUI

struct AED: View {
    
    @State var topicName = ""
    @State var expiry = ""
    @State var key = ""
    @State var value = ""
    @State private var messageText = ""
    @State private var placeholder = ""
    @State private var messageHeight: CGFloat = 0
    @State private var keyboardHeight: CGFloat = 0
    let topics = ["Topic 1", "Topic 2", "Topic 3", "Topic 4", "Topic 5"]
    
    var body: some View {
        NavigationView  {
            Form {
                Section(header: Text("Topic")) {
                    TextField("Topic Name", text: $topicName)
                    TextField("Expiry", text: $expiry)
                    Button("Connect") {
                        print("Connect Please")
                    }
                }
                Section(header: Text("Data")) {
                    TextField("Key", text: $key)
                    TextField("Value", text: $value)
                    Button("Publish") {
                        print("Publish Value")
                    }
                    Button("Delete") {
                        print("Delete Value")
                    }
                }
                
                Section(header: Text("Message")) {
                    TextField("Your message", text: $topicName)
                    Button("Send") {
                        print("Send Message")
                    }
                }
                
                Section(header: Text("Connected Topics")) {
                    List {
                        ForEach(topics, id: \.self) { topic in
                            TopicCell(topic: topic)
                        }
                    }
                    
                }
                Section(header: Text("Console")) {
                    AutoSizingTextView(text: self.$messageText, height: self.$messageHeight, placeholder: self.$placeholder)
                        .frame(height: self.messageHeight < 150 ? self.messageHeight : 150)
                        .padding(.horizontal)
                        .foregroundColor(.white)
                        .background(Color.black)
                        .font(.body)
                }.background(Color.black)
                    .listRowBackground(Color.black)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(content: {
                 ToolbarItem(placement: .principal, content: {
                 Text("Application Event Distribution")
              })})        }
        .onTapGesture {
//            hideKeyboard()
        }
    }
}

struct AED_Previews: PreviewProvider {
    static var previews: some View {
        AED()
    }
}
