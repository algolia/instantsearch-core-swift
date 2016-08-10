Algolia Search Helper for Swift
===============================


This is the **Algolia Search Helper** library for Swift, built on top of Algolia's [Swift API Client](https://github.com/algolia/algoliasearch-client-swift), using Algolia's [Search API](https://www.algolia.com/).

*Table of Contents*

1. [Overview](#overview)
2. [Quick Start](#quick-start)
3. [Searching](#searching)
4. [Highlighting](#highlighting)
5. [Miscellaneous](#miscellaneous)


## Overview

### Rationale

While the API Client covers the entire feature set of the Search API, it primarily aims at efficiency and simplicity. It does not provide much beyond raw search requests.

However, when building a search UI, especially in an as-you-type setting, more work is usually required that just issuing requests. The Search Helper takes you one step further by focusing on **search session** management.


### Features

The core of the Helper is the `Searcher` class, which manages searches on a given index. It takes care of properly **sequencing** received results (which may come out-of-order due to network unpredictability) and **pagination**. It also provides tools to manipulate **facets and refinements**.

The `HighlightRenderer` class takes care of transforming marked up text such as found in search result highlights into attributed text suitable for display.

Other miscellaneous utilities are provided as well.

**Note:** *The Search Helper is UI-agnostic.* Although some features (such as highlight rendering) are only useful in the context of a user interface, the helper has no dependencies on a specific UI framework. For example, it can indiscriminately be used on iOS with UIKit or macOS with AppKit. It has no system dependencies beyond Foundation (see below).


### Supported platforms

The library is written in Swift, but is fully compatible with Objective-C.

It supports every platform that the [API Client](https://github.com/algolia/algoliasearch-client-swift) supports (at the time of writing: iOS, macOS and tvOS).


### Dependencies

This module requires:

- Algolia's [Swift API Client](https://github.com/algolia/algoliasearch-client-swift).
- Apple's Foundation framework.



## Quick start

### Setup

1. Add a dependency on "AlgoliaSearch-Helper-Swift":
    - CocoaPods: add `pod 'AlgoliaSearch-Helper-Swift', '~> 1.0'` to your `Podfile`.
    - Carthage: not supported so far.
2. Add `import AlgoliaSearchHelper` to your source files.

**Note:** If you wish to use the API Client's offline mode, use the subspec `AlgoliaSearch-Helper-Swift/Offline` instead.


### Examples

A good start is our [Movie Search demo](https://github.com/algolia/algolia-swift-demo), which makes extensive use of the Search Helper.



## Searching

### Basics

First create a `Client` and an `Index` as you would do with the bare API Client:

```swift
let client = Client(appID: "YOUR_APP_ID", apiKey: "YOUR_API_KEY")
let index = client.getIndex("index_name")
```

Then create a `Searcher` targeting the index; you typically specify a result handler during creation (although you can register more later):

```swift
let searcher = Searcher(index, resultHandler: self.handleResults)
```

A closure is accepted as well:

```swift
let searcher = Searcher(index, resultHandler: { (results: SearchResults?, error: NSError?) in
    // Your code goes here.
})
```

The searcher will only launch a request when you call its `search()` method. Before you search, of course, you will want to modify the search query:

```swift
searcher.query.query = "paris"
searcher.query.numericFilters = ["stars>=4"]
searcher.search()
```

### Handling results

The searcher will call your result handler after each request, when the response is received, *unless the request has been cancelled* (e.g. because newer results have already been received). Typically, your result handler will check for errors, store the hits in some data structure, then reload your UI:

```swift
func handleResults(results: SearchResults?, error: NSError?) {
    guard let results = results else { return }
    self.hits = results.hits
    self.tableView.reloadData()
}
```

The `SearchResults` class is a wrapper around the JSON response received from the API. You can always access the underlying JSON directly through the `content` property. However, the fields you will most likely are also exposed via typed properties, such as `hits` or `nbHits`. You also get convenience accessors for:

- facet values (`facets()`) and statistics (`facetStats()`);
- highlights (`highlightResult()`) and snippet results (`snippetResult()`)
- ranking information (`rankingInfo()`)

Please note that not every piece of information may be present in the response; it depends on your request.


### Continuous scrolling

The searcher facilitates the implementation of continuous scrolling through its `loadMore()` method. Fetching the next page of results is as easy as calling this method.

Note that if you use continuous scrolling, then you must take care to *append* hits to your internal data structure instead of erasing them. Using the `page` property is usually sufficient:

```swift
if results.page == 0 {
    self.hits = results.hits
} else {
    self.hits.appendContentsOf(results.hits)
}
```

When should you call `loadMore()`? Whenever your UI detects the need to fetch more data. Note that, in order to provide a smooth scrolling experience, it is wiser to pre-fetch data before it is required. A good indicator is when your table view or collection view data source is called for cells near the end of the currently available data. Alternatively, you can use the `UICollectionView` data source pre-fetching introduced in iOS 10.

The `loadMore()` method is guarded against concurrent or inconsistent calls. If you try to call it while another request has already been issued, it will ignore the call.


### Faceting

The searcher maintains a list of refined values for every facet, in the `refinements` property. Typically, you don't manipulate this property directly; instead, you call the convenience methods `hasFacetRefinement()`, `addFacetRefinement()`, `removeFacetRefinement()` and `toggleFacetRefinement()`.

The searcher also keeps track of which facets are disjunctive (`OR`) via the `disjunctiveFacets` property; all facets not listed in this property are considered to be conjunctive (`AND`).

When a search is triggered, the searcher will build the `facetFilters` according to the refinements and the conjunctive/disjunctive state.

**Note:** *You need to specify the list of all facets via the search query's `facets` parameter.*

**Note:** *The search query's `facetFilters` parameter will be overridden by the searcher; any manually specified value will be lost.*


### Events

The `Searcher` class emits notifications through `NSNotificationCenter` on various events of its lifecycle:

- `Searcher.SearchNotification` when a new request is fired
- `Searcher.ResultNotification` when a successful response is received
- `Searcher.ErrorNotification` when an erroneous response is received

You may subscribe to these notifications to react on different events without having to explicitly write a result handler.


## Highlighting

The `HighlightRenderer` class is in charge of parsing highlight result values (as returned by the Search API in the `_highlightResults` attribute of every hit) and render them into a rich text string (an `NSAttributedString` instance).

When you instantiate a highlight renderer, you specify a set of **text attributes** that will be applied to highlighted portions. For example, the following code will give you truly ugly red-on-yellow highlights:

```swift
let renderer = HighlightRenderer(highlightAttrs: [
    NSForegroundColorAttributeName: UIColor.redColor(),
    NSBackgroundColorAttributeName: UIColor.yellowColor(),
]
```

By default, the renderer is set to recognized `<em>` tags, which are the default tags used by the Search API to mark up highlights. However, you can easily override that to a custom value. **Note:** *In that case, make sure that it matches the values for `highlightPreTag` and `highlightPostTag` in your search query (or your index's default)!*

```swift
renderer.preTag = "<mark>"
renderer.postTag = "</mark>"
```

Once the renderer is set, rendering highlights is just a matter of calling `render()`. The real trick is to retrieve the highlighted value from the JSON... Fortunately, the `SearchResults` class makes it easy:

```swift
let searchResults: SearchResults = ... // whatever was received by the result handler
let index: Int = ... // index of the hit you want to retrieve
if let highlightResult = searchResults.highlightResult(index, path: "attribute_name") {
    if let highlightValue = highlightResult.value {
        let highlightedString = renderer.render(highlightValue)
    }
}
```



## Miscellaneous

### Debouncing

"Debouncing" is the process of ignoring too frequent events, keeping only the last one in a series of adjacent events.

The `Debouncer` class provides a generic way of debouncing calls. It can be useful to avoid triggering too many search requests, for example when a UI widget is continuously firing updates (e.g. a slider).
