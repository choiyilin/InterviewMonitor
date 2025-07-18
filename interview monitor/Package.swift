// swift-tools-version:5.3
import PackageDescription

let package = Package(
    name: "InterviewMonitor",
    platforms: [
        .macOS(.v10_15)
    ],
    products: [
        .executable(name: "InterviewMonitor", targets: ["InterviewMonitor"])
    ],
    dependencies: [
        // Add any dependencies here
    ],
    targets: [
        .target(
            name: "InterviewMonitor",
            path: "Sources"
        ),
        .testTarget(
            name: "InterviewMonitorTests",
            dependencies: ["InterviewMonitor"],
            path: "Tests"
        )
    ]
)
