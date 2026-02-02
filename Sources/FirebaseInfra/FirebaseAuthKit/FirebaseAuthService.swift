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
        let userDataResult =  try await Auth.auth().signInAnonymously()
        return userDataResult.user
    }

    public func signOut() async throws {
        print("🖐️ Auth: -------- Sign Out")
        try await Auth.auth().signOut()
    }

    public var currentUser: User? {
        print("🖐️ Auth: -------- current User")
        guard let user = Auth.auth().currentUser else { return nil }
        return user
    }
    
    public func getUserId() throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseAuth.AuthErrorCode.userNotFound
        }
        return userId
    }

    
    public func getCurrentUser() -> User? {
        print("🖐️ Auth: -------- current User")
        guard let user = Auth.auth().currentUser else { return nil }
        return user
    }

    public func upgradeToApple(idToken: String, nonce: String) async throws -> User {
//        let credential = OAuthProvider.credential(
//            withProviderID: "apple.com",
//            idToken: idToken,
//            rawNonce: nonce
//        )
        let credential = OAuthProvider.credential(providerID: AuthProviderID.apple, idToken: idToken, rawNonce: nonce, accessToken: nil)
        
        let (user, isNewAccout) = try await signInWithCredential(credential)
        return user
    }

    public func signInWithGoogle(idToken: String, accessToken: String) async throws -> (User, Bool) {
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )
        print("구글 로그인 진행 - sign in")
        let (user, isNewAccount) = try await signInWithCredential(credential)
        print("진행 완료")
        return (user, isNewAccount)
    }
    // create account
    public func upgradeToGoogle(idToken: String, accessToken: String) async throws -> (User, Bool) {
        do {
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )
            let user = try await upgradeWithCredential(credential)
            return (user, true)
        } catch {
            let nsError = error as NSError
                let code = AuthErrorCode(rawValue: nsError.code)

                switch code {
                case .emailAlreadyInUse,
                     .credentialAlreadyInUse,
                     .accountExistsWithDifferentCredential:
                    print("이미 있는 유저라 sign in 으로 진행")
                    let result = try await self.signInWithGoogle(idToken: idToken, accessToken: accessToken)
                    return result
                default:
                    throw error
                }
            
        }
    }
    
    public func signIn(email: String, password: String) async throws -> User {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        print("Auth result after sign in ", authResult)
        return authResult.user
    }
    
    public func createAccount(email: String, password: String) async throws -> User {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        let user = try await upgradeWithCredential(credential)
        return user
    }
    
    public func signInWithCredential(_ credential: AuthCredential) async throws -> (User, Bool) {
        let authDataResult = try await Auth.auth().signIn(with: credential)
        print("계정 초기 정보", authDataResult.additionalUserInfo)
        print("이거 새로운 계정인가요??", authDataResult.additionalUserInfo?.isNewUser)
        let isNewUser = authDataResult.additionalUserInfo?.isNewUser ?? false
        return (authDataResult.user, isNewUser)
    }
    
    public func upgradeWithCredential(_ credential: AuthCredential) async throws -> User {
        guard let currentUser = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        let userData = try await currentUser.link(with: credential)
        return userData.user
    }
    
    public func sendResetPasswordEmail(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
}
