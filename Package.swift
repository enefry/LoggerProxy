// swift-tools-version:5.6

import PackageDescription

let package = Package(
  name: "LoggerProxy",
  platforms: [
    .iOS("13")
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
