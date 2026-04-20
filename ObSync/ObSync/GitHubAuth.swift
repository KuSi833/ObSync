import Foundation
import AuthenticationServices

enum GitHubAuth {
    static let clientID = BuildConfig.githubClientId
    static let clientSecret = BuildConfig.githubClientSecret
    static let redirectURI = "obsync://auth"
    static let scope = "repo"

    // MARK: - OAuth Redirect Flow

    /// Opens GitHub login in a secure browser session and returns the access token.
    @MainActor
    static func authenticate() async throws -> String {
        let code = try await requestAuthorizationCode()
        return try await exchangeCodeForToken(code)
    }

    /// Step 1: Open GitHub authorization page, get back an authorization code.
    @MainActor
    private static func requestAuthorizationCode() async throws -> String {
        let urlString = "https://github.com/login/oauth/authorize"
            + "?client_id=\(clientID)"
            + "&redirect_uri=\(redirectURI)"
            + "&scope=\(scope)"

        guard let url = URL(string: urlString) else {
            throw AuthError.unknown("Invalid authorization URL")
        }

        return try await withCheckedThrowingContinuation { continuation in
            let session = ASWebAuthenticationSession(
                url: url,
                callbackURLScheme: "obsync"
            ) { callbackURL, error in
                if let error {
                    if (error as NSError).code == ASWebAuthenticationSessionError.canceledLogin.rawValue {
                        continuation.resume(throwing: AuthError.denied)
                    } else {
                        continuation.resume(throwing: AuthError.unknown(error.localizedDescription))
                    }
                    return
                }

                guard let callbackURL,
                      let components = URLComponents(url: callbackURL, resolvingAgainstBaseURL: false),
                      let code = components.queryItems?.first(where: { $0.name == "code" })?.value
                else {
                    continuation.resume(throwing: AuthError.unknown("No authorization code received"))
                    return
                }

                continuation.resume(returning: code)
            }

            session.prefersEphemeralWebBrowserSession = false
            session.presentationContextProvider = AuthPresentationContext.shared
            session.start()
        }
    }

    /// Step 2: Exchange the authorization code for an access token.
    private static func exchangeCodeForToken(_ code: String) async throws -> String {
        var request = URLRequest(url: URL(string: "https://github.com/login/oauth/access_token")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        request.setValue("application/x-www-form-urlencoded", forHTTPHeaderField: "Content-Type")

        let body = "client_id=\(clientID)&client_secret=\(clientSecret)&code=\(code)&redirect_uri=\(redirectURI)"
        request.httpBody = body.data(using: .utf8)

        let (data, _) = try await URLSession.shared.data(for: request)
        let response = try JSONDecoder().decode(TokenResponse.self, from: data)

        guard let token = response.access_token else {
            throw AuthError.unknown(response.error ?? "Token exchange failed")
        }

        return token
    }

    // MARK: - Response Types

    private struct TokenResponse: Decodable {
        let access_token: String?
        let token_type: String?
        let scope: String?
        let error: String?
    }

    // MARK: - User

    struct User: Decodable {
        let login: String
    }

    static func fetchUser(token: String) async throws -> User {
        var request = URLRequest(url: URL(string: "https://api.github.com/user")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode(User.self, from: data)
    }

    // MARK: - Repos

    struct Repo: Decodable, Identifiable, Hashable {
        let id: Int
        let full_name: String
        let `private`: Bool
        let default_branch: String
    }

    struct Branch: Decodable, Identifiable, Hashable {
        let name: String
        var id: String { name }
    }

    static func fetchBranches(repo: String, token: String) async throws -> [Branch] {
        var request = URLRequest(url: URL(string: "https://api.github.com/repos/\(repo)/branches?per_page=100")!)
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")
        let (data, _) = try await URLSession.shared.data(for: request)
        return try JSONDecoder().decode([Branch].self, from: data)
    }

    static func fetchRepos(token: String) async throws -> [Repo] {
        var allRepos: [Repo] = []
        var page = 1

        while true {
            var request = URLRequest(url: URL(string: "https://api.github.com/user/repos?per_page=100&page=\(page)&sort=updated")!)
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
            request.setValue("application/vnd.github+json", forHTTPHeaderField: "Accept")

            let (data, _) = try await URLSession.shared.data(for: request)
            let repos = try JSONDecoder().decode([Repo].self, from: data)
            if repos.isEmpty { break }
            allRepos.append(contentsOf: repos)
            if repos.count < 100 { break }
            page += 1
        }

        return allRepos
    }

    /// Build an authenticated HTTPS clone URL
    static func authenticatedURL(repo: String, token: String) -> URL? {
        URL(string: "https://x-access-token:\(token)@github.com/\(repo).git")
    }

    // MARK: - Keychain

    private static let keychainService = "com.obsync.github"
    private static let keychainAccount = "oauth-token"

    static func saveToken(_ token: String) {
        let data = Data(token.utf8)
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]
        SecItemDelete(query as CFDictionary)
        var add = query
        add[kSecValueData as String] = data
        SecItemAdd(add as CFDictionary, nil)
    }

    static func loadToken() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
            kSecReturnData as String: true,
        ]
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        guard status == errSecSuccess, let data = result as? Data else { return nil }
        return String(data: data, encoding: .utf8)
    }

    static func deleteToken() {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: keychainService,
            kSecAttrAccount as String: keychainAccount,
        ]
        SecItemDelete(query as CFDictionary)
    }

    // MARK: - Errors

    enum AuthError: LocalizedError {
        case expired
        case denied
        case unknown(String)

        var errorDescription: String? {
            switch self {
            case .expired: "Authorization expired. Please try again."
            case .denied: "Authorization cancelled."
            case .unknown(let msg): "Auth error: \(msg)"
            }
        }
    }
}

// MARK: - Presentation Context

private class AuthPresentationContext: NSObject, ASWebAuthenticationPresentationContextProviding {
    static let shared = AuthPresentationContext()

    func presentationAnchor(for session: ASWebAuthenticationSession) -> ASPresentationAnchor {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive }) else {
            return ASPresentationAnchor()
        }
        return scene.windows.first(where: \.isKeyWindow) ?? ASPresentationAnchor(windowScene: scene)
    }
}
