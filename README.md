InstantSearch Core for Swift
============================

**Warning:** *Beta version. Until version 1.0 is released, incompatible changes may occur.*

This is the **InstantSearch Core** library for Swift and Objective-C, built on top of Algolia's [Swift API Client](https://github.com/algolia/algoliasearch-client-swift), using Algolia's [Search API](https://www.algolia.com/). It works on macOS, iOS, tvOS and watchOS.

*Table of Contents*

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Searching](#searching)
4. [Highlighting](#highlighting)
5. [Miscellaneous](#miscellaneous)


## Overview

### Rationale

While the API Client covers the entire feature set of the Search API, it primarily aims at efficiency and simplicity. It does not provide much beyond raw search requests.

However, when building a search UI, especially in an as-you-type setting, more work is usually required that just issuing requests. InstantSearch takes you one step further by focusing on **search session** management.


### Features

The central point of InstantSearch Core is the `Searcher` class, which manages searches on a given index. It takes care of properly **sequencing** received results (which may come out-of-order due to network unpredictability) and **pagination**. It also provides tools to manipulate **facet filters** and **numeric filters**.

The `Highlighter` class takes care of transforming marked up text such as found in search result highlights into attributed text suitable for display.

Other miscellaneous utilities are provided as well.

**Note:** *InstantSearch Core is UI-agnostic.* Although some features (such as highlight rendering) are only useful in the context of a user interface, the library itself has no dependencies on a specific UI framework. For example, it can indiscriminately be used on iOS with UIKit or macOS with AppKit. It has no system dependencies beyond Foundation (see below).


### Supported platforms

The library is written in Swift, but is fully compatible with Objective-C.

It supports every platform that the [API Client](https://github.com/algolia/algoliasearch-client-swift) supports (at the time of writing: iOS, macOS and tvOS).


### Dependencies

This module requires:

- Algolia's [Swift API Client](https://github.com/algolia/algoliasearch-client-swift).
- Apple's Foundation framework.



## Quick start

### Setup

- Add a dependency on "InstantSearch-Core-Swift":

    - CocoaPods: add `pod 'InstantSearch-Core-Swift', '~> 1.0'` to your `Podfile`.

    - Carthage is not supported. [Wondering why?](#why-is-carthage-not-supported)

- Add `import InstantSearchCore` to your source files.

**Note:** If you wish to use the API Client's offline mode, use the subspec `InstantSearch-Core-Offline-Swift` instead.


### Examples

A good start is our [Movie Search demo](https://github.com/algolia/algolia-swift-demo), which makes extensive use of the InstantSearch.



## Searching

### Basics

First create a `Client` and an `Index` as you would do with the bare API Client:

```swift
let client = Client(appID: "YOUR_APP_ID", apiKey: "YOUR_API_KEY")
let index = client.index(withName: "index_name")
```

Then create a `Searcher` targeting the index; you typically specify a result handler during creation (although you can register more later):

```swift
let searcher = Searcher(index: index, resultHandler: self.handleResults)
```

A closure is accepted as well:

```swift
let searcher = Searcher(index: index, resultHandler: { (results: SearchResults?, error: NSError?) in
    // Your code goes here.
})
```

The searcher will only launch a request when you call its `search()` method. Before you search, of course, you will want to modify the **search parameters** via the `params` property (a `SearchParameters` instance):

```swift
searcher.params.query = "hotel"
searcher.params.aroundLatLngViaIP = true
searcher.search()
```

### Handling results

The searcher will call your result handler after each request, when the response is received, *unless the request has been cancelled* (e.g. because newer results have already been received). Typically, your result handler will check for errors, store the hits in some data structure, then reload your UI:

```swift
func handleResults(results: SearchResults?, error: Error?) {
    guard let results = results else { return }
    self.hits = results.hits
    self.tableView.reloadData()
}
```

The `SearchResults` class is a wrapper around the JSON response received from the API. You can always access the underlying JSON directly through the `content` property. However, the fields you will most likely are also exposed via typed properties, such as `hits` or `nbHits`. You also get convenience accessors for:

- facet values (`facets(name:)`) and statistics (`facetStats(name:)`);
- highlights (`highlightResult(at:path:)`) and snippet results (`snippetResult(at:path:)`)
- ranking information (`rankingInfo(at:)`)

Please note that not every piece of information may be present in the response; it depends on your request.


### Continuous scrolling

The searcher facilitates the implementation of continuous scrolling through its `loadMore()` method. Fetching the next page of results is as easy as calling this method.

Note that if you use continuous scrolling, then you must take care to *append* hits to your internal data structure instead of erasing them. Using the `page` property is usually sufficient:

```swift
if results.page == 0 {
    self.hits = results.hits
} else {
    self.hits.append(contentsOf: results.hits)
}
```

When should you call `loadMore()`? Whenever your UI detects the need to fetch more data. Note that, in order to provide a smooth scrolling experience, it is wiser to pre-fetch data before it is required. A good indicator is when your table view or collection view data source is called for cells near the end of the currently available data. Alternatively, you can use the `UICollectionView` data source pre-fetching introduced in iOS 10.

The `loadMore()` method is guarded against concurrent or inconsistent calls. If you try to call it while another request has already been issued, it will ignore the call.


### Filtering

#### Facets

The search parameters maintain a list of refined values for every facet, called **facet refinements**. A facet refinement is the combination of an attribute name and a value. Optionally, the refinement can be negated (i.e. treated as exclusive rather than inclusive).

To edit the refinements, use the facet refinement handling methods, like `addFacetRefinement(name:value:)`, `removeFacetRefinement(name:value:)` and `toggleFacetRefinement(name:value:)`.

A given facet can be treated as either **conjunctive** (the default---refinements combined with an `AND` operator) or **disjunctive** (refinements combined with an `OR`). You can modify the conjunctive/disjunctive status of a facet by calling `setFacet(withName:disjunctive:)`.

When a search is triggered, the searcher will build the facet filters according to the refinements and the
conjunctive/disjunctive state of each facet.

**Note:** *You still need to specify the list of all facets via the `facets` search parameter.*

**Note:** *The `filters` and `facetFilters` search parameters will be overridden by the facet refinements; any manually specified value will be lost.*


#### Numeric filters

The search parameters also provide tools to easily manipulate numeric filters, through the notion of **numeric refinements**. A numeric refinement is basically made of an attribute name (the left operand), a comparison operator and a value (right operand). Optionally, the expression can be negated.

The numeric refinement handling methods work in a very similar fashion to the facet refinements (see above):

- A given numeric attribute can be treated as either conjunctive (the default) or disjunctive. The conjunctive/disjunctive status is modified via `setNumeric(withName:disjunctive:)`.

- Numeric refinements are edited via `addNumericRefinement(...)` and `removeNumericRefinement(...)`.

**Note:** *The `filters` and `numericFilters` search parameters will be overridden by the numeric refinements; any manually specified value will be lost.*


### Events

The `Searcher` class emits notifications through `NSNotificationCenter` on various events of its lifecycle:

- `Searcher.SearchNotification` when a new request is fired
- `Searcher.ResultNotification` when a successful response is received
- `Searcher.ErrorNotification` when an erroneous response is received

You may subscribe to these notifications to react on different events without having to explicitly write a result handler.


## Highlighting

The `Highlighter` class is in charge of parsing highlight result values (as returned by the Search API in the `_highlightResults` attribute of every hit) and render them into a rich text string (an `NSAttributedString` instance).

When you instantiate a highlight renderer, you specify a set of **text attributes** that will be applied to highlighted portions. For example, the following code will give you truly ugly red-on-yellow highlights:

```swift
let renderer = Highlighter(highlightAttrs: [
    NSForegroundColorAttributeName: UIColor.red,
    NSBackgroundColorAttributeName: UIColor.yellow,
]
```

By default, the renderer is set to recognized `<em>` tags, which are the default tags used by the Search API to mark up highlights. However, you can easily override that to a custom value.

**Note:** *In that case, make sure that it matches the values for `highlightPreTag` and `highlightPostTag` in your search query (or your index's default)!*

```swift
renderer.preTag = "<mark>"
renderer.postTag = "</mark>"
```

Once the renderer is set, rendering highlights is just a matter of calling `render(text:)`. The real trick is to retrieve the highlighted value from the JSON... Fortunately, the `SearchResults` class makes it easy:

```swift
let searchResults: SearchResults = ... // whatever was received by the result handler
let index: Int = ... // index of the hit you want to retrieve
if let highlightResult = searchResults.highlightResult(at: index, path: "attribute_name") {
    if let highlightValue = highlightResult.value {
        let highlightedString = renderer.render(text: highlightValue)
    }
}
```



## Miscellaneous

### Debouncing

"Debouncing" is the process of ignoring too frequent events, keeping only the last one in a series of adjacent events.

The `Debouncer` class provides a generic way of debouncing calls. It can be useful to avoid triggering too many search requests, for example when a UI widget is continuously firing updates (e.g. a slider).

### Why is Carthage not supported?

InstantSearch Core has an external dependency (on the Algolia Search API Client). A package manager is therefore required to draw that dependency. Cocoapods works by adding special build phases to the Xcode project (in addition to creating a Pods project and an Xcode workspace referencing both). Because of this, it is technically impossible to support both Cocoapods and Carthage on the same project when it has external dependencies. Because Cocoapods has a wider audience than Carthage, we chose the former.
