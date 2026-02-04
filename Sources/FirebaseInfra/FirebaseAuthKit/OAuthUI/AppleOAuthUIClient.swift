//
//  SwiftUIView.swift
//  FirebaseInfra
//
//  Created by Eunji Hwang on 3/2/2026.
//

import UIKit
import AuthenticationServices

public struct AppleOAuthPayload: Sendable {
    public let idTokenString: String
    public let rawNonce: String
    public let email: String?
    public let fullName: PersonNameComponents?
    public let appleUserId: String

    public init(
        idTokenString: String,
        rawNonce: String,
        email: String?,
        fullName: PersonNameComponents?,
        appleUserId: String
    ) {
        self.idTokenString = idTokenString
        self.rawNonce = rawNonce
        self.email = email
        self.fullName = fullName
        self.appleUserId = appleUserId
    }
}


/// UI를 띄우는 건 MainActor에서만 안전하다.
@MainActor
public final class AppleOAuthUIClient: NSObject {

    private let nonceProvider: NonceProvider

    /// ✅ presenterProvider는 “UI를 어디 위에 띄울지” 제공하는 클로저
    /// - 이건 UI 책임이므로 AuthService/FirebaseAuthService에 있으면 안 됨.
    private var presenterProvider: (@MainActor () -> UIViewController?)?

    private var continuation: CheckedContinuation<AppleOAuthPayload, Error>?
    private var pendingRawNonce: String?

    public init(nonceProvider: NonceProvider) {
        self.nonceProvider = nonceProvider
    }

    /// 앱 시작 시 1번만 주입해두면, 이후 로그인 호출 시마다 presenter를 찾을 수 있음
    public func configurePresenter(_ presenter: @escaping @MainActor () -> UIViewController?) {
        self.presenterProvider = presenter
    }

    /// ✅ Apple 로그인 UI를 띄워서 토큰/nonce/email/name/userId를 가져온다.
    /// - 여기서 email/name은 최초 1회만 올 수도 있으므로, 상위(AuthKit)에서 Keychain에 저장하도록 설계.
    public func authorize() async throws -> AppleOAuthPayload {
        guard presenterProvider?() != nil else { throw AuthKitError.presenterNotConfigured }

        let rawNonce = nonceProvider.makeRawNonce()
        pendingRawNonce = rawNonce

        return try await withCheckedThrowingContinuation { cont in
            self.continuation = cont

            let request = ASAuthorizationAppleIDProvider().createRequest()
            request.requestedScopes = [.fullName, .email]
            request.nonce = nonceProvider.sha256(rawNonce)

            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            controller.performRequests()
        }
    }
}

@MainActor
extension AppleOAuthUIClient: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController,
                                        didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let cred = authorization.credential as? ASAuthorizationAppleIDCredential else { return }

        guard let tokenData = cred.identityToken else {
            continuation?.resume(throwing: AuthKitError.tokenMissing("Apple identityToken is missing."))
            continuation = nil
            return
        }

        guard let idTokenString = String(data: tokenData, encoding: .utf8) else {
            continuation?.resume(throwing: AuthKitError.tokenMissing("Unable to decode Apple token into String."))
            continuation = nil
            return
        }

        guard let rawNonce = pendingRawNonce else {
            continuation?.resume(throwing: AuthKitError.invalidState("Missing pending nonce state."))
            continuation = nil
            return
        }

        let payload = AppleOAuthPayload(
            idTokenString: idTokenString,
            rawNonce: rawNonce,
            email: cred.email,
            fullName: cred.fullName,
            appleUserId: cred.user
        )

        continuation?.resume(returning: payload)
        continuation = nil
    }

    public func authorizationController(controller: ASAuthorizationController,
                                        didCompleteWithError error: Error) {
        if let asErr = error as? ASAuthorizationError, asErr.code == .canceled {
            continuation?.resume(throwing: AuthKitError.userCancelled)
        } else {
            continuation?.resume(throwing: error)
        }
        continuation = nil
    }
}

@MainActor
extension AppleOAuthUIClient: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        presenterProvider?()?.view.window
        ?? UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap { $0.windows }
            .first(where: { $0.isKeyWindow })
        ?? ASPresentationAnchor()
    }
}
