//
//  AppleAuthLinking.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 3/2/2026.
//

import FirebaseAuth
//
//public protocol AppleAuthLinking: Sendable {
//    /// 익명 유저를 Apple로 "연결(link)" 시도.
//    /// - 실패가 "이미 다른 계정에 연결된 credential"이면 sign-in으로 fallback.
//    /// - 반환 Bool은 (내 앱 관점에서) “link 성공(=새로 연결)”이면 true, fallback sign-in이면 Firebase의 isNewUser를 반환.
//    func upgradeToApple(idToken: String, nonce: String) async throws -> (User, Bool)
//
//    /// 기존 Apple 계정으로 sign-in
//    func signInWithApple(idToken: String, nonce: String) async throws -> (User, Bool)
//}
