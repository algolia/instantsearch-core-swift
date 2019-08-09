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

#### Swift 4.2+

```ruby
pod 'InstantSearchCore', '~> 6.0'
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

#### Swift 4.2+

```ruby
github "algolia/instantsearch-core-swift" ~> 6.0 
```

#### Swift 4.1

```ruby
github "algolia/instantsearch-core-swift" ~> 3.3 
```

# License

InstantSearch Core iOS is [Apache 2.0 licensed](LICENSE.md).
