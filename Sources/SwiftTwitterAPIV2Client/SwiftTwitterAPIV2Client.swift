import Foundation
import Alamofire
import SwiftyJSON

public class SwiftTwitterAPIV2Client {
    

    let authurl :String = "https://api.twitter.com/oauth2/token"
    let url : String = "https://api.twitter.com/2/tweets/search/recent"
    let counturl : String = "https://api.twitter.com/2/tweets/counts/recent"
    var concatCredentials: String = ""
    let baseSixFour : String?
    var bearerToken : String = ""
    public enum Language {
        case english, french, spanish, german
    }
    
    struct DecodableType: Decodable { let url: String }
    
    public init(consumerKey: String, consumerSecret: String){
        concatCredentials = consumerKey + ":" + consumerSecret
        baseSixFour = concatCredentials.data(using: .utf8)?.base64EncodedString()
    }
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
                authenticateCompletionHandler("")
            }
        }
    }
    public func authenticate() async -> String {
        await withCheckedContinuation {continuation in
            authenticate (authenticateCompletionHandler: { result in
                    continuation.resume(returning: result)
            })
        }
    }

    
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
    
}
