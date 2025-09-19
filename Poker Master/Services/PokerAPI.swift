import Foundation

struct EquityRequest: Codable {
    let hero_hole: [String]
    let villain_range: [String]
    let board: [String]
}

struct EquityRequestHand: Codable {
    let hero_hole: [String]
    let villain_hole: [String]
    let board: [String]
}

struct EquityResponse: Codable {
    let low_equity: Int
    let high_equity: Int
}

let apiPrefix = "https://pokermasterbackend-production.up.railway.app"
// let apiPrefix = "http://127.0.0.1:8000"
func fetchEquityRange(heroHole: [String], villainRange: [String], board: [String] = [], completion: @escaping (EquityResponse?) -> Void) {
    
    JWTCache.shared.getToken() { token in
        guard let token = token else {
            completion(nil)
            return
        }

        // Build the request after we have a valid token
        guard let url = URL(string: "\(apiPrefix)/api/equity/from-range") else {
            completion(nil)
            return
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization") // <-- Add this

        let body = EquityRequest(hero_hole: heroHole, villain_range: villainRange, board: board)

        do {
            request.httpBody = try JSONEncoder().encode(body)
        } catch {
            print("Error encoding body: \(error)")
            completion(nil)
            return
        }

        URLSession.shared.dataTask(with: request) { data, response, error in
            guard let data = data, error == nil else {
                print("Request error: \(String(describing: error))")
                completion(nil)
                return
            }

            do {
                let equityResponse = try JSONDecoder().decode(EquityResponse.self, from: data)
                completion(equityResponse)
            } catch {
                print("Decoding error: \(error)")
                completion(nil)
            }
        }.resume()
    }
}


func fetchEquityVsHand(heroHole: [String], villainHole: [String], board: [String] = [], completion: @escaping (EquityResponse?) -> Void) {
    
    // Change port if your FastAPI runs on something else
    guard let url = URL(string: "\(apiPrefix)/api/equity/from-hand") else {
        completion(nil)
        return
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.addValue("application/json", forHTTPHeaderField: "Content-Type")

    let body = EquityRequestHand(hero_hole: heroHole, villain_hole: villainHole, board: board)
    
    do {
        request.httpBody = try JSONEncoder().encode(body)
    } catch {
        print("Error encoding body: \(error)")
        completion(nil)
        return
    }

    URLSession.shared.dataTask(with: request) { data, response, error in
        guard let data = data, error == nil else {
            print("Request error: \(String(describing: error))")
            completion(nil)
            return
        }

        do {
            let equityResponse = try JSONDecoder().decode(EquityResponse.self, from: data)
            completion(equityResponse)
        } catch {
            print("Decoding error: \(error)")
            completion(nil)
        }
    }.resume()
}
