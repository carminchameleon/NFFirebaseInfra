//
//  FireBaseAuthService.swift
//  FirebaseAuthKit
//
//  Created by Eunji Hwang on 11/5/2025.
//

import FirebaseAuth
import UIKit


public protocol AppleAuthLinking: Sendable {
    /// 익명 유저를 Apple로 "연결(link)" 시도.
    /// - 실패가 "이미 다른 계정에 연결된 credential"이면 sign-in으로 fallback.
    /// - 반환 Bool은 (내 앱 관점에서) “link 성공(=새로 연결)”이면 true, fallback sign-in이면 Firebase의 isNewUser를 반환.
    func upgradeToApple(idToken: String, nonce: String) async throws -> AuthUser

    /// 기존 Apple 계정으로 sign-in
    func signInWithApple(idToken: String, nonce: String) async throws -> AuthUser
}


public final class FirebaseAuthService: AuthServiceProtocol, AppleAuthLinking {
    
   
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

    public func signInAnonymously() async throws -> AuthUser {
        print("🖐️ Auth: -------- Sign In Anonymously")
        let userDataResult =  try await Auth.auth().signInAnonymously()
        return userDataResult.user.getAuthUser()
    }

    public func signOut() async throws {
        print("🖐️ Auth: -------- Sign Out")
        try await Auth.auth().signOut()
    }

    public var currentUser: AuthUser? {
        print("🖐️ Auth: -------- current User")
        guard let user = Auth.auth().currentUser else { return nil }
        return user.getAuthUser()
    }
    
    public func getUserId() throws -> String {
        guard let userId = Auth.auth().currentUser?.uid else {
            throw FirebaseAuth.AuthErrorCode.userNotFound
        }
        return userId
    }

    
    public func getCurrentUser() -> AuthUser? {
        print("🖐️ Auth: -------- current User")
        guard let user = Auth.auth().currentUser else { return nil }
        return user.getAuthUser()
    }
    
    public func signInWithGoogle(idToken: String, accessToken: String) async throws -> AuthResult {
        let credential = GoogleAuthProvider.credential(
            withIDToken: idToken,
            accessToken: accessToken
        )
        print("구글 로그인 진행 - sign in")
        let (user, isNewAccount) = try await signInWithCredential(credential)
        print("진행 완료")
        let authUser = AuthUser(uid: user.uid,
                                email: user.email,
                                displayName: user.displayName,
                                photoURL: user.photoURL,
                                appId: nil,
                                isAnonymous: false)
        let result = AuthResult(user: authUser, isNewUser: isNewAccount, provider: .google)
        return result
    }

    public func upgradeToGoogle(idToken: String, accessToken: String) async throws -> AuthResult {
        do {
            let credential = GoogleAuthProvider.credential(
                withIDToken: idToken,
                accessToken: accessToken
            )
            let user = try await upgradeWithCredential(credential)
            let authUser = AuthUser(uid: user.uid,
                                    email: user.email,
                                    displayName: user.displayName,
                                    photoURL: user.photoURL,
                                    appId: nil,
                                    isAnonymous: false)
            let result = AuthResult(user: authUser, isNewUser: true, provider: .google)
            return result
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
    
    public func signIn(email: String, password: String) async throws -> AuthResult {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        print("Auth result after sign in ", authResult)
        let authUser = AuthUser(uid: authResult.user.uid,
                                email: authResult.user.email,
                                displayName: authResult.user.displayName,
                                photoURL: authResult.user.photoURL,
                                appId: nil,
                                isAnonymous: false)
        
        let result = AuthResult(user: authUser, isNewUser: true, provider: .google)
        return result
    }
    
    public func createAccount(email: String, password: String) async throws -> AuthResult {
        let credential = EmailAuthProvider.credential(withEmail: email, password: password)
        let user = try await upgradeWithCredential(credential)
        let authUser = AuthUser(uid: user.uid,
                                email: user.email,
                                displayName: user.displayName,
                                photoURL: user.photoURL,
                                appId: nil,
                                isAnonymous: false)
        
        let result = AuthResult(user: authUser, isNewUser: true, provider: .google)
        return result
    }
    
    public func signInWithCredential(_ credential: AuthCredential) async throws -> (AuthUser, Bool) {
        let authDataResult = try await Auth.auth().signIn(with: credential)
        print("auth data result email - ", authDataResult.user.email)
        print("auth data result name - ", authDataResult.user.displayName)
        print("auth data result id -", authDataResult.user.uid)
        print("계정 초기 정보", authDataResult.additionalUserInfo)
        print("이거 새로운 계정인가요??", authDataResult.additionalUserInfo?.isNewUser)
        let isNewUser = authDataResult.additionalUserInfo?.isNewUser ?? false
        return (authDataResult.user.getAuthUser(), isNewUser)
    }
    
    public func upgradeWithCredential(_ credential: AuthCredential) async throws -> AuthUser {
        guard let currentUser = Auth.auth().currentUser else {
            throw URLError(.badServerResponse)
        }
        let authDataResult = try await currentUser.link(with: credential)
        print("auth data result email - ", authDataResult.user.email)
        print("auth data result name - ", authDataResult.user.displayName)
        print("auth data result id -", authDataResult.user.uid)
        print("계정 초기 정보", authDataResult.additionalUserInfo)
        print("이거 새로운 계정인가요??", authDataResult.additionalUserInfo?.isNewUser)
        
        return authDataResult.user.getAuthUser()
    }
    
    public func sendResetPasswordEmail(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }

    public func upgradeToApple(idToken: String, nonce: String) async throws -> AuthUser {
        // ✅ Apple fullName은 Firebase credential에 직접 넣을 수 있는 API가 일관적이지 않아서
        // 여기서는 idToken + nonce만으로 credential 생성(표준 방식)
        let credential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: idToken,
            rawNonce: nonce,
            accessToken: nil
        )
        print("credential", credential)
        do {
            // 1) 익명 -> link
            let user = try await upgradeWithCredential(credential)
            return user
        } catch {
            // 2) "이미 다른 계정이 이 credential을 가지고 있음"이면 sign-in으로 fallback
            let nsError = error as NSError
            let code = AuthErrorCode(rawValue: nsError.code)

            switch code {
            case .emailAlreadyInUse, .credentialAlreadyInUse, .accountExistsWithDifferentCredential:
                print("이미 있는 계정이라 sign-in으로 fallback")
                let (user, _) = try await signInWithCredential(credential)
                return user
            default:
                throw error
            }
        }
    }

    public func signInWithApple(idToken: String, nonce: String) async throws -> AuthUser {
        let credential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: idToken,
            rawNonce: nonce,
            accessToken: nil
        )
        let (user, _) = try await signInWithCredential(credential)
        return user
    }
}
