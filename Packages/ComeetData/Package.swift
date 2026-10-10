// swift-tools-version: 6.4
import PackageDescription

let package = Package(
    name: "ComeetData",
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [.library(name: "ComeetData", targets: ["ComeetData"])],
    targets: [.target(name: "ComeetData"), .testTarget(name: "ComeetDataTests", dependencies: ["ComeetData"])]
)
