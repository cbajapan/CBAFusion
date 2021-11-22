//
//  AddContact.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 11/16/21.
//

import SwiftUI

struct AddContact: View {
    
    @EnvironmentObject var contact: ContactService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView  {
            Form {
                Section(header: Text(self.contact.isEdit ? "Edit Contact" : "Add Contact")) {
                    VStack(alignment: .leading) {
                        Text("Contact")
                            .bold()
                        TextField("Enter Contact name...", text: $contact.username)
                        Divider()
                        Text("Phone Number")
                            .bold()
                        TextField("Enter Phone Number...", text: $contact.number)
                    }
                }
                Button(action: {
                    Task {
                        if self.contact.isEdit {
                            await self.contact.addContact(self.contact.contactToEdit, isEdit: true)
                        } else {
                            await self.contact.addContact(nil, isEdit: false)
                        }
                        await self.contact.clearToDismiss()
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }, label: {
                    Text("Save")
                })
            }
            .alert("Please fill in the Contact information", isPresented: self.$contact.alert, actions: {
                Button("OK", role: .cancel) { }
            })
            .navigationBarTitle(self.contact.isEdit ? "Edit Contact" : "Add Contact")
        }
    }
}


struct AddContact_Previews: PreviewProvider {
    static var previews: some View {
        AddContact()
    }
}
