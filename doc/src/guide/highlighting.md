---
title: Highlighting
layout: guide.mustache
---

# Highlighting

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
