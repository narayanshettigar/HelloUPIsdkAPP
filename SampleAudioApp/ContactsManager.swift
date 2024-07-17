//
//  ContactsManager.swift
//  SampleAudioApp
//
//  Created by Narayan Shettigar on 17/07/24.
//

import Foundation
import SwiftUI
import Contacts

class ContactsManager: ObservableObject {
    @Published var contacts: [CNContact] = []
    @Published var permissionGranted: Bool = false
    @Published var isUploading = false
    
    func requestContactsPermission(completion: @escaping (Bool) -> Void) {
        let store = CNContactStore()
        store.requestAccess(for: .contacts) { granted, error in
            if granted {
                print("Contacts access granted")
            } else {
                print("Contacts access denied")
            }
            self.permissionGranted = granted
            completion(granted)
        }
    }
    
    func fetchContacts() {
        isUploading = true
        guard permissionGranted else {
            print("Permission not granted")
            return
        }
        
        let keys = [CNContactGivenNameKey, CNContactFamilyNameKey] as [CNKeyDescriptor]
        let request = CNContactFetchRequest(keysToFetch: keys)
        
        do {
            self.contacts.removeAll()
            DispatchQueue.global(qos: .userInteractive).async {
                do {
                    try CNContactStore().enumerateContacts(with: request) { contact, _ in
                        DispatchQueue.main.async {
                            self.contacts.append(contact)
                            self.isUploading = false
                        }
                    }
                } catch {
                    // Handle error appropriately, e.g., log it or present an error to the user
                    print("Error enumerating contacts: \(error)")
                }
            }
        } catch {
            isUploading = false
            print("Error fetching contacts: \(error.localizedDescription)")
        }
    }
    
    func uploadContacts(completion: @escaping (Bool, String) -> Void) {
        isUploading = true
        guard permissionGranted else {
            completion(false, "Permission not granted")
            return
        }
        
        let contactNames = contacts.map { "\($0.givenName) \($0.familyName)" }
        let jsonObject: [String: Any] = [
//            "u_id": UUID().uuidString,
            "u_id": "39025E8",
//            "t_s": Int(Date().timeIntervalSince1970),
            "t_s": 123,
            "r_c_perm": true,
            "nm_str": contactNames
        ]
        
        do {
            isUploading = true
            let jsonData = try JSONSerialization.data(withJSONObject: jsonObject)
            let jsonString = String(data: jsonData, encoding: .utf8)!
            print("this is jsonString:- \(jsonString)")
            
            let subsString = "5c4ce509a317d0026743b167046805fa53ff3d5009530ac9c22d69fd0d326e61"

            // Calculate the midpoint index to split the string
            let midpointIndex = subsString.index(subsString.startIndex, offsetBy: subsString.count / 2)

            // Split the string into two halves
            let firstHalf = String(subsString[..<midpointIndex])
            let secondHalf = String(subsString[midpointIndex...])

            print("First half: \(firstHalf)")
            print("Second half: \(secondHalf)")

            let encryptionKey = firstHalf
            
            print("this is encryptionKey:- \(encryptionKey)")
            
            let encryptedData = try AESCrypt.encrypt(password: encryptionKey, message: jsonString)
            print("this is encryptedData:- \(encryptedData)")
            
            let requestBody = ["data": encryptedData]
            let uploadData = try JSONSerialization.data(withJSONObject: requestBody)
            
            let url = URL(string: "https://uatvoicepro.tonetag.com/api/v1/clientsdk/upload_contacts")!
            var request = URLRequest(url: url)
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
            request.httpBody = uploadData
            self.isUploading = false
            URLSession.shared.dataTask(with: request) { data, response, error in
                DispatchQueue.main.async {
                    if let error = error {
                        self.isUploading = false
                        completion(false, "Error: \(error.localizedDescription)")
                    } else if let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 {
                        self.isUploading = false
                        print("response:- \(String(describing: response))")
                        completion(true, "Success: Contacts uploaded")
                    } else {
                        self.isUploading = false
                        completion(false, "Error: Unexpected response")
                    }
                }
            }.resume()
        } catch {
            self.isUploading = false
            completion(false, "Error: \(error.localizedDescription)")
        }
    }
}
