//
//  HTTPConnector.swift
//  MyMusic
//
//  Created by Leo Lo on 14/5/2021.
//  Copyright © 2021 ASN GROUP LLC. All rights reserved.
//

import Foundation

protocol HTTPConnectorDelegate {
    func httpConnector(_ connector: HTTPConnector, complete response: Data, userInfo: [String: Any]?)
    func httpConnector(_ connector: HTTPConnector, response: HTTPURLResponse?, data: Data?, error: Error?, userInfo: [String: Any]?)
}

enum HTTPRequestMethod: Int, CustomStringConvertible {
    case post = 0
    case get = 1
    case put = 2
    case delete = 3
    
    var description: String {
        switch self {
            case .post: return "POST"
            case .get: return "GET"
            case .put: return "PUT"
            case .delete: return "DELETE"
        }
    }
}

enum ContentType: Int {
    case json = 0
    case wwwForm = 1
    case jsonWithoutToken = 2
    
    var header: [String: String] {
//        let accessToken = ConfigController.shared.getConfig(name: "User", UserConfig.self)!.accessToken
        switch self {
            case .json:
                return [
                    "Content-Type": "application/json",
                    "Cache-Control": "no-cache",
                    "Authorization": "accessToken"
                ]
            case .wwwForm:
                return [
                    "Content-Type": "application/x-www-form-urlencoded",
                    "Cache-Control": "no-cache",
                    "Authorization": "accessToken"
                ]
            case .jsonWithoutToken:
                return [
                    "Content-Type": "application/json",
                    "Cache-Control": "no-cache",
                ]
        }
    }
}

class HTTPConnector: NSObject {
    var delegate: HTTPConnectorDelegate?

    private func prepareHeader(request: inout URLRequest, header: [String: String]) {
        header.forEach({ (field, value) in
            request.setValue(value, forHTTPHeaderField: field)
        })
    }

    private func prepareRequest(url: String, data: Data?, header: [String: String], method: HTTPRequestMethod) -> URLRequest {
        guard let urlObj = URL(string: url) else { fatalError("Error") }
        var request = URLRequest(url: urlObj)
        prepareHeader(request: &request, header: header)
        request.httpMethod = method.description
        request.httpBody = data
        return request
    }

    private func send(url: String, data: Data?, header: [String: String], method: HTTPRequestMethod, userInfo: [String: Any]? = nil) {
        let request: URLRequest = prepareRequest(url: url, data: data, header: header, method: method)
        
        let session = URLSession(configuration: .ephemeral)
        session.configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        session.configuration.timeoutIntervalForRequest = 5
        session.configuration.timeoutIntervalForResource = 5
        
        session.dataTask(with: request) { (data, response, error) in
            if let response = response as? HTTPURLResponse {
                if response.statusCode != 200 {
                    print("Response: \(response)")
                    print(String(data: data!, encoding: .utf8) ?? "HTTP response error")
                    self.delegate?.httpConnector(self, response: response, data: data, error: error, userInfo: userInfo)
                    return
                }
            }
            if let data = data {
                self.delegate?.httpConnector(self, complete: data, userInfo: userInfo)
            } else if let error = error {
                print("error: \(error)")
                self.delegate?.httpConnector(self, response: response as? HTTPURLResponse, data: data, error: error, userInfo: userInfo)
            }
        }.resume()
    }

    func get(url: String, data: Data?, header: [String: String], userInfo: [String: Any]? = nil) {
        send(url: url, data: data, header: header, method: .get, userInfo: userInfo)
    }
    
    func post(url: String, data: Data?, header: [String: String], userInfo: [String: Any]? = nil) {
        send(url: url, data: data, header: header, method: .post, userInfo: userInfo)
    }
    
    func put(url: String, data: Data?, header: [String: String], userInfo: [String: Any]? = nil) {
        send(url: url, data: data, header: header, method: .put, userInfo: userInfo)
    }
    
    func delete(url: String, data: Data?, header: [String: String], userInfo: [String: Any]? = nil) {
        send(url: url, data: data, header: header, method: .delete, userInfo: userInfo)
    }
}

