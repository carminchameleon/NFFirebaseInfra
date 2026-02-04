//
//  AuthServiceProtocol.swift
//  FirebaseAuthKit
//
//  Created by Eunji Hwang on 11/5/2025.
//

import FirebaseAuth
import SwiftUI
public protocol AuthServiceProtocol: Sendable {
    func signInAnonymously() async throws -> User
    func signOut() async throws
    
    // if it's real create account -> true, sign in -> false
    func upgradeToGoogle(idToken: String, accessToken: String) async throws -> (User, Bool)
    var currentUser: User? { get }
    
//    func upgradeAnonymousWithApple() async throws ->  (User, Bool)
//    func signInWithApple() async throws ->  (User, Bool)
    
}
