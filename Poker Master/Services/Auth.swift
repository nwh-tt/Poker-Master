import Foundation
import DeviceCheck

struct AuthRequest: Codable {
    let device_id: String
}

struct AuthResponse: Codable {
    let access_token: String
    let token_type: String
}


class JWTCache {
    static let shared = JWTCache()
    private init() {}

    private var token: String?
    private var expiration: Date?
    private var isFetching = false
    private var pendingCompletions: [(String?) -> Void] = []
    
    func getDeviceToken(completion: @escaping (Data?) -> Void) {
        #if targetEnvironment(simulator)
        // Simulator: return a mock token
        let mockToken = "simulator-mock-token".data(using: .utf8)
        completion(mockToken)
        #else
        // Real device: generate Apple-verified token
        DCDevice.current.generateToken { data, error in
            if let error = error {
                print("Error generating device token: \(error)")
                completion(nil)
                return
            }
            completion(data) // Apple-verified device token
        }
        #endif
    }

    // Returns a valid token, fetching a new one if needed
    func getToken(completion: @escaping (String?) -> Void) {
        if let token = token, let expiration = expiration, expiration > Date() {
            // Token is valid
            completion(token)
            return
        }

        // If a fetch is already in progress, append the completion to pending list
        if isFetching {
            pendingCompletions.append(completion)
            return
        }

        isFetching = true
        pendingCompletions.append(completion)
        // Get Apple device token
                getDeviceToken { deviceTokenData in
                    guard let deviceTokenData = deviceTokenData else {
                        self.isFetching = false
                        self.pendingCompletions.forEach { $0(nil) }
                        self.pendingCompletions.removeAll()
                        return
                    }

                    let deviceTokenString = deviceTokenData.base64EncodedString()

                    // Fetch new JWT from backend
                    self.fetchJWT(deviceId: deviceTokenString) { newToken in
                        self.isFetching = false
                        self.token = newToken
                        if let newToken = newToken {
                            self.expiration = self.decodeExpiration(from: newToken)
                        }

                        // Call all pending completions
                        self.pendingCompletions.forEach { $0(newToken) }
                        self.pendingCompletions.removeAll()
                    }
                }
    }

    private func fetchJWT(deviceId: String, completion: @escaping (String?) -> Void) {
        guard let url = URL(string: "\(apiPrefix)/api/auth/token") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        let body = ["device_id": deviceId]

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            print("Error encoding body: \(error)")
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, _, error in
            guard let data = data, error == nil else {
                print("Request error: \(String(describing: error))")
                completion(nil)
                return
            }

            do {
                let response = try JSONDecoder().decode(AuthResponse.self, from: data)
                completion(response.access_token)
            } catch {
                print("Decoding error: \(error)")
                completion(nil)
            }
        }.resume()
    }

    private func decodeExpiration(from jwt: String) -> Date? {
        let segments = jwt.split(separator: ".")
        guard segments.count == 3 else { return nil }

        let payloadSegment = segments[1]
        var base64 = String(payloadSegment)
            .replacingOccurrences(of: "-", with: "+")
            .replacingOccurrences(of: "_", with: "/")
        while base64.count % 4 != 0 { base64 += "=" }

        guard let data = Data(base64Encoded: base64),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let exp = json["exp"] as? TimeInterval
        else { return nil }

        return Date(timeIntervalSince1970: exp)
    }
}
