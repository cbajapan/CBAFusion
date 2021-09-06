//
//  Contacts.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/2/21.
//

import SwiftUI

struct Contacts: View {
    
    var contacts = [Contact(name: "FCSDK", number: "1002", icon: "sdk"), Contact(name: "FCSDK-SIP", number: "sip:4005@192.168.99.103", icon: "sip")]
    @State var callStarted: Bool = false
    @State var contact: Contact = Contact(name: "", number: "", icon: "")
    
    var body: some View {
        NavigationView {
            List {
                ForEach(contacts, id: \.self) { contact in
                    ContactsCell(contact: contact)
                        .onTapGesture {
                            self.contact = contact
                            self.callStarted = true
                        }
                }
            }
        }
        .navigationBarTitle("Contacts", displayMode: .automatic)
        .fullScreenCover(isPresented: self.$callStarted, content: {
            Communication(contact: self.$contact, callStarted: self.$callStarted)
        })
    }
}


struct Contacts_Previews: PreviewProvider {
    static var previews: some View {
        Contacts(contact: Contact(name: "'", number: "", icon: ""))
    }
}
