import Foundation
import AuthenticationServices
import CryptoKit
import Security
import Supabase

@MainActor
final class AuthManager: NSObject, ObservableObject {
    @Published private(set) var session: Session?
    @Published private(set) var user: User?
    @Published private(set) var userId: UUID?
    @Published var lastError: Error?
    @Published var emailMagicLinkSent = false

    private let client: SupabaseClient?
    private var authStateTask: Task<Void, Never>?
    private var currentNonce: String?

    init(client: SupabaseClient?) {
        self.client = client
        super.init()
        if let client {
            authStateTask = Task { await listenForAuthChanges(client: client) }
            Task { await refreshSession(client: client) }
        }
    }

    deinit {
        authStateTask?.cancel()
    }

    func prepareAppleRequest(_ request: ASAuthorizationAppleIDRequest) {
        let nonce = randomNonceString()
        currentNonce = nonce
        request.requestedScopes = [.fullName, .email]
        request.nonce = sha256(nonce)
    }

    func handleAppleCompletion(_ result: Result<ASAuthorization, Error>) async {
        switch result {
        case .failure(let error):
            self.lastError = error
        case .success(let authorization):
            guard let client else {
                lastError = NSError(
                    domain: "Auth",
                    code: -3,
                    userInfo: [NSLocalizedDescriptionKey: "Supabase client unavailable in preview mode."]
                )
                return
            }
            guard let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential else { return }
            guard let identityToken = appleIDCredential.identityToken,
                  let token = String(data: identityToken, encoding: .utf8) else {
                self.lastError = NSError(domain: "Auth", code: -1)
                return
            }
            do {
                _ = try await client.auth.signInWithIdToken(
                    credentials: .init(provider: .apple, idToken: token, nonce: currentNonce ?? "")
                )
            } catch {
                self.lastError = error
            }
        }
    }

    func sendMagicLink(to email: String) async {
        emailMagicLinkSent = false
        guard let client else {
            lastError = NSError(
                domain: "Auth",
                code: -2,
                userInfo: [NSLocalizedDescriptionKey: "Supabase client unavailable in preview mode."]
            )
            return
        }
        do {
            try await client.auth.signInWithOTP(email: email, redirectTo: nil)
            emailMagicLinkSent = true
        } catch {
            lastError = error
        }
    }

    func signOut() async {
        guard let client else { return }
        do {
            try await client.auth.signOut()
            session = nil
            user = nil
            userId = nil
        } catch {
            lastError = error
        }
    }

    private func refreshSession(client: SupabaseClient) async {
        do {
            let session = try await client.auth.session
            self.session = session
            self.user = session.user
            self.userId = session.user.id
        } catch {
            lastError = error
        }
    }

    private func listenForAuthChanges(client: SupabaseClient) async {
        for await change in client.auth.authStateChanges {
            switch change.event {
            case .signedIn, .initialSession, .tokenRefreshed:
                if let session = change.session {
                    self.session = session
                    self.user = session.user
                    self.userId = session.user.id
                }
            case .signedOut:
                self.session = nil
                self.user = nil
                self.userId = nil
            default:
                break
            }
        }
    }
}

private extension AuthManager {
    func randomNonceString(length: Int = 32) -> String {
        precondition(length > 0)
        let charset: [Character] = Array("0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._")
        var result = ""
        var remainingLength = length

        while remainingLength > 0 {
            var randoms: [UInt8] = []
            randoms.reserveCapacity(16)
            for _ in 0..<16 {
                var random: UInt8 = 0
                let status = SecRandomCopyBytes(kSecRandomDefault, 1, &random)
                if status == errSecSuccess {
                    randoms.append(random)
                }
            }

            randoms.forEach { random in
                if remainingLength == 0 { return }
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
        return hashed.compactMap { String(format: "%02x", $0) }.joined()
    }
}
