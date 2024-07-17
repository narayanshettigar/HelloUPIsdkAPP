//
//  ContactScreen.swift
//  SampleAudioApp
//
//  Created by Narayan Shettigar on 17/07/24.
//

import Foundation
import SwiftUI
import Contacts

struct ContentViewContacts: View {
    @StateObject private var contactsManager = ContactsManager()
    @State private var uploadResult = ""

    var body: some View {
        VStack {
            Button(action: {
                self.contactsManager.requestContactsPermission { granted in
                    if granted {
                        self.contactsManager.fetchContacts()
                    }
                }
            }) {
                Text("Fetch Contacts")
            }
            
            Text("Contacts count: \(contactsManager.contacts.count)")
            
            Button(action: {
                uploadContacts()
            }) {
                Text("Upload Contacts")
            }
            .disabled(contactsManager.contacts.isEmpty || contactsManager.isUploading)
            
            if contactsManager.isUploading {
                ProgressView()
            }
            
            if !uploadResult.isEmpty {
                Text(uploadResult)
                    .foregroundColor(uploadResult.contains("Success") ? .green : .red)
            }
            
//            ContactsListView(contacts: contactsManager.contacts)
//                .padding(.horizontal)
            
//            Spacer()
        }
        .onAppear {
            self.contactsManager.requestContactsPermission { granted in
                if granted {
                    self.contactsManager.fetchContacts()
                }
            }
        }
    }
    
    func uploadContacts() {
        uploadResult = ""
        
        contactsManager.uploadContacts { success, message in
            uploadResult = message
        }
    }
}

struct ContactsListView: View {
    var contacts: [CNContact]
    
    var body: some View {
        List(contacts, id: \.identifier) { contact in
            Text("\(contact.givenName) \(contact.familyName)")
        }
        .frame(maxHeight: UIScreen.main.bounds.height * 0.2)
        .background(Color.gray.opacity(0.1))
        .cornerRadius(10)
        .padding()
    }
}
