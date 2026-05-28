import Foundation

enum HTTPMethod: String {
    case get = "GET"
    case post = "POST"
    case put = "PUT"
    case patch = "PATCH"
    case delete = "DELETE"
}

struct APIEndpoint {
    var path: String
    var method: HTTPMethod = .get
    var queryItems: [URLQueryItem]? = nil
    var body: Data? = nil
    var requiresAuth: Bool = true
}
