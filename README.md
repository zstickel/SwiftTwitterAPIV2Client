# SwiftTwitterAPIV2Client

![Platform](https://img.shields.io/badge/platforms-iOS%213.0%20%7C%20macOS%2010.15-F28D00.svg)

Async Swift Twitter API v2 client makes it easy to make certain calls to Twitter API v2 from your Swift application. This Twitter API v2 client implements a subset of Twitter API v2. Currently only API calls capable of authenticating with OAuth2.0 App-Only are implemented, including Search Recent Tweets, Tweet counts, and Retweets lookup. Contributions to increase API coverage are always welcome!  

You can use the Swift Package Manager to install SwiftTwitterAPIV2Client. 

## Usage
```swift
import SwiftTwitterAPIV2Client
```

To initialize the client:
```swift
let twitterClient = SwiftTwitterAPIV2Client(consumerKey: CONSUMER_KEY, consumerSecret: CONSUMER SECRET)`
```

To authenticate:
```swift
bearerToken = await twitterClient.authenticate()
```
This will return a String representation of the bearer token returned from the API.

To search recent tweets:
```swift
let result = await twitterClient.searchRecentTweets(searchString: searchString,isVerified: false, maxResults: 20, language: .english)
```
This makes the GET /2/tweets/recent request using Alamofire under the hood. The function  will return a JSON object which can be decoded using the SwiftyJSON package which is included as a dependencey. An example of how to decode the JSON object and obtain the first tweet:
```swift
let tweet = result["data"][0]["text"].rawString()!
```
To get a set of historical tweet counts that match a query:
```swift
let result = await twitterClient.tweetCount(searchString: searchString, language: .english)
```
This makes the GET /2/tweets/counts/recent request. The function will return a JSON object.


You can also use this package without using the async methods using callbacks. For example:
```swift 
twitterClient.searchRecentTweets(searchString: searchString,isVerified: false, maxResults: 20, language: .english){result in
    //Code to execute
}
```

## Example asynchronous usage in a simple SwiftUI application that queries for the number of recent tweets about a topic and displays the number of tweets about the topic in the previous hour:

View code:
```swift
struct ContentView: View {
    @State var searchTerm = ""
    @ObservedObject var client = TwitterCaller()
    var body: some View {
        ZStack{
            Color.init(red: 52.0/255.0, green: 235/255.0, blue: 171/255.0, opacity: 1.0).ignoresSafeArea()
            
            VStack{
                Text(client.result)
                    .padding()
                TextField("Tweets the previous hour..", text: $searchTerm)
                    .multilineTextAlignment(.center).background(Color.white)
        
                Button("Get number of tweets from the previous hour.", action: getSentiment)
            }
        }
    }
    func getSentiment(){
        Task.detached{
            await client.getToken()
            await client.getTweetInfo(of: searchTerm)
        }
    }
}
```
Controller code (your twitter developer consumer key and consumer secret will have to be provided to the client constructor as a String):
```swift
@MainActor
class TwitterCaller : ObservableObject {
    @Published var result = "How many tweets were there in the previous hour about this subject?"
    var token = ""
    let client = SwiftTwitterAPIV2Client(consumerKey: CONSUMER_KEY, consumerSecret: CONSUMER_SECRET)
    func getToken() async {
        token = await testTwitter.authenticate()
        
    }
    func getTweetInfo(of searchTerm : String) async{
        let count = await client.tweetCount(searchString: searchTerm, language: .english)
        result = count["data"][count["data"].count-2]["tweet_count"].rawString()!
    }
    
}
```
