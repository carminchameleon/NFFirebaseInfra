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
    func upgradeToApple(idToken: String, nonce: String) async throws -> (User, Bool)

    /// 기존 Apple 계정으로 sign-in
    func signInWithApple(idToken: String, nonce: String) async throws -> (User, Bool)
}


public final class FirebaseAuthService: AuthServiceProtocol, AppleAuthLinking {
   
    
    
    // Presenter 주입(앱에서 1번만)
//    private var presenterProvider: (() -> UIViewController?)?

    // 내부 구성 요소
//    private let nonceProvider = NonceProvider()
//    private let keychainStore = KeychainAppleStore()
//    
    public init() {}
//    private let appleUI: AppleOAuthUIProviding
//    private lazy var appleUI = AppleOAuthUIClient(nonceProvider: nonceProvider)

//    @MainActor
//    public func configurePresenter(_ presenter: @escaping @MainActor () -> UIViewController?) {
//        (appleUI as? (any PresenterConfigurable))?.configurePresenter(presenter)
//
////          self.appleUI.configurePresenter(presenter)  // Apple UI도 같은 presenter 사용
//      }
    
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

//
//    // MARK: - Apple
//       public func upgradeAnonymousWithApple() async throws -> (User, Bool) {
//           guard presenterProvider != nil else { throw AuthKitError.presenterNotConfigured }
//
//           // 1) Apple UI로 토큰/nonce/email/name 가져오기
//           let apple = try await appleUI.authorize()
//
//           // 2) Apple email/name은 다음에 안 줄 수도 있으니 저장 (유저 UX 유지 목적)
//           keychainStore.save(email: apple.email, givenName: apple.fullName?.givenName, appleUserId: apple.appleUserId)
//
//           // 3) 익명→link 시도. 중복이면 sign-in fallback (정책은 FirebaseAuthService 내부)
//           
//           let credential = OAuthProvider.appleCredential(withIDToken: apple.idTokenString,
//                                                          rawNonce: apple.rawNonce,
//                                                          fullName: apple.fullName)
//           do {
//               let user = try await upgradeWithCredential(credential)
//               
//               return (user, true)
//           } catch {
//               let nsError = error as NSError
//               let code = AuthErrorCode(rawValue: nsError.code)
//               
//               switch code {
//               case .emailAlreadyInUse,
//                       .credentialAlreadyInUse,
//                       .accountExistsWithDifferentCredential:
//                   print("이미 있는 유저라 sign in 으로 진행")
//                   let result = try await self.signInWithCredential(credential)
//                   return result
//               default:
//                   throw error
//               }
//               
//           }
//       }
//    
//    @MainActor
//    public func signInWithApple() async throws -> (User, Bool) {
//        guard presenterProvider != nil else { throw AuthKitError.presenterNotConfigured }
//
//        let apple = try await appleUI.authorize()
//        let credential = OAuthProvider.appleCredential(withIDToken: apple.idTokenString,
//                                                       rawNonce: apple.rawNonce,
//                                                       fullName: apple.fullName)
//        let result = try await self.signInWithCredential(credential)
//        return result
//   }
}


extension FirebaseAuthService {

    public func upgradeToApple(idToken: String, nonce: String) async throws -> (User, Bool) {
        // ✅ Apple fullName은 Firebase credential에 직접 넣을 수 있는 API가 일관적이지 않아서
        // 여기서는 idToken + nonce만으로 credential 생성(표준 방식)
        let credential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: idToken,
            rawNonce: nonce,
            accessToken: nil
        )

        do {
            // 1) 익명 -> link
            let user = try await upgradeWithCredential(credential)
            // link가 성공했다는 의미에서 true
            return (user, true)
        } catch {
            // 2) "이미 다른 계정이 이 credential을 가지고 있음"이면 sign-in으로 fallback
            let nsError = error as NSError
            let code = AuthErrorCode(rawValue: nsError.code)

            switch code {
            case .emailAlreadyInUse, .credentialAlreadyInUse, .accountExistsWithDifferentCredential:
                return try await signInWithCredential(credential)
            default:
                throw error
            }
        }
    }

    public func signInWithApple(idToken: String, nonce: String) async throws -> (User, Bool) {
        let credential = OAuthProvider.credential(
            providerID: AuthProviderID.apple,
            idToken: idToken,
            rawNonce: nonce,
            accessToken: nil
        )
        return try await signInWithCredential(credential)
    }
}
