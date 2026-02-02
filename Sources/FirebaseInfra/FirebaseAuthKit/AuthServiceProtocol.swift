//
//  AuthServiceProtocol.swift
//  FirebaseAuthKit
//
//  Created by Eunji Hwang on 11/5/2025.
//

import FirebaseAuth

public protocol AuthServiceProtocol {
    func signInAnonymously() async throws -> User
    func signOut() async throws
    func upgradeToApple(idToken: String, nonce: String) async throws -> User
    // if it's real create account -> true, sign in -> false
    func upgradeToGoogle(idToken: String, accessToken: String) async throws -> (User, Bool)
    var currentUser: User? { get }
    
}
