[![Pod Version](http://img.shields.io/cocoapods/v/InstantSearchCore.svg?style=flat)](https://github.com/algolia/instantsearch-core-swift/)
[![Pod Platform](http://img.shields.io/cocoapods/p/InstantSearchCore.svg?style=flat)](https://github.com/algolia/instantsearch-core-swift/)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-brightgreen.svg)](https://github.com/algolia/instantsearch-core-swift/)
[![SwiftPM compatible](https://img.shields.io/badge/SwiftPM-compatible-brightgreen.svg)](https://swift.org/package-manager/)
[![Mac Catalyst compatible](https://img.shields.io/badge/Catalyst-compatible-brightgreen.svg)](https://developer.apple.com/documentation/xcode/creating_a_mac_version_of_your_ipad_app/)
[![Licence](http://img.shields.io/cocoapods/l/InstantSearchCore.svg?style=flat)](https://opensource.org/licenses/MIT)

# InstantSearch iOS

If you're looking to build search interfaces on iOS with Algolia, then you should check out [InstantSearch iOS](https://github.com/algolia/instantsearch-ios) which is built on top of this library, and provides UI building blocks to build search experiences. Otherwise, keep reading.

# InstantSearch Core for Swift

This is the **InstantSearch Core** library for Swift, built on top of Algolia's [Swift API Client](https://github.com/algolia/algoliasearch-client-swift), using Algolia's [Search API](https://www.algolia.com/). It works on macOS, iOS, tvOS and watchOS.

You can always find the latest version of the **user documentation** on [Algolia Documentation](https://www.algolia.com/doc/api-reference/widgets/ios/).

## Installation

If you use Swift version earlier than 4.2, you have to use the version 3.3 of InstantSearch Core.
This version is outdated and not recommended for use. 

### CocoaPods

[CocoaPods](https://cocoapods.org/) is a dependency manager for Cocoa projects.

To install InstantSearch, simply add the following line to your Podfile:


#### Swift 5.0+

```ruby
pod 'InstantSearchCore', '~> 7.0'
```

#### Swift 4.2+

```ruby
pod 'InstantSearchCore', '~> 5.0'
```

#### Swift 4.1

```ruby
pod 'InstantSearchcore', '~> 3.3'
```

Then, run the following command:

```bash
$ pod update
```

### Carthage

[Carthage](https://github.com/Carthage/Carthage) is a simple, decentralized dependency manager for Cocoa.

To install InstantSearch, simply add the following line to your Cartfile:


#### Swift 5.0+

```ruby
github "algolia/instantsearch-core-swift" ~> 7.0
```

Then launch the following commands from the project directory
```shell
carthage update
./Carthage/Checkouts/instantsearch-core-swift/carthage-prebuild
carthage build
```

#### Swift 4.2+

```ruby
github "algolia/instantsearch-core-swift" ~> 5.0 
```

#### Swift 4.1

```ruby
github "algolia/instantsearch-core-swift" ~> 3.3 
```

#### Swift Package Manager

[Swift Package Manager](https://swift.org/package-manager/) (SwiftPM) is a tool for managing the distribution of Swift code as well as C-family dependency. From Xcode 11, SwiftPM got natively integrated with Xcode.

InstantSearch Core support SwiftPM from version 6.4.0. To use SwiftPM, you should use Xcode 11 to open your project. Click `File` -> `Swift Packages` -> `Add Package Dependency`, enter [InstantSearch Core repo's URL](https://github.com/algolia/instantsearch-core-swift.git).
After select the package, you can choose the dependency type (tagged version, branch or commit). Then Xcode will setup all the stuff for you.

If you're a framework author and use InstantSearch Core  as a dependency, update your `Package.swift` file:

```swift
let package = Package(
    // ...
    dependencies: [
        .package(name: "InstantSearchCore", url: "https://github.com/algolia/instantsearch-core-swift", from: "7.0")
    ],
    // ...
)
```


# License

InstantSearch Core iOS is [Apache 2.0 licensed](LICENSE.md).