Algolia Search Helper for Swift
===============================


## Overview

This is the **Algolia Search Helper** library for Swift, built on top of Algolia's [Swift API Client](https://github.com/algolia/algoliasearch-client-swift), using Algolia's [Search API](https://www.algolia.com/).


### Rationale

While the [API Client](https://github.com/algolia/algoliasearch-client-swift) covers the entire feature set of the Search API, it aims primarily at efficiency and simplicity. It does not provide much beyond raw search requests.

However, when building a search UI, especially in an as-you-type setting, more work is usually required that just issuing requests. The Helper takes you one step further and focuses on managing a **search session**.


### Features

The core of the Helper is the `Searcher` class, which manages a search session on a given index. It takes care of properly **sequencing** received results (which may come out-of-order due to network unpredictability), and **pagination**. It also provides tools to manipulate **facets and refinements**.

The `HighlightRenderer` class takes care of transforming marked up text such as found in search result highlights into attributed text suitable for display.


### Supported platforms

The library is written in Swift, but is fully compatible with Objective-C.

It supports every platform that the [API Client](https://github.com/algolia/algoliasearch-client-swift) supports (at the time of writing: iOS, macOS and tvOS).


### Dependencies

This module requires Algolia's [Swift API Client](https://github.com/algolia/algoliasearch-client-swift).



## Quick start

### Setup

1. Add a dependency on "AlgoliaSearch-Helper-Swift":

    - CocoaPods: add `pod 'AlgoliaSearch-Helper-Swift', '~> 1.0'` to your Podfile.

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
let searcher = Searcher(index, resultHandler: self.handleResults) // a closure is accepted as well
```

The searcher will call you back after each request, unless the request has been cancelled because newer results have already been received. Typically, you will check for errors, then reload your UI:

```swift
func handleResults(results: SearchResults?, error: NSError?) {
    guard let results = results else { return }
    self.tableView.reloadData()
}
```

The searcher will only launch a request when you call its `search()` method:

```swift
searcher.query.query = "paris"
searcher.query.facets = ["stars", "facilities"]
searcher.search()
```


### Faceting

The searcher maintains a list of refined values for every facet, in the `refinements` property. Typically, you don't manipulate this property directly; instead, you call the convenience methods `hasFacetRefinement()`, `addFacetRefinement()`, `removeFacetRefinement()` and `toggleFacetRefinement()`.

The searcher also keeps track of which facets are disjunctive (`OR`) via the `disjunctiveFacets` property; all facets not listed in this property are considered to be conjunctive (`AND`).

When a search is triggered, the searcher will build the `facetFilters` according to the refinements and the conjunctive/disjunctive state.

*Note: You need to specify the list of all facets via the search query's `facets` parameter.*

*Note: The search query's `facetFilters` parameter will be overridden by the searcher; any manually specified value will be lost.*



## Highlighting

The `HighlightRenderer` class is in charge of parsing highlight result values (as returned by the Search API in the `_highlightResults` attribute of every hit) and render them into a rich text string (an `NSAttributedString` instance).

When you instantiate a highlight renderer, you specify a set of **text attributes** that will be applied to highlighted portions. For example, the following code will give you truly ugly red-on-yellow highlights:

```swift
let renderer = HighlightRenderer(highlightAttrs: [
    NSForegroundColorAttributeName: UIColor.redColor(),
    NSBackgroundColorAttributeName: UIColor.yellowColor(),
]
```

By default, the renderer is set to recognized `<em>` tags, which are the default tags used by the Search API to mark up highlights. However, you can easily override that to a custom value. *Note: In that case, make sure that it matches the values for `highlightPreTag` and `highlightPostTag` in your search query (or your index's default)!*

```swift
renderer.preTag = "<mark>"
renderer.postTag = "</mark>"
```

Once the renderer is set, rendering highlights is just a matter of calling `render()`. The real trick is to retrieve the highlighted value from the JSON... Fortunately, the `SearchResults` class makes it easy:

```swift
let searchResults: SearchResults = ... // whatever results received by the result handler
let index: Int = ... // index of the hit you want to retrieve
if let highlightResult = searchResults.highlightResult(index, path: "attribute_name") {
    if let highlightValue = highlightResult.value {
        let highlightedString = renderer.render(highlightValue)
    }
}
```
