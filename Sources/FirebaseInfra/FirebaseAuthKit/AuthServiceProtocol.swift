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
    func upgradeToGoogle(idToken: String, accessToken: String) async throws -> AuthResult
    var currentUser: User? { get }
    
}
