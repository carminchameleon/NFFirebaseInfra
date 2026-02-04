//
//  AuthKit.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 3/2/2026.
//

import FirebaseAuth
import UIKit

@MainActor
public final class AuthKit {

    public static let shared = AuthKit(
        auth: FirebaseAuthService(),
        appleUI: AppleOAuthUIClient(nonceProvider: DefaultNonceProvider()),
        appleProfileStore: KeychainAppleStore()
    )

    private let auth: AppleAuthLinking
    private let appleUI: AppleOAuthUIClient
    private let appleProfileStore: AppleProfileStore

    public init(
        auth: AppleAuthLinking,
        appleUI: AppleOAuthUIClient,
        appleProfileStore: AppleProfileStore
    ) {
        self.auth = auth
        self.appleUI = appleUI
        self.appleProfileStore = appleProfileStore
    }

    /// ✅ 앱에서 딱 1번만 설정
    /// - presenterProvider를 AuthKit이 “소유”하지 않고, appleUI에게 전달만 한다.
    @MainActor
    public func configurePresenter(_ presenter: @escaping @MainActor () -> UIViewController?) {
        appleUI.configurePresenter(presenter)
    }

    // MARK: - Apple

    /// ✅ 익명 → Apple 연결(link) 시도
    /// - Apple UI로 토큰/nonce 받기 (MainActor)
    /// - email/name/userId는 다음에 nil일 수 있으니 Keychain에 저장(UX 유지)
    /// - FirebaseAuthService가 link 시도 + 중복이면 sign-in fallback 처리
    @MainActor
    public func upgradeAnonymousWithApple() async throws -> (User, Bool) {
        // 1) Apple UI 띄워 payload 확보
        let apple = try await appleUI.authorize()
        print("apple에서 주는 데이터 - email", apple.email)
        print("apple에서 주는 데이터 - fullname", apple.fullName?.familyName, apple.fullName?.givenName)
        print("apple에서 주는 데이터 - id token string", apple.idTokenString)
        print("apple에서 주는 데이터 - raw nonce", apple.rawNonce)
        
        // 2) Apple이 최초 1회만 주는 값을 저장해서 "다음 로그인 UX" 유지
        appleProfileStore.save(
            email: apple.email,
            fullName: (apple.fullName?.givenName ?? "") + (apple.fullName?.familyName ?? ""),
            appleUserId: apple.appleUserId
        )

        if apple.email == nil {
            print("새로운 가입이 아님. 이미 있는거 로그인")
        } else {
            print("새로운 가입임.")
            appleProfileStore.save(
                email: apple.email,
                fullName: (apple.fullName?.givenName ?? "") + (apple.fullName?.familyName ?? ""),
                appleUserId: apple.appleUserId
            )

        }
        
        // 3) Firebase(Infra)로 토큰/nonce만 전달 (UI 모르게)
        return try await auth.upgradeToApple(idToken: apple.idTokenString, nonce: apple.rawNonce)
    }

    
    @MainActor
    public func continueWithApple() async throws -> AuthResult {
        var isNewUser = false
        let apple = try await appleUI.authorize()
        
        print("apple에서 주는 데이터 - appleUserId", apple.appleUserId)
        print("apple에서 주는 데이터 - email", apple.email)
        print("apple에서 주는 데이터 - fullname", apple.fullName?.familyName, apple.fullName?.givenName)
        print("apple에서 주는 데이터 - id token string", apple.idTokenString)
        print("apple에서 주는 데이터 - raw nonce", apple.rawNonce)
        let displayName = (apple.fullName?.givenName ?? "") + " " + (apple.fullName?.familyName ?? "")
        let email = apple.email
        
        if email == nil {
            print("이미 있는 유저에요!!!")
            // 이미 있는 것
            let (user, _) = try await auth.signInWithApple(idToken: apple.idTokenString, nonce: apple.rawNonce)
            print("user", user.uid)
            print("email", user.email)
            let authUser = AuthUser(uid: user.uid,
                                    email: user.email,
                                    displayName: user.displayName,
                                    photoURL: user.photoURL,
                                    appId: nil,
                                    isAnonymous: false)
            return AuthResult(user: authUser, isNewUser: isNewUser, provider: .apple)
        } else {
            // 새로운 가입
            isNewUser = true
            print("이미 새로운 유저에요!!!", displayName)
            appleProfileStore.save(email: apple.email, fullName: displayName, appleUserId: apple.appleUserId)
            
            /// 애플  Link
            let (user, _) =  try await auth.upgradeToApple(idToken: apple.idTokenString, nonce: apple.rawNonce)
            let authUser = AuthUser(uid: user.uid,
                                    email: email,
                                    displayName: displayName.trimmingCharacters(in: .whitespacesAndNewlines),
                                    photoURL: nil,
                                    appId: apple.appleUserId,
                                    isAnonymous: false)
            
            print("auth user", authUser)
            return AuthResult(user: authUser, isNewUser: isNewUser, provider: .apple)
        }
    }
    /// ✅ 기존 Apple 계정으로 sign-in (익명 링크가 아니라 그냥 로그인)
    @MainActor
    public func signInWithApple() async throws -> AuthResult {
        let apple = try await appleUI.authorize()
        print("apple에서 주는 데이터 - appleUserId", apple.appleUserId)
        print("apple에서 주는 데이터 - email", apple.email)
        print("apple에서 주는 데이터 - fullname", apple.fullName?.familyName, apple.fullName?.givenName)
        print("apple에서 주는 데이터 - id token string", apple.idTokenString)
        print("apple에서 주는 데이터 - raw nonce", apple.rawNonce)
        
        let displayName = (apple.fullName?.givenName ?? "") + "" + (apple.fullName?.familyName ?? "")
        var isNewUser = false
        if apple.email == nil {
            print("새로운 가입이 아님. 이미 있는거 로그인")
        } else {
            print("새로운 가입임.")
            isNewUser = true
            appleProfileStore.save(
                email: apple.email,
                fullName: displayName,
                appleUserId: apple.appleUserId
            )
        }
        let (user, _) = try await auth.signInWithApple(idToken: apple.idTokenString, nonce: apple.rawNonce)
        
        let authUser = AuthUser(uid: user.uid,
                                email: user.email,
                                displayName: displayName,
                                photoURL: user.photoURL,
                                appId: apple.appleUserId,
                                isAnonymous: user.isAnonymous)
        return AuthResult(user: authUser, isNewUser: isNewUser, provider: .apple)
    }
}

