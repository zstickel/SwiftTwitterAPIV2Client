# SwiftTwitterAPIV2Client

Swift client for the Twitter API v2.

You can use The Swift Package Manager to install SwiftTwitterAPIV2Client by adding the proper description to your Package.swift file:

// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "YOUR_PROJECT_NAME",
    dependencies: [
        .package(url: "https://github.com/", from: "5.5.5"),
    ]
)

Initialization:
let twitterClient = TwitterClient(consumerKey: CONSUMER_KEY, consumerSecret: CONSUMER SECRET)

Sample asyncronous usage:
let result = await twitterClient.searchRecentTweets(searchString: searchString,isVerified: false, maxResults: 20, language: .english)



Sample usage with callback:
twitterClient.searchRecentTweets(searchString: searchString,isVerified: false, maxResults: 20, language: .english){result in
    //Code to execute
}
