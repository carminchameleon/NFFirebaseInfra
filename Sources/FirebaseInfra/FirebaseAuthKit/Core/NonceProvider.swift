//
//  File.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 3/2/2026.
//

import Foundation
import CryptoKit
//
//final public class NonceProvider {
//    func makeRawNonce() -> String {
//        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
//        return String((0..<32).compactMap { _ in charset.randomElement() })
//    }
//
//    func sha256(_ input: String) -> String {
//        let hashed = SHA256.hash(data: Data(input.utf8))
//        return hashed.map { String(format: "%02x", $0) }.joined()
//    }
//}

/// nonce 생성/sha256은 보통 AuthKit에서 같이 둠 (이미 너 NonceProvider 갖고 있어서 그대로 쓰면 됨)
public protocol NonceProvider: Sendable {
    func makeRawNonce() -> String
    func sha256(_ input: String) -> String
}

import Foundation
import CryptoKit

public struct DefaultNonceProvider: NonceProvider {
    public init() {}

    public func makeRawNonce() -> String {
        let charset = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        return String((0..<32).compactMap { _ in charset.randomElement() })
    }

    public func sha256(_ input: String) -> String {
        let data = Data(input.utf8)
        let hashed = SHA256.hash(data: data)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}
