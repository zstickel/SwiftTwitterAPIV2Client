//
// SwiftTwitterAPIV2Client.swift
//
// Copyright (c) 2022 Zane Stickel
// MIT License

import Foundation
import Alamofire
import SwiftyJSON

/// An async capable Swift client for certain Twitter API V2 calls
public class SwiftTwitterAPIV2Client {
    
    
    private let authurl :String = "https://api.twitter.com/oauth2/token"
    private let url : String = "https://api.twitter.com/2/tweets/search/recent"
    private let counturl : String = "https://api.twitter.com/2/tweets/counts/recent"
    private let retweeturl : String = "https://api.twitter.com/2/tweets/"
    private let userslikingtweeturl : String = "https://api.twitter.com/2/tweets/"
    private let tweetslikedByUserUrl : String = "https://api.twitter.com/2/users/"
    private var concatCredentials: String = ""
    private let baseSixFour : String?
    private var queryHeaders: HTTPHeaders = []
    public var isAuthenticated = false
    var bearerToken : String = ""
    /// Supports only four languages at this time, English, French, Spanish, and German
    public enum Language {
        case english, french, spanish, german, ukranian
    }
    
    struct DecodableType: Decodable { let url: String }
    /// Client initializer that prepares the authorization header for the authentication method.
    /// - Parameters:
    ///     - consumerKey: Consumer key for the API v2 OAuth2.0 App-Only authentication method. This can be obtained from the Twitter Developer Console.
    ///     - consumerSecret: Consumer sercret for the API v2 OAuth2.0 App-Only  authentication method. This can be obtained from the Twitter Developer Console.
    public init(consumerKey: String, consumerSecret: String){
        concatCredentials = consumerKey + ":" + consumerSecret
        baseSixFour = concatCredentials.data(using: .utf8)?.base64EncodedString()
    }
    
    // Used to select a language for received tweets, more languages are available through the twitter api and will be implemented at a later date.
    private func getLanguage(language: Language)-> String{
        switch language{
        case .english:
            return "en"
        case .german:
            return "de"
        case .french:
            return "fr"
        case .spanish:
            return "es"
        case .ukranian:
            return "uk"
        }
        
    }
    /// Authenticates the client to the Twitter APIv2 and returns an OAuth2.0 bearer token or a description of the error.
    public func authenticate(authenticateCompletionHandler: @escaping (String)-> Void){
        let headers: HTTPHeaders = [
            "Authorization" : "Basic \(baseSixFour ?? "")",
            "Accept" : "application/x-www-form-urlencoded;charset=UTF-8",
        ]
        let parameter: [String:String] = [
            "grant_type" : "client_credentials",
        ]
        
        AF.request(authurl, method: .post,parameters: parameter, headers: headers).responseDecodable(of: DecodableType.self){ response in
            do{
                guard let data = response.data else {fatalError("Data didn't come back")}
                
                let json = try JSON(data: data)
                var token = ""
                token = json["access_token"].rawString() ?? ""
                self.bearerToken = token
                self.queryHeaders = [
                    "Authorization" : "Bearer \(self.bearerToken)",
                    "Accept" : "application/x-www-form-urlencoded;charset=UTF-8",
                ]
                self.isAuthenticated = true
                authenticateCompletionHandler(token)
            }catch{
                print(error)
                authenticateCompletionHandler("Unable to obtain Bearer Token")
            }
        }
    }
    /// Async wrapper for the authenticate method. Authenticates the client to the Twitter API and returns an OAuth2.0 bearer token.
    public func authenticate() async -> String {
        await withCheckedContinuation {continuation in
            authenticate (authenticateCompletionHandler: { result in
                continuation.resume(returning: result)
            })
        }
    }
    
    /// Calls the recent tweets GET request from the Twitter API and returns the received JSON or nil in the event of an error.
    ///  - Parameters:
    ///     - searchString: The query string to be passed to the Twitter API v2. See the Twitter API documentation for formatting.
    ///     - isVerified: Require the tweeter to be verified or not
    ///     - maxResults: Maximum results desired, a parameter greater than 100 or less than one will default to 100.
    ///     - language: Desired languange. Only a few of the suported languages are currently supported by the client.
    public func searchRecentTweets(searchString: String, isVerified : Bool, maxResults: Int, language: Language, searchRecentTweetsCompletionHandler: @escaping (JSON?)-> Void) {
        if !isAuthenticated {
            print("Authenticate first")
            searchRecentTweetsCompletionHandler(nil)
            return
        }
        var numResults = maxResults
        if maxResults > 100 || maxResults < 1 {numResults = 100}
        let language = getLanguage(language: language)
        var query = ""
        if isVerified {
            query = searchString + " " + "is:verified " + "lang:" + language
        }else{
            query = searchString + " " + "lang:" + language
        }
        
        let parameters : [String:String] = [
            "query" : query,
            "max_results" : String(numResults),
        ]
        AF.request(url, method: .get, parameters: parameters, headers: queryHeaders).responseDecodable(of: DecodableType.self){ (response) in
            do{
                guard let data = response.data else {fatalError("Data didn't come back")}
                let json = try JSON(data: data)
                
                searchRecentTweetsCompletionHandler(json)
                return
            }catch{
                print(error)
                searchRecentTweetsCompletionHandler(nil)
                return
            }
        }.resume()
    }
    /// Asnyc wrapper for searchRecentTweets method. Calls the recent tweets GET request from the Twitter API and returns the received JSON or nil in the event of an error.
    ///  - Parameters:
    ///     - searchString: The query string to be passed to the Twitter API v2. See the Twitter API documentation for formatting.
    ///     - isVerified: Require the tweeter to be verified or not
    ///     - maxResults: Maximum results desired, a parameter greater than 100 or less than one will default to 100.
    ///     - language: Desired languange. Only a few of the suported languages are currently supported by the client.
    public func searchRecentTweets(searchString: String, isVerified : Bool, maxResults: Int, language: Language) async -> JSON {
        await withCheckedContinuation {continuation in
            searchRecentTweets (searchString: searchString, isVerified: isVerified, maxResults: maxResults, language: language, searchRecentTweetsCompletionHandler: { result in
                continuation.resume(returning: result ?? "Error fetching JSON")
            })
        }
    }
    
    /// Calls the recent tweet count GET request from the Twitter API and returns the received JSON or nil in the event of an error.
    ///  - Parameters:
    ///     - searchString: The query string to be passed to the Twitter API v2. See the Twitter API documentation for formatting.
    ///     - language: Desired languange. Only a few of the suported languages are currently supported by the client.
    public func tweetCount (searchString: String, language: Language, tweetCountCompletionHandler: @escaping (JSON?)-> Void){
        if !isAuthenticated {
            print("Authenticate first")
            tweetCountCompletionHandler(nil)
            return
        }
        let language = getLanguage(language: language)
        let query = searchString + " " + "lang:" + language
        let parameters : [String:String] = [
            "query" : query,
        ]
        
        
        AF.request(counturl, method: .get, parameters: parameters, headers: queryHeaders).responseDecodable(of: DecodableType.self){ (response) in
            do{
                guard let data = response.data else {fatalError("Data didn't come back")}
                let json = try JSON(data: data)
                
                tweetCountCompletionHandler(json)
                return
            }catch{
                print(error)
                tweetCountCompletionHandler(nil)
                return
            }
        }.resume()
    }
    /// Async wrapper for the tweetCount method. Calls the recent tweet count GET request from the Twitter API and returns the received JSON or nil in the event of an error.
    ///  - Parameters:
    ///     - searchString: The query string to be passed to the Twitter API v2. See the Twitter API documentation for formatting.
    ///     - language: Desired languange. Only a few of the suported languages are currently supported by the client.
    public func tweetCount(searchString: String, language: Language) async -> JSON {
        await withCheckedContinuation {continuation in
            tweetCount (searchString: searchString,language: language, tweetCountCompletionHandler: { result in
                continuation.resume(returning: result ?? "Error fetching JSON")
            })
        }
    }
    /// Calls the retweets lookup GET request from the Twitter API and returns the received JSON or nil in the event of an error.
    ///  - Parameters:
    ///     - id: The id of the tweet to lookup. You can get a tweet id from the twitter application or via tweet lookup API calls.
    public func reetweetLookup (id: String, retweetLookupCompletionHandler: @escaping (JSON?)-> Void){
        if !isAuthenticated {
            print("Authenticate first")
            retweetLookupCompletionHandler(nil)
            return
        }
        let retweetURL = retweeturl + id + "/retweeted_by"
        AF.request(retweetURL, method: .get, headers: queryHeaders).responseDecodable(of: DecodableType.self){ (response) in
            do{
                guard let data = response.data else {fatalError("Data didn't come back")}
                let json = try JSON(data: data)
                
                retweetLookupCompletionHandler(json)
                return
            }catch{
                print(error)
                retweetLookupCompletionHandler(nil)
                return
            }
        }.resume()
    }
    /// Async wrapper for the retweetLookup method. Calls the retweets lookup GET request from the Twitter API and returns the received JSON or nil in the event of an error.
    ///  - Parameters:
    ///     - id: The id of the tweet to lookup. You can get a tweet id from the twitter application or via tweet lookup API calls.
    public func retweetLookup(id: String) async -> JSON {
        await withCheckedContinuation {continuation in
            reetweetLookup(id: id) { result in
                continuation.resume(returning: result ?? "Error fetching JSON")
            }
        }
    }
    /// Calls the users who have liked a tweet GET request from the Twitter API and returns the received JSON or nil in the event of an error.
    ///  - Parameters:
    ///     - tweetid: The id of the tweet to lookup. You can get a tweet id from the twitter application or via tweet lookup API calls.
    public func likedTweetUsersLookup (tweetid: String, likedTweetUsersLookupCompletionHandler: @escaping (JSON?)-> Void){
        if !isAuthenticated {
            print("Authenticate first")
            likedTweetUsersLookupCompletionHandler(nil)
            return
        }
        let likedURL = userslikingtweeturl + tweetid + "/liking_users"
        AF.request(likedURL, method: .get, headers: queryHeaders).responseDecodable(of: DecodableType.self){ (response) in
            do{
                guard let data = response.data else {fatalError("Data didn't come back")}
                let json = try JSON(data: data)
                
                likedTweetUsersLookupCompletionHandler(json)
                return
            }catch{
                print(error)
                likedTweetUsersLookupCompletionHandler(nil)
                return
            }
        }.resume()
    }
    /// Async wrapper for the likedTweetUsersLookup method. Calls the users who have liked a tweet GET request from the Twitter API and returns the received JSON or nil in the event of an error.
    ///  - Parameters:
    ///     - tweetid: The id of the tweet to lookup. You can get a tweet id from the twitter application or via tweet lookup API calls.
    public func likedTweetUsersLookup(tweetid: String) async -> JSON {
        await withCheckedContinuation {continuation in
            likedTweetUsersLookup(tweetid: tweetid) { result in
                continuation.resume(returning: result ?? "Error fetching JSON")
            }
        }
    }
    /// Calls the tweets liked by a user GET request from the Twitter API and returns the received JSON or nil in the event of an error.
    ///  - Parameters:
    ///     - userid: The userid of the user whose liked tweets to lookup.
    public func usersLikedTweetsLookup (userid: String, usersLikedTweetsLookupCompletionHandler: @escaping (JSON?)-> Void){
        if !isAuthenticated {
            print("Authenticate first")
            usersLikedTweetsLookupCompletionHandler(nil)
            return
        }
        let likedURL = tweetslikedByUserUrl + userid + "/liked_tweets"
        AF.request(likedURL, method: .get, headers: queryHeaders).responseDecodable(of: DecodableType.self){ (response) in
            do{
                guard let data = response.data else {fatalError("Data didn't come back")}
                let json = try JSON(data: data)
                
                usersLikedTweetsLookupCompletionHandler(json)
                return
            }catch{
                print(error)
                usersLikedTweetsLookupCompletionHandler(nil)
                return
            }
        }.resume()
    }
    /// Async wrapper for the usersLikedTweetsLookup method. Calls the tweets liked by a user GET request from the Twitter API and returns the received JSON or nil in the event of an error.
    ///  - Parameters:
    ///     - userid: The userid of the user whose liked tweets to lookup.
    public func usersLikedTweetsLookup(userid: String) async -> JSON {
        await withCheckedContinuation {continuation in
            usersLikedTweetsLookup(userid: userid) { result in
                continuation.resume(returning: result ?? "Error fetching JSON")
            }
        }
    }
    @available(iOS 15.0, *)
    @available(macOS 12.0, *)
    public func asyncTweetCount(searchString: String, language: Language) async -> JSON? {
        if !isAuthenticated {
            print("Authenticate first")
            return nil
        }
        let language = getLanguage(language: language)
        let query = searchString + " " + "lang:" + language
        let parameters = [
            URLQueryItem(name: "query", value: query)
        ]
        do{
            if let data = await Networking.loadData(queryItems: parameters){
                let json = try JSON(data: data)
                return json
            }
            print("no data back")
            return nil
        }catch{
            print(error)
            return nil
        }
    }
}
