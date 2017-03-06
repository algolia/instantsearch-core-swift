//
//  Copyright (c) 2017 Algolia
//  http://www.algolia.com/
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

import AlgoliaSearch
import Foundation


/// Records a history of searches.
///
@objc public class HistoryRecorder: NSObject {
    /// The searcher being observed.
    @objc public let searcher: Searcher
    
    /// The history being fed.
    @objc public let history: History
    
    @objc public var delay: TimeInterval = 1.0 {
        didSet {
            debouncer.delay = self.delay
        }
    }

    /// Debouncer used to avoid updating the history after each keystroke.
    private let debouncer: Debouncer

    /// Create a new recorder observing a searcher and feeding a history.
    ///
    /// - parameter searcher: The searcher to observer.
    /// - parameter history: The history to feed.
    ///
    @objc public init(searcher: Searcher, history: History) {
        self.searcher = searcher
        self.history = history
        self.debouncer = Debouncer(delay: self.delay)
        super.init()
        NotificationCenter.default.addObserver(forName: Searcher.SearchNotification, object: searcher, queue: nil) { (notification) in
            // TODO: Handle final searches via metadata.
            self.debouncer.call {
                guard let params = notification.userInfo?[Searcher.notificationParamsKey] as? SearchParameters else { return }
                self.history.add(query: params)
            }
        }
    }
}

/// Manages a history of previous searches.
///
@objc public protocol History {
    /// Add a new query to the history.
    ///
    /// - parameter query: The query to add.
    ///
    @objc func add(query: SearchParameters)
    
    /// Search the history.
    ///
    /// - parameter query: The searched query.
    /// - parameter options: Search options.
    /// - returns: A list of matching queries in the history.
    ///
    @objc func search(query: SearchParameters, options: HistorySearchOptions) -> [SearchParameters]
}

/// Options when searching a `History`.
///
@objc public class HistorySearchOptions: NSObject {
    /// Whether hits should be highlighted.
    public var highlighted: Bool = false
    
    /// Tag prepended to highlights.
    public var highlightPreTag: String = "<em>"
    
    /// Tag appended to highlights.
    public var highlightPostTag: String = "</em>"
}

/// A history that sits in the local device.
/// By default, the history sits purely in memory. If `filePath` is set, it is also persisted on disk.
///
@objc public class LocalHistory: NSObject, History {
    // MARK: Properties
    
    /// The in-memory cache of the history's content.
    private var queries: NSMutableOrderedSet = NSMutableOrderedSet()

    /// The history's content.
    @objc public var contents: [String] {
        return queries.array as! [String]
    }
    
    /// Maximum number of entries allowed in this history. Default = 10.
    public var maxCount: Int = 10 {
        didSet {
            purge()
        }
    }
    
    /// Whether each query added automatically trigges a save. Default = true.
    ///
    /// + Note: The save will be performed asynchronously for better performance.
    ///
    public var autosave: Bool = true
    
    /// File path to the history on disk.
    /// If nil (default), the history will sit purely in memory.
    public var filePath: String?
    
    // MARK: Initialization
    
    /// Create a new, empty history that sits purely in memory.
    public override init() {
    }
    
    /// Create a new history that is persisted on disk.
    public init(filePath: String) {
        self.filePath = filePath
        super.init()
        self.load()
    }
    
    // MARK: History management
    
    /// Search the history.
    ///
    /// + Complexity: O(n): grows linearly with the size of the history.
    ///   This should remain acceptable if the history is small (a few tens of entries).
    ///
    @objc public func search(query: SearchParameters, options: HistorySearchOptions = HistorySearchOptions()) -> [SearchParameters] {
        guard let text = query.query else {
            return []
        }
        let searchedText = normalize(text)
        if searchedText.isEmpty {
            return []
        }
        // Only search for the text at the beginning of a word.
        let searchedPattern = "\\b" + searchedText
        var hits: [SearchParameters] = []
        for query in queries {
            let queryString = query as! String
            // TODO: Implement anchoring on words.
            if let foundRange = queryString.range(of: searchedPattern, options: .regularExpression) {
                var hit: String
                if options.highlighted {
                    // NOTE: We don't handle multiple occurrences as they are assumed to be rare.
                    // Also, highlighting would be weird in a suggestion context.
                    hit = queryString.substring(to: foundRange.lowerBound) + options.highlightPreTag + queryString.substring(with: foundRange) + options.highlightPostTag + queryString.substring(from: foundRange.upperBound)
                } else {
                    hit = queryString
                }
                let query = SearchParameters()
                query.query = hit
                hits.append(query)
            }
        }
        return hits
    }
    
    @objc public func add(query: SearchParameters) {
        guard var newText = query.query else { return }
        
        // Normalize query string.
        newText = normalize(newText)
        if newText.isEmpty {
            return
        }
        
        // Add or update the query.
        let index = queries.index(of: newText)
        if index != NSNotFound {
            // If the text is found exactly, just move it to the front of the queue (LRU).
            queries.moveObjects(at: IndexSet(integer: index), to: 0)
        } else {
            // Check that the new text is not redundant with existing texts:
            // - If the new text is a prefix of an existing text, reject it, unless it ends on a word boundary.
            // - If an existing text is a prefix of the new text, replace it, unless it ends on a word boundary.
            var redundant = false
            if let newTextPrefixPattern = try? NSRegularExpression(pattern: "^" + newText + "(?!\\b)", options: .useUnicodeWordBoundaries) {
                for i in 0 ..< queries.count {
                    let oldText = queries[i] as! String
                    if newTextPrefixPattern.firstMatch(in: oldText, range: NSMakeRange(0, (oldText as NSString).length)) != nil {
                        // New text is a prefix of the old text, not ending on a word boundary.
                        redundant = true
                        break
                    }
                    guard let oldTextPrefixPattern = try? NSRegularExpression(pattern: "^" + oldText + "(?!\\b)", options: .useUnicodeWordBoundaries) else { continue }
                    if oldTextPrefixPattern.firstMatch(in: newText, range: NSMakeRange(0, (newText as NSString).length)) != nil {
                        // Old text is a prefix of the new text, not ending on a word boundary.
                        redundant = true
                        // Update the existing entry...
                        queries[i] = newText
                        // ... and move it first.
                        queries.moveObjects(at: IndexSet(integer: i), to: 0)
                        break
                    }
                }
            }
            if !redundant {
                queries.insert(newText, at: 0)
            }
        }

        // Clean up.
        purge()
        saveIfNeeded()
    }
    
    @objc public func clear() {
        queries.removeAllObjects()
        saveIfNeeded()
    }
    
    // MARK: Persistence
    
    private func purge() {
        if queries.count > maxCount {
            queries.removeObjects(at: IndexSet(integersIn: Range(uncheckedBounds: (maxCount, queries.count))))
        }
    }
    
    private func saveIfNeeded() {
        if autosave && filePath != nil {
            saveAsync()
        }
    }

    /// Save the history to disk (synchronously).
    ///
    @objc public func save() {
        guard let filePath = filePath else { return }
        let values = queries.array
        do {
            let data = try PropertyListSerialization.data(fromPropertyList: values, format: .binary, options: 0)
            try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
        } catch _ {
            // Ignore
        }
    }

    /// Save the history to disk (asynchronously).
    ///
    @objc public func saveAsync() {
        guard let filePath = filePath else { return }
        let values = queries.array
        DispatchQueue.global(qos: .background).async {
            do {
                let data = try PropertyListSerialization.data(fromPropertyList: values, format: .binary, options: 0)
                try data.write(to: URL(fileURLWithPath: filePath), options: .atomic)
            } catch _ {
                // Ignore
            }
        }
    }

    /// Load the history from disk (synchronously).
    ///
    @objc public func load() {
        guard let filePath = filePath else { return }
        do {
            let data = try Data(contentsOf: URL(fileURLWithPath: filePath))
            if let values = try PropertyListSerialization.propertyList(from: data, format: nil) as? [String] {
                queries = NSMutableOrderedSet(array: values)
            }
        } catch _ {
            // Ignore
        }
    }
    
    // MARK: Utils
    
    private let whitespaceRegex: NSRegularExpression = {
        return (try? NSRegularExpression(pattern: "\\s+"))!
    }()
    
    /// Normalize a string for storage in the history.
    ///
    private func normalize(_ text: String) -> String {
        return whitespaceRegex
            // Replace each sequence of whitespace by a single space.
            .stringByReplacingMatches(in: text, options: [], range: NSMakeRange(0, (text as NSString).length), withTemplate: " ")
            // Trim leading and trailing whitespace.
            .trimmingCharacters(in: .whitespaces)
            // Convert to lower case.
            .lowercased()
    }
}
