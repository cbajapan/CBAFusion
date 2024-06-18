//
//  AddContact.swift
//  CBAFusion
//
//  Created by Cole M on 11/16/21.
//

import SwiftUI

struct AddContact: View {
    
    @EnvironmentObject var contactService: ContactService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView  {
            Form {
                Section(header: Text(self.contactService.isEdit ? "Edit Contact" : "Add Contact")) {
                    VStack(alignment: .leading) {
                        Text("Contact")
                            .bold()
                        TextField("Enter Contact name...", text: $contactService.username)
                        Divider()
                        Text("Phone Number")
                            .bold()
                        TextField("Enter Phone Number...", text: $contactService.number)
                    }
                }
                Button(action: {
                    Task {
                        if self.contactService.isEdit {
                            await self.contactService.addContact(self.contactService.contactToEdit, isEdit: true)
                        } else {
                            await self.contactService.addContact(nil, isEdit: false)
                        }
                        await self.contactService.clearToDismiss()
                        if self.contactService.isEdit {
                            self.contactService.isEdit = false
                        }
                        self.presentationMode.wrappedValue.dismiss()
                    }
                }, label: {
                    Text("Save")
                })
            }
            .alert(isPresented: self.$contactService.alert, content: {
                Alert(
                    title: Text("Please fill in the Contact information"),
                    message: Text(""),
                    dismissButton: .cancel(Text("Okay"), action: {
                    })
                )
            })
            .navigationBarTitle(self.contactService.isEdit ? "Edit Contact" : "Add Contact")
        }
    }
}


struct AddContact_Previews: PreviewProvider {
    static var previews: some View {
        AddContact()
    }
}
