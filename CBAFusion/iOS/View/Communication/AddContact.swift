//
//  AddContact.swift
//  CBAFusion
//
//  Created by Cole M on 11/16/21.
//

import SwiftUI

/// A view for adding or editing a contact.
struct AddContact: View {
    
    // Environment objects to access shared data and presentation mode
    @EnvironmentObject var contactService: ContactService
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            Form {
                // Section for contact details
                contactDetailsSection
                
                // Save button to add or edit a contact
                saveButton
            }
            .alert(isPresented: $contactService.alert) {
                Alert(
                    title: Text("Please fill in the Contact information"),
                    dismissButton: .cancel(Text("Okay"))
                )
            }
            .navigationBarTitle(contactService.isEdit ? "Edit Contact" : "Add Contact")
        }
    }
    
    /// A section for entering contact details.
    private var contactDetailsSection: some View {
        Section(header: Text(contactService.isEdit ? "Edit Contact" : "Add Contact")) {
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
    }
    
    /// A button to save the contact information.
    private var saveButton: some View {
        Button(action: {
            Task {
                // Add or edit the contact based on the current mode
                if contactService.isEdit {
                    await contactService.addContact(contactService.contactToEdit, isEdit: true)
                } else {
                    await contactService.addContact(nil, isEdit: false)
                }
                
                // Clear the contact service and dismiss the view
                await contactService.clearToDismiss()
                if contactService.isEdit {
                    contactService.isEdit = false
                }
                presentationMode.wrappedValue.dismiss()
            }
        }) {
            Text("Save")
        }
    }
}

// MARK: - Preview

struct AddContact_Previews: PreviewProvider {
    static var previews: some View {
        AddContact()
            .environmentObject(ContactService()) // Provide a mock ContactService for previews
    }
}
