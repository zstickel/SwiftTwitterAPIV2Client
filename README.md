# SwiftTwitterAPIV2Client

![Platform](https://img.shields.io/badge/platforms-iOS%2013.0%20%7C%20macOS%2010.15-F28D00.svg)

This async Swift Twitter API v2 client makes it easy to make certain calls to the Twitter API v2 from your Swift application. The package implements a subset of Twitter API v2 using Alamofire under the hood. Currently only API calls capable of authenticating with OAuth2.0 App-Only are implemented, including Search Recent Tweets, Tweet counts, Retweets lookup and Likes lookup. Contributions to increase API coverage are always welcome!  

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
This makes the GET /2/tweets/recent request using Alamofire under the hood. The method will return a JSON object which can be decoded using the SwiftyJSON package which is included as a dependencey. An example of how to decode the JSON object and obtain the first tweet in the result:
```swift
let tweet = result["data"][0]["text"].rawString()!
```
To get a set of historical tweet counts that match a query:
```swift
let result = await twitterClient.tweetCount(searchString: searchString, language: .english)
```
This makes the GET /2/tweets/counts/recent request. The method will return a JSON object.

To get a list of accounts that retweeted a given tweet, pass the tweet id as a string:
```swift
let retweeters = await twitterClient.retweetLookup(id: tweetidString)
```
This makes the GET /2/tweets/:id/retweeted_by request. The method will return a JSON object.

To get a list of tweets that a user liked, pass the user id as a string:
```swift
let tweetsauserliked = await twitterClient.usersLikedTweetsLookup(userid: useridString)
```
This makes the GET /2/users/:id/liked_tweets request. The method will return a JSON object.

To get a list of users that liked a tweet, pass the tweet id as a string:
```swift
let usersthatlikedatweet = await twitterClient.likedTweetUsersLookup(tweetid: tweetidString)
```


You can also use this package without using the async methods by using callbacks. For example:
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
