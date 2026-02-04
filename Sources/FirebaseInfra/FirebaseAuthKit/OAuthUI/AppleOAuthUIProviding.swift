//
//  File.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 3/2/2026.
//

import Foundation

@MainActor
public protocol AppleOAuthUIProviding {
    func authorize() async throws -> (idToken: String, nonce: String)
}
