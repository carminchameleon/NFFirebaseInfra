////
////  UserSession.swift
////  FirebaseAuthKit
////
////  Created by Eunji Hwang on 11/5/2025.
////
//import FirebaseAuth
//
//public struct UserSession: Equatable {
//    public let uid: String
//    public let email: String?
//    public let isAnonymous: Bool
//    public let providerID: String?
//
//    public init(
//        uid: String,
//        email: String?,
//        isAnonymous: Bool,
//        providerID: String?
//    ) {
//        self.uid = uid
//        self.email = email
//        self.isAnonymous = isAnonymous
//        self.providerID = providerID
//    }
//
//    public init(from user: User) {
//        self.uid = user.uid
//        self.email = user.email
//        self.isAnonymous = user.isAnonymous
//        self.providerID = user.providerData.first?.providerID
//    }
//    
//    public init(uid: String) {
//        self.uid = uid
//        self.email = nil
//        self.isAnonymous = true
//        self.providerID = nil
//    }
//    
//    
//}
