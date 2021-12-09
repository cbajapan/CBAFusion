//
//  ContactsCell.swift
//  CBAFusion
//
//  Created by Cole M on 9/2/21.
//

import SwiftUI

struct ContactsCell: View {
    
    @State var contact: ContactModel
    @State private var isChecked: Bool = false
    @Environment(\.colorScheme) var colorScheme
    
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
                    .foregroundColor(.white)
                Text(contact.number)
                    .fontWeight(.light)
                    .padding(.leading, 10)
                    .foregroundColor(.white)
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
