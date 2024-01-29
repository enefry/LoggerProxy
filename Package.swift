// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "LoggerProxy",
  platforms: [
    .iOS(.v13),
    .macOS(.v11)
  ],
  products: [
    .library(name: "LoggerProxy", targets: ["LoggerProxy"]),
  ],
  dependencies: [
  ],
  targets: [
    .target(
            name: "LoggerProxy",
            path: "LoggerProxy"
        ),
  ]
)
