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

        // 2) Apple이 최초 1회만 주는 값을 저장해서 "다음 로그인 UX" 유지
        appleProfileStore.save(
            email: apple.email,
            givenName: apple.fullName?.givenName,
            appleUserId: apple.appleUserId
        )

        // 3) Firebase(Infra)로 토큰/nonce만 전달 (UI 모르게)
        return try await auth.upgradeToApple(idToken: apple.idTokenString, nonce: apple.rawNonce)
    }

    /// ✅ 기존 Apple 계정으로 sign-in (익명 링크가 아니라 그냥 로그인)
    @MainActor
    public func signInWithApple() async throws -> (User, Bool) {
        let apple = try await appleUI.authorize()

        // sign-in 시에도 email/fullName이 nil일 수 있으니
        // userId는 항상 주므로 업데이트 용도로 저장해둘 수 있음
        appleProfileStore.save(
            email: apple.email,
            givenName: apple.fullName?.givenName,
            appleUserId: apple.appleUserId
        )

        return try await auth.signInWithApple(idToken: apple.idTokenString, nonce: apple.rawNonce)
    }
}

