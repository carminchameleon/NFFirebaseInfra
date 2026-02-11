//
//  AuthModels.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 3/2/2026.
//

import Foundation
import FirebaseAuth
/// ✅ 앱이 FirebaseAuth.User를 직접 다루지 않게 하기 위한 래퍼
/// - 패키지 바깥(앱)은 FirebaseAuth를 import할 필요가 없어짐
public struct AuthUser: Sendable {
    public let uid: String
    public let email: String?
    public let displayName: String?
    public let photoURL: URL?
    public let appId: String?
    public let isAnonymous: Bool

    public init(uid: String, email: String?, displayName: String?, photoURL: URL?, appId: String?, isAnonymous: Bool) {
        self.uid = uid
        self.email = email
        self.displayName = displayName
        self.photoURL = photoURL
        self.appId = appId
        self.isAnonymous = isAnonymous
    }
}

extension User {
    public func getAuthUser(appId: String? = nil) -> AuthUser {
        return AuthUser(
            uid: uid,
            email: email,
            displayName: displayName,
            photoURL: photoURL,
            appId: appId,
            isAnonymous: isAnonymous
        )
    }
}

public enum AuthProvider: String, Sendable {
    case anonymous
    case apple
    case google
    case email
}

public struct AuthResult: Sendable {
    public let user: AuthUser
    public let isNewUser: Bool
    public let provider: AuthProvider

    public init(user: AuthUser, isNewUser: Bool, provider: AuthProvider) {
        self.user = user
        self.isNewUser = isNewUser
        self.provider = provider
    }
    
    public static var mockData: AuthResult {
        return AuthResult(user: AuthUser(uid: "", email: nil, displayName: nil, photoURL: nil, appId: nil, isAnonymous: true), isNewUser: false, provider: .anonymous)
    }
    
    
}
