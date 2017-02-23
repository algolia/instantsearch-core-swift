---
title: Miscellaneous
layout: guide.mustache
---

# Miscellaneous

## Debouncing

"Debouncing" is the process of ignoring too frequent events, keeping only the last one in a series of adjacent events.

The `Debouncer` class provides a generic way of debouncing calls. It can be useful to avoid triggering too many search requests, for example when a UI widget is continuously firing updates (e.g. a slider).

## Why is Carthage not supported?

InstantSearch Core has an external dependency (on the Algolia Search API Client). A package manager is therefore required to draw that dependency. Cocoapods works by adding special build phases to the Xcode project (in addition to creating a Pods project and an Xcode workspace referencing both). Because of this, it is technically impossible to support both Cocoapods and Carthage on the same project when it has external dependencies. Because Cocoapods has a wider audience than Carthage, we chose the former.
