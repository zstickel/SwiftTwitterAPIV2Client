import Foundation
import Alamofire
import SwiftyJSON

public class SwiftTwitterAPIV2Client {
    

    let authurl :String = "https://api.twitter.com/oauth2/token"
    let url : String = "https://api.twitter.com/2/tweets/search/recent"
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
        authenticate()
    }
    public func authenticate(){
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
                if let token = json["access_token"].rawString(){
                    self.bearerToken = token
                }
            }catch{
                print(error)
            }
        }
    }
    public func searchRecentTweets(searchString: String, isVerified : Bool, maxResults: Int, language: Language, searchRecentTweetsCompletionHandler: @escaping (String)-> Void) {
        let language = getLanguage(language: language)
        var query = ""
        var finalResult = ""
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
            "max_results" : String(maxResults),
        ]
        AF.request(url, method: .get, parameters: parameters, headers: queryHeaders).responseDecodable(of: DecodableType.self){ (response) in
            do{
                guard let data = response.data else {fatalError("Data didn't come back")}
                let json = try JSON(data: data)
                finalResult = json["data"][0]["text"].rawString()!
            
                searchRecentTweetsCompletionHandler(finalResult)
                return
            }catch{
                searchRecentTweetsCompletionHandler("Error fetching tweets")
                return
            }
        }.resume()
    }
    
    public func searchRecentTweets(searchString: String, isVerified : Bool, maxResults: Int, language: Language) async -> String {
            await withCheckedContinuation {continuation in
                searchRecentTweets (searchString: searchString, isVerified: isVerified, maxResults: maxResults, language: language, searchRecentTweetsCompletionHandler: { result in
                        continuation.resume(returning: result)
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
    
}
