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
    var bearerToken : String = ""
/// Supports only four languages at this time
    public enum Language {
        case english, french, spanish, german
    }
    
    struct DecodableType: Decodable { let url: String }
/// Client initializer that also prepares the authorization header  for the authentication method.
    /// - Parameters
    ///     -consumer key: Consumer key for the API v2 OAuth2.0 App-Only authentication method.
    ///     -consumerSecret: Consumer sercret for the API v2 OAuth2.0 App-Only  authentication method.
    public init(consumerKey: String, consumerSecret: String){
        concatCredentials = consumerKey + ":" + consumerSecret
        baseSixFour = concatCredentials.data(using: .utf8)?.base64EncodedString()
    }
    /// Client authentication method. Stores and returns a bearer token as a String from the twitter API response.
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
                print(json)
                var token = ""
                token = json["access_token"].rawString() ?? ""
                self.bearerToken = token
                authenticateCompletionHandler(token)
            }catch{
                print(error)
                authenticateCompletionHandler("Unable to obtain Bearer Token")
            }
        }
    }
    /// Async wrapper for the authenticate method.
    public func authenticate() async -> String {
        await withCheckedContinuation {continuation in
            authenticate (authenticateCompletionHandler: { result in
                    continuation.resume(returning: result)
            })
        }
    }

    /// Calls the recent tweets request from the Twitter API and returns the received JSON or nil in the event of an error.
    ///  - Parameters
    ///   - searchString : The query string to be passed to the Twitter API v2. See the Twitter API documentation for formatting.
    ///   - isVerified : Require the tweeter to be verified
    ///   - maxResults : Maximum results desured
    ///   - language : Only a few of the suported languages are currently supported by the client.
    public func searchRecentTweets(searchString: String, isVerified : Bool, maxResults: Int, language: Language, searchRecentTweetsCompletionHandler: @escaping (JSON?)-> Void) {
        var numResults = maxResults
        if maxResults > 100 {numResults = 100}
        let language = getLanguage(language: language)
        var query = ""
        if isVerified {
            query = searchString + " " + "is:verified " + "lang:" + language
        }else{
            query = searchString + " " + "lang:" + language
        }
        let queryHeaders: HTTPHeaders = [
            "Authorization" : "Bearer \(bearerToken)",
            "Accept" : "application/x-www-form-urlencoded;charset=UTF-8",
        ]
        
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
                searchRecentTweetsCompletionHandler(nil)
                return
            }
        }.resume()
    }
    
    public func searchRecentTweets(searchString: String, isVerified : Bool, maxResults: Int, language: Language) async -> JSON {
            await withCheckedContinuation {continuation in
                searchRecentTweets (searchString: searchString, isVerified: isVerified, maxResults: maxResults, language: language, searchRecentTweetsCompletionHandler: { result in
                    continuation.resume(returning: result ?? "Error fetching JSON")
                })
            }
    }
    
    
    func getLanguage(language: Language)-> String{
        switch language{
        case .english:
            return "en"
        case .german:
            return "de"
        case .french:
            return "fr"
        case .spanish:
            return "es"
        }
        
    }
    
    public func tweetCount (searchString: String, language: Language, tweetCountCompletionHandler: @escaping (JSON?)-> Void){
        let queryHeaders: HTTPHeaders = [
            "Authorization" : "Bearer \(bearerToken)",
            "Accept" : "application/x-www-form-urlencoded;charset=UTF-8",
        ]
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
                tweetCountCompletionHandler(nil)
                return
            }
        }.resume()
    }
    public func tweetCount(searchString: String, language: Language) async -> JSON {
            await withCheckedContinuation {continuation in
                tweetCount (searchString: searchString,language: language, tweetCountCompletionHandler: { result in
                    continuation.resume(returning: result ?? "Error fetching JSON")
                })
            }
    }
    
    public func reetweetLookup (id: String, retweetLookupCompletionHandler: @escaping (JSON?)-> Void){
        let queryHeaders: HTTPHeaders = [
            "Authorization" : "Bearer \(bearerToken)",
            "Accept" : "application/x-www-form-urlencoded;charset=UTF-8",
        ]
        let retweetURL = retweeturl + id + "/retweeted_by"
        AF.request(retweetURL, method: .get, headers: queryHeaders).responseDecodable(of: DecodableType.self){ (response) in
            do{
                guard let data = response.data else {fatalError("Data didn't come back")}
                let json = try JSON(data: data)
               
                retweetLookupCompletionHandler(json)
                return
            }catch{
                retweetLookupCompletionHandler(nil)
                return
            }
        }.resume()
    }
    public func retweetLookup(id: String) async -> JSON {
            await withCheckedContinuation {continuation in
                reetweetLookup(id: id) { result in
                    continuation.resume(returning: result ?? "Error fetching JSON")
                }
            }
    }
    public func likedTweetUsersLookup (tweetid: String, likedTweetUsersLookupCompletionHandler: @escaping (JSON?)-> Void){
        let queryHeaders: HTTPHeaders = [
            "Authorization" : "Bearer \(bearerToken)",
            "Accept" : "application/x-www-form-urlencoded;charset=UTF-8",
        ]
        let likedURL = userslikingtweeturl + tweetid + "/liking_users"
        AF.request(likedURL, method: .get, headers: queryHeaders).responseDecodable(of: DecodableType.self){ (response) in
            do{
                guard let data = response.data else {fatalError("Data didn't come back")}
                let json = try JSON(data: data)
               
                likedTweetUsersLookupCompletionHandler(json)
                return
            }catch{
                likedTweetUsersLookupCompletionHandler(nil)
                return
            }
        }.resume()
    }
    public func likedTweetUsersLookup(tweetid: String) async -> JSON {
            await withCheckedContinuation {continuation in
                likedTweetUsersLookup(tweetid: tweetid) { result in
                    continuation.resume(returning: result ?? "Error fetching JSON")
                }
            }
    }
    
    public func usersLikedTweetsLookup (userid: String, usersLikedTweetsLookupCompletionHandler: @escaping (JSON?)-> Void){
        let queryHeaders: HTTPHeaders = [
            "Authorization" : "Bearer \(bearerToken)",
            "Accept" : "application/x-www-form-urlencoded;charset=UTF-8",
        ]
        let likedURL = tweetslikedByUserUrl + userid + "/liked_tweets"
        AF.request(likedURL, method: .get, headers: queryHeaders).responseDecodable(of: DecodableType.self){ (response) in
            do{
                guard let data = response.data else {fatalError("Data didn't come back")}
                let json = try JSON(data: data)
               
                usersLikedTweetsLookupCompletionHandler(json)
                return
            }catch{
                usersLikedTweetsLookupCompletionHandler(nil)
                return
            }
        }.resume()
    }
    public func usersLikedTweetsLookup(userid: String) async -> JSON {
            await withCheckedContinuation {continuation in
                usersLikedTweetsLookup(userid: userid) { result in
                    continuation.resume(returning: result ?? "Error fetching JSON")
                }
            }
    }
}
