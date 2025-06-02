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
    func upgradeToGoogle(idToken: String, accessToken: String) async throws -> User
    var currentUser: User? { get }
    
}
