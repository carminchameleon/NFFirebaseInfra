// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FirebaseInfra",
    platforms: [
        .iOS(.v14), // ✅ iOS만 지원
        .macOS(.v15)
   ],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "FirebaseInfra",
            targets: ["FirebaseInfra"]),
    ],
    dependencies: [
      .package(url: "https://github.com/firebase/firebase-ios-sdk", from: "11.12.0")
    ],

    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "FirebaseInfra",
            dependencies: [
                .product(name: "FirebaseFirestore", package: "firebase-ios-sdk"),
                .product(name: "FirebaseRemoteConfig", package: "firebase-ios-sdk"),
                .product(name: "FirebaseStorage", package: "firebase-ios-sdk")
                ]
        ),

    ]
)

