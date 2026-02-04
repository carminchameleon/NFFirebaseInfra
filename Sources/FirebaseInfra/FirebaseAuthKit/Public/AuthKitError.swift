//
//  AuthKitErro.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 3/2/2026.
//

import Foundation

public enum AuthKitError: Error, LocalizedError {
    case presenterNotConfigured
    case presenterNotFound
    case tokenMissing(String)
    case invalidState(String)
    case userCancelled

    public var errorDescription: String? {
        switch self {
        case .presenterNotConfigured:
            return "Presenter is not configured."
        case .presenterNotFound:
            return "Unable to find a presenter view controller."
        case .tokenMissing(let msg):
            return msg
        case .invalidState(let msg):
            return msg
        case .userCancelled:
            return "User cancelled sign-in."
        }
    }
}
