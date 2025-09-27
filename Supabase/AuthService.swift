import AuthenticationServices
import CryptoKit
import Foundation
import Security
import Supabase
import UIKit

@MainActor
final class AuthService: NSObject {
    static func shared(bundle: Bundle = .main) throws -> AuthService {
        let client = try SupabaseClientProvider.client(bundle: bundle)
        return AuthService(client: client)
    }

    private let client: SupabaseClient
    private var appleCoordinator: AppleSignInCoordinator?
    private var oauthPresentationProvider: WebAuthenticationPresentationProvider?

    init(client: SupabaseClient) {
        self.client = client
        super.init()
    }

    // MARK: - Public API

    func currentUserId() -> UUID? {
        client.auth.currentUser?.id
    }

    func signInWithEmail(email: String, password: String) async throws -> UUID {
        let session = try await client.auth.signIn(email: email, password: password)
        return session.user.id
    }

    func signInWithApple() async throws -> UUID {
        let anchor = try resolvePresentationAnchor()
        return try await signInWithApple(presentationAnchor: anchor)
    }

    func signInWithGoogle() async throws -> UUID {
        let anchor = try resolvePresentationAnchor()
        return try await signInWithGoogle(presentationAnchor: anchor)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    // MARK: - Internal helpers

    func signInWithApple(presentationAnchor: ASPresentationAnchor) async throws -> UUID {
        let nonce = randomNonceString()
        let request = ASAuthorizationAppleIDProvider().createRequest()
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)

        let coordinator = AppleSignInCoordinator(
            client: client,
            nonce: nonce,
            presentationAnchor: presentationAnchor
        )
        appleCoordinator = coordinator
        defer { appleCoordinator = nil }

        return try await coordinator.perform(request: request)
    }

    func signInWithGoogle(presentationAnchor: ASPresentationAnchor) async throws -> UUID {
        guard SupabaseClientProvider.redirectURL != nil else {
            throw AuthServiceError.missingRedirectURL
        }

        let provider = WebAuthenticationPresentationProvider(anchor: presentationAnchor)
        oauthPresentationProvider = provider
        defer { oauthPresentationProvider = nil }

        let session = try await client.auth.signInWithOAuth(provider: .google) { webSession in
            webSession.presentationContextProvider = provider
            webSession.prefersEphemeralWebBrowserSession = true
        }

        return session.user.id
    }
}

// MARK: - Presentation helpers

private extension AuthService {
    func resolvePresentationAnchor() throws -> ASPresentationAnchor {
        #if canImport(UIKit)
        guard
            let windowScene = UIApplication.shared.connectedScenes
                .compactMap({ $0 as? UIWindowScene })
                .first(where: { $0.activationState == .foregroundActive }),
            let window = windowScene.windows.first(where: { $0.isKeyWindow })
        else {
            throw AuthServiceError.presentationAnchorUnavailable
        }

        return window
        #else
        throw AuthServiceError.presentationAnchorUnavailable
        #endif
    }

    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms = [UInt8](repeating: 0, count: 16)
            let status = SecRandomCopyBytes(kSecRandomDefault, randoms.count, &randoms)
            if status != errSecSuccess {
                fatalError("Unable to generate nonce. SecRandomCopyBytes failed with status \(status)")
            }

            randoms.forEach { random in
                if remainingLength == 0 {
                    return
                }

                if random < charset.count {
                    result.append(charset[Int(random)])
                    remainingLength -= 1
                }
            }
        }

        return result
    }

    func sha256(_ input: String) -> String {
        let inputData = Data(input.utf8)
        let hashed = SHA256.hash(data: inputData)
        return hashed.map { String(format: "%02x", $0) }.joined()
    }
}

// MARK: - Errors

enum AuthServiceError: LocalizedError {
    case presentationAnchorUnavailable
    case invalidAppleIdentityToken
    case missingRedirectURL

    var errorDescription: String? {
        switch self {
        case .presentationAnchorUnavailable:
            return "Unable to determine a window to present authentication UI."
        case .invalidAppleIdentityToken:
            return "The identity token returned by Sign in with Apple is invalid."
        case .missingRedirectURL:
            return "Provide SUPABASE_REDIRECT_URL in Info.plist to enable OAuth sign-in flows."
        }
    }
}

// MARK: - Coordinators

private final class AppleSignInCoordinator: NSObject {
    private let client: SupabaseClient
    private let nonce: String
    private let presentationAnchor: ASPresentationAnchor
    private var continuation: CheckedContinuation<UUID, Error>?
    private var controller: ASAuthorizationController?

    init(client: SupabaseClient, nonce: String, presentationAnchor: ASPresentationAnchor) {
        self.client = client
        self.nonce = nonce
        self.presentationAnchor = presentationAnchor
    }

    func perform(request: ASAuthorizationAppleIDRequest) async throws -> UUID {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let controller = ASAuthorizationController(authorizationRequests: [request])
            controller.delegate = self
            controller.presentationContextProvider = self
            self.controller = controller
            controller.performRequests()
        }
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerDelegate {
    func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        guard let credential = authorization.credential as? ASAuthorizationAppleIDCredential else {
            continuation?.resume(throwing: AuthServiceError.invalidAppleIdentityToken)
            cleanup()
            return
        }

        guard let identityToken = credential.identityToken, let token = String(data: identityToken, encoding: .utf8) else {
            continuation?.resume(throwing: AuthServiceError.invalidAppleIdentityToken)
            cleanup()
            return
        }

        Task {
            do {
                let session = try await client.auth.signInWithIdToken(
                    credentials: .init(provider: .apple, idToken: token, nonce: nonce)
                )
                continuation?.resume(returning: session.user.id)
            } catch {
                continuation?.resume(throwing: error)
            }
            cleanup()
        }
    }

    func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: Error) {
        continuation?.resume(throwing: error)
        cleanup()
    }
}

extension AppleSignInCoordinator: ASAuthorizationControllerPresentationContextProviding {
    func presentationAnchor(for _: ASAuthorizationController) -> ASPresentationAnchor {
        presentationAnchor
    }
}

private extension AppleSignInCoordinator {
    func cleanup() {
        continuation = nil
        controller?.delegate = nil
        controller?.presentationContextProvider = nil
        controller = nil
    }
}

private final class WebAuthenticationPresentationProvider: NSObject, ASWebAuthenticationPresentationContextProviding {
    private let anchor: ASPresentationAnchor

    init(anchor: ASPresentationAnchor) {
        self.anchor = anchor
    }

    func presentationAnchor(for _: ASWebAuthenticationSession) -> ASPresentationAnchor {
        anchor
    }
}
