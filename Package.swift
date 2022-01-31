// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftTwitterAPIV2Client",
    platforms: [
        .macOS(.v10_15),.iOS(.v13)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "SwiftTwitterAPIV2Client",
            targets: ["SwiftTwitterAPIV2Client"]),
    ],
    
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
        .package(url: "https://github.com/Alamofire/Alamofire", .upToNextMajor(from: "5.5.0")),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON", .upToNextMajor(from: "4.0.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "SwiftTwitterAPIV2Client",
            dependencies: ["Alamofire","SwiftyJSON"]),
        .testTarget(
            name: "SwiftTwitterAPIV2ClientTests",
            dependencies: ["SwiftTwitterAPIV2Client"]),
    ]
)
