//
//  KeychainAppleStore.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 3/2/2026.
//

import SwiftKeychainWrapper
import Foundation

public protocol AppleProfileStore: Sendable {
    func save(email: String?, givenName: String?, appleUserId: String)
    func loadEmail() -> String?
    func loadGivenName() -> String?
    func loadAppleUserId() -> String?
}

/// ✅ 왜 Keychain을 쓰나?
/// - Apple은 최초 1회만 email/fullName을 줄 수 있음.
/// - 다음 로그인에는 `cred.email`, `cred.fullName`이 nil인 경우가 많아.
/// - 그래서 "환영 문구/프로필 초기값" 같은 UX를 유지하려면 로컬에 저장해두는 게 좋음.
/// - Keychain은 앱 삭제/재설치 전까지 비교적 안전하게 유지됨(일반 UserDefaults보다 적합).
///
/// ✅ 유저 베네핏
/// - 다음에 다시 들어왔을 때 "이름이 비어있는" 어색한 경험 감소
/// - 계정 복구/고객지원 상황에서 appleUserId(=Apple의 stable user identifier)를 참고 가능
public struct KeychainAppleStore: AppleProfileStore {
    public init() {}

    private enum Keys {
        static let email = "appleSignInEmail"
        static let givenName = "appleSignInGivenName"
        static let userId = "appleSignInIdentifier"
    }

    public func save(email: String?, givenName: String?, appleUserId: String) {
        // nil이면 저장 안 하거나, 기존 값 유지하고 싶으면 조건으로 제어 가능
        if let email { KeychainWrapper.standard.set(email, forKey: Keys.email) }
        if let givenName { KeychainWrapper.standard.set(givenName, forKey: Keys.givenName) }
        KeychainWrapper.standard.set(appleUserId, forKey: Keys.userId)
    }

    public func loadEmail() -> String? { KeychainWrapper.standard.string(forKey: Keys.email) }
    public func loadGivenName() -> String? { KeychainWrapper.standard.string(forKey: Keys.givenName) }
    public func loadAppleUserId() -> String? { KeychainWrapper.standard.string(forKey: Keys.userId) }
}
