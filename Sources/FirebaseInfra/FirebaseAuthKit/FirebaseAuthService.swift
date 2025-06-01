//
//  FireBaseAuthService.swift
//  FirebaseAuthKit
//
//  Created by Eunji Hwang on 11/5/2025.
//

import FirebaseAuth

public struct FirebaseAuthService: AuthServiceProtocol {
    public init() {}
    
    public func addStateChangeListener(handler: @escaping (User?) -> Void) -> AuthStateDidChangeListenerHandle {
        print("🖐️ Auth: -------- Add state change listener - changed")
        return Auth.auth().addIDTokenDidChangeListener { _, user in
            handler(user)
        }
    }
    
    
    public func removeAddStateChangeListener(handler: AuthStateDidChangeListenerHandle) {
        Auth.auth().removeStateDidChangeListener(handler)
    }

    public func signInAnonymously() async throws -> User {
        print("🖐️ Auth: -------- Sign In Anonymously")
        let result = try await Auth.auth().signInAnonymously()
        return result.user
    }

    public func signOut() async throws {
        print("🖐️ Auth: -------- Sign Out")
        try await Auth.auth().signOut()
    }

    public var currentUser: UserSession? {
        print("🖐️ Auth: -------- current User")
        guard let user = Auth.auth().currentUser else { return nil }
        return UserSession(uid: user.uid)
    }

    public func upgradeToApple(idToken: String, nonce: String) async throws {
//        let credential = OAuthProvider.credential(
//            withProviderID: "apple.com",
//            idToken: idToken,
//            rawNonce: nonce
//        )
        let credential = OAuthProvider.credential(providerID: AuthProviderID.apple, idToken: idToken, rawNonce: nonce, accessToken: nil)
        
        try await signInWithCredential(credential)
    }

    public func upgradeToGoogle(idToken: String, accessToken: String) async throws {
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )
        _ = try await Auth.auth().currentUser?.link(with: credential)
    }
    
    public func signIn(email: String, password: String) async throws {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        print("Auth result after sign in ", authResult)
    }
    
    public func createAccount(email: String, password: String) async throws {
        guard let user = Auth.auth().currentUser else { return }
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        try await user.link(with: credential)
    }
    
    public func signInWithCredential(_ credential: AuthCredential) async throws {
        _ = try await Auth.auth().currentUser?.link(with: credential)
    }
}
