//
//  ContactsCell.swift
//  SwiftFCSDKSample
//
//  Created by Cole M on 9/2/21.
//

import SwiftUI

struct ContactsCell: View {
    
    @State var contact: ContactModel
    @State private var isChecked: Bool = false
    
    var body: some View {
        HStack {
            ZStack{
                if #available(iOS 15.0, *) {
                    Circle()
                        .fill(Color.cyan)
                        .frame(width: 30, height: 30, alignment: .leading)
                } else {
                    Circle()
                        .fill(Color.blue)
                        .frame(width: 30, height: 30, alignment: .leading)
                }
            }
            VStack(alignment: .leading, spacing: 0) {
                Text(contact.username)
                    .fontWeight(.bold)
                Text(contact.number)
                    .fontWeight(.light)
                    .padding(.leading, 10)
            }
        }
    }
}

struct Contact: Hashable {
    var id = UUID()
    var name: String
    var number: String
    var icon: String
}
