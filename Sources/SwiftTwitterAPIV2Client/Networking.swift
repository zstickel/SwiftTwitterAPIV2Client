//
//  File.swift
//  
//
//  Created by Stickel, Zane on 3/27/22.
//

import Foundation

struct Networking {
    @available(iOS 15.0, *)
    @available(macOS 12.0, *) static func loadData(queryItems:[URLQueryItem]) async -> Data? {
        var components = URLComponents()
        components.scheme = "https"
        components.host = "api.twitter.com"
        components.path = "/2/tweets/counts/recent"
        components.queryItems = queryItems
        do {
            let(data, _) = try await URLSession.shared.data(from: components.url!)
                return data
        }catch{
            print("failed to get data")
            return nil
        }
    }
}
