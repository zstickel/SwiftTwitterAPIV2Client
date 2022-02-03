# SwiftTwitterAPIV2Client

![Platform](https://img.shields.io/badge/platforms-iOS%213.0%20%7C%20macOS%2010.15-F28D00.svg)

Async Swift Twitter API v2 client makes it easy to make certain calls to Twitter API v2 from your Swift application. This Twitter API v2 client implements a subset of Twitter API v2. Currently only OAuth2.0 App-Only authentication with Search Recent Tweets and Tweet counts API calls implemented. Contributions to increase API coverage are always welcome!  

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

