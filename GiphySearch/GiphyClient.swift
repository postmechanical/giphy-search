//
//  GiphyClient.swift
//  GiphySearch
//
//  Created by Aaron London on 4/16/19.
//  Copyright © 2019 postmechanical. All rights reserved.
//
//  GIPHY provides a full featured SDK: https://github.com/Giphy/giphy-ios-sdk-core
//  This class is implemented as an exercise to demonstrate router pattern and working with `URLSession` APIs.
//

import UIKit

class GiphyClient {
    var currentTask: URLSessionDataTask?

    func search(for term: String, limit: UInt = 100, offset: UInt = 0, completion: @escaping ([String: Any], Error?) -> Void) {
        do {
            currentTask = try Router.search(term: term, limit: limit, offset: offset).sendRequest(completion: { (response, error) in
                DispatchQueue.main.async {
                    completion(response, error)
                }
            })
        } catch {
            completion([:], error)
        }
    }
    
    func cancel() {
        currentTask?.cancel()
        currentTask = nil
    }
}

enum GiphyClientError: Error {
    case invalidURL(baseURLString: String?, path: String?, queryItems: [URLQueryItem]?)
    case unexpectedResponseData
    case responseError(code: Int, description: String)
    
    public var errorDescription: String {
        switch self {
        case let .invalidURL(baseURLString, path, queryItems): return "Could not generate valid URL for request with baseURLString: \(baseURLString ?? ""), path: \(path ?? ""), queryItems: \(queryItems ?? [])"
        case .unexpectedResponseData: return "The data returned from the server was in an unexpected format, or expected data was not present."
        case let .responseError(code, description): return "\(description) (Response code: \(code))"
        }
    }
    
    public var errorName: String {
        switch self {
        case .invalidURL: return "invalidURL"
        case .unexpectedResponseData: return "unexpectedResponseData"
        case let .responseError(code, _): return "responseError: \(code)"
        }
    }
}

private enum HTTPMethod: String {
    case GET
    case POST
}

private enum Router {
    case search(term: String, limit: UInt, offset: UInt)
    
    static let apiKey = "HfPEFSIiY5P3dWpDyt1DsBdbXAD9SutP"
    static let baseURLString = "https://api.giphy.com"
    static var userAgent: String {
        guard let info = Bundle.main.infoDictionary else { return "" }
        
        let bundleId = Bundle.main.bundleIdentifier ?? ""
        let version = info["CFBundleShortVersionString"] as? String ?? ""
        let build = info["CFBundleVersion"] as? String ?? ""
        let deviceModel = UIDevice.current.model
        let systemName = UIDevice.current.systemName
        let systemVersion = UIDevice.current.systemVersion
        let scale = UIScreen.main.scale
        
        return "\(bundleId)/\(version).\(build) (\(deviceModel); \(systemName) \(systemVersion); Scale/\(scale))"
    }
    
    func sendRequest(completion: @escaping ([String: Any], Error?) -> Void) throws -> URLSessionDataTask {
        var components = URLComponents(string: Router.baseURLString)
        components?.path = self.path
        components?.queryItems = self.queryItems
        guard let url = components?.url else {
            throw GiphyClientError.invalidURL(baseURLString: Router.baseURLString, path: self.path, queryItems: self.queryItems)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = self.method.rawValue
        
        for headerField in headerFields {
            request.addValue(headerField.value, forHTTPHeaderField: headerField.key)
        }
        
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue(Router.userAgent, forHTTPHeaderField: "User-Agent")
        
        if self.method == .POST {
            request.httpBody = try JSONSerialization.data(withJSONObject: postParameters, options: .prettyPrinted)
        }
        
        let task = URLSession.shared.dataTask(with: request, completionHandler: { (data, response, taskError) in
            guard
                let data = data,
                let response = response as? HTTPURLResponse,
                let json = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any]
                else {
                    completion([:], GiphyClientError.unexpectedResponseData)
                    return
            }
            
            let status = response.statusCode
            
            switch status {
            case 200:
                completion(json, nil)
            default:
                completion(json, GiphyClientError.responseError(code: status, description: json["message"] as? String ?? (json["meta"] as? [String: Any])?["msg"] as? String ?? ""))
            }
        })
        task.resume()
        return task
        
    }
    
    func queryItems(from parameters: [String: String]) -> [URLQueryItem] {
        return parameters.map { URLQueryItem(name: $0, value: $1) }
    }
    
    var path: String {
        switch self {
        case .search: return "/v1/gifs/search"
        }
    }
    
    var queryItems: [URLQueryItem] {
        switch self {
        case let .search(term, limit, offset):
            return queryItems(from: ["api_key": Router.apiKey, "q": term, "limit": "\(limit)", "offset": "\(offset)"])
        }
    }
    
    var postParameters: [String: Any] {
        return [:]
    }
    
    var headerFields: [String: String] {
        return [:]
    }
    
    var method: HTTPMethod {
        switch self {
        case .search: return .GET
        }
    }
}
