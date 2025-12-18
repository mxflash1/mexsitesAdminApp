import Foundation

// Client configuration model
struct ClientConfig: Codable {
    let clientId: String
    let clientName: String
    let firebaseConfig: FirebaseProjectConfig
    
    struct FirebaseProjectConfig: Codable {
        let apiKey: String
        let projectId: String
        let storageBucket: String
        let messagingSenderId: String
        let appId: String
        let databaseURL: String?
    }
}

// Store for managing client configurations
class ClientConfigStore {
    static let shared = ClientConfigStore()
    
    private let configs: [String: ClientConfig] = [
        // MexiCuts configuration (your first client)
        "mexicuts": ClientConfig(
            clientId: "mexicuts",
            clientName: "MexiCuts",
            firebaseConfig: ClientConfig.FirebaseProjectConfig(
                apiKey: "AIzaSyDZCOSHTqoDXJ4Ki84_-28kFh4cGbUNsEM",
                projectId: "mexicuts-booking",
                storageBucket: "mexicuts-booking.firebasestorage.app",
                messagingSenderId: "738836577452",
                appId: "1:738836577452:ios:59420d6889ae105041b309",
                databaseURL: nil
            )
        )
        // Add more clients as you onboard them
    ]
    
    func getConfig(for clientId: String) -> ClientConfig? {
        return configs[clientId]
    }
    
    func getConfigForCredentials(username: String, password: String) async throws -> ClientConfig {
        print("🔍 Looking for config with username: \(username)")
        
        // Example: username format could be "mexicuts_admin" 
        let clientId = username.components(separatedBy: "_").first?.lowercased() ?? ""
        print("🔍 Extracted clientId: \(clientId)")
        
        guard let config = getConfig(for: clientId) else {
            print("❌ No config found for clientId: \(clientId)")
            throw NSError(domain: "ClientConfigStore", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Client configuration not found for '\(clientId)'"])
        }
        
        print("✅ Found config for: \(config.clientName)")
        
        // Validate password
        guard await validateCredentials(clientId: clientId, username: username, password: password) else {
            print("❌ Password validation failed")
            throw NSError(domain: "ClientConfigStore", code: -1,
                        userInfo: [NSLocalizedDescriptionKey: "Invalid username or password"])
        }
        
        print("✅ Credentials validated successfully")
        return config
    }
    
    private func validateCredentials(clientId: String, username: String, password: String) async -> Bool {
        print("🔐 Validating credentials:")
        print("   clientId: '\(clientId)'")
        print("   username: '\(username)'")
        print("   password length: \(password.count)")
        
        // For now, hardcoded for MexiCuts
        let expectedClientId = "mexicuts"
        let expectedUsername = "mexicuts_admin"
        let expectedPassword = "Martina2016."
        
        let clientIdMatch = clientId == expectedClientId
        let usernameMatch = username == expectedUsername
        let passwordMatch = password == expectedPassword
        
        print("   clientId match: \(clientIdMatch) (expected: '\(expectedClientId)')")
        print("   username match: \(usernameMatch) (expected: '\(expectedUsername)')")
        print("   password match: \(passwordMatch)")
        
        if clientIdMatch && usernameMatch && passwordMatch {
            print("✅ All credentials match!")
            return true
        }
        
        print("❌ Credentials don't match")
        return false
    }
}

