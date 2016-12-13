Change Log
==========


## 0.3.1 (2016-12-13)

### Bug fixes

- Fix handling of numeric refinements when disjunctive faceting is used


## 0.3 (2016-12-06)

- [refact] Rebrand as "InstantSearch Core for Swift". **Breaking change:** Names of Git repository, module and pod have changed.
- The `Searcher` class now accepts a delegate (in addition to result handlers and event notifications)
- [refact] New handling of query numeric and facet filters
- [doc] New documentation structure
- [test] Add unit tests for `Highlighter`


## 0.2 (2016-09-14)

### New features

- Support **Swift 3**
    - The naming has been revised to comply with the Swift API Design Guidelines
    - Better Objective-C mappings
- New `SearchProgressController` class

### Bug fixes

- Fix memory leaks
- Improve request cancellation


## 0.1 (2016-08-16)

**Warning:** Beta version. Until version 1.0 is released, incompatible changes may occur.

### New features

- `Searcher` class to manage a search session
- `HighlightRenderer` class to render highlight markup into rich text
- `Debouncer` class to debounce frequent calls
