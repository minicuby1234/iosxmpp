import PackageDescription

let package = Package(
    name: "XMPPClient",
    platforms: [
        .iOS(.v16)
    ],
    dependencies: [
        .package(url: "https://github.com/robbiehanson/XMPPFramework.git", .upToNextMajor(from: "4.1.0")),
        .package(url: "https://github.com/signalapp/libsignal-client.git", .upToNextMajor(from: "0.21.0")),
        .package(url: "https://github.com/stasel/WebRTC.git", .upToNextMajor(from: "1.1.0"))
    ],
    targets: [
        .target(
            name: "XMPPClient",
            dependencies: [
                .product(name: "XMPPFramework", package: "XMPPFramework"),
                .product(name: "XMPPFrameworkSwift", package: "XMPPFramework"),
                .product(name: "LibSignalClient", package: "libsignal-client"),
                .product(name: "WebRTC", package: "WebRTC")
            ]
        )
    ]
)
