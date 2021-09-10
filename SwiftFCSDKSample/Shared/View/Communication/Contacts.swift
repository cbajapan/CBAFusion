//
//  Contacts.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/2/21.
//

import SwiftUI

struct Contacts: View {
    
    var contacts = [Contact(name: "FCSDK", number: "1002", icon: "sdk"), Contact(name: "FCSDK-SIP", number: "sip:4005@192.168.99.103", icon: "sip")]
    
    @State var showFullSheet: ActiveSheet?
    @State var callStarted: Bool = false
    @State var contact: Contact = Contact(name: "", number: "", icon: "")
    @ObservedObject var call: FCSDKCall
    
    var body: some View {
        NavigationView {
            List {
                ForEach(contacts, id: \.self) { contact in
                    ContactsCell(contact: contact)
                        .onTapGesture {
                            self.contact = contact
                            self.callStarted = true
                            self.showFullSheet = .communincationSheet
                        }
                }
            }
            .navigationBarTitle("Recent Calls")
            .navigationBarItems(trailing:
                                    Button(action: {
                self.showFullSheet = .callSheet
            }, label: {
                Image(systemName: "plus")
                    .foregroundColor(Color.blue)
            })                
            )
        }
        .fullScreenCover(item: self.$showFullSheet) { sheet in
            switch sheet {
            case .callSheet:
                CallSheet(callStarted: self.$callStarted, showFullSheet: self.$showFullSheet)
            case .communincationSheet:
                Communication(contact: self.$contact, showFullSheet: self.$showFullSheet, call: self.call)
            }
        }
    }
}

enum ActiveSheet: Identifiable {
    case callSheet, communincationSheet

    var id: Int {
        hashValue
    }
}


struct Contacts_Previews: PreviewProvider {
    static var previews: some View {
        Contacts(contact: Contact(name: "", number: "", icon: ""), call: FCSDKCall(handle: ""))
    }
}
