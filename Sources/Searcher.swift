//
//  Copyright (c) 2016 Algolia
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


// ------------------------------------------------------------------------
// IMPLEMENTATION NOTES
// ------------------------------------------------------------------------
// # Sequencing logic
//
// An important part of the search helper is to manage the proper sequencing
// of search requests and responses.
//
// Conceptually, a search session can be seen as a sequence of *queries*,
// each query resulting in one or more *requests* to the API (one per page).
// Each request is assigned an auto-incremented sequence number.
//
// Example:
//
// ```
// Queries:    A --> B --> C --> D
//             |     |     |     |
// Requests:   1     2     4     6
//             …     |     |
//            (X)    3     5
// ```
//
// Now, there are important rules to guarantee a consistent behavior:
//
// 1. A `loadMore()` request for a query will be ignored if a more recent
//    query has already been requested.
//
//    For example, in the diagram above: request X (page 2 of query A) will
//    be ignored if request 2 (page 1 of query B) has already been sent.
//
// 2. Results for a request will be ignored if results have already been
//    received for a more recent request.
//
//    For example, in the diagram above: results for request 3 will be
//    ignored if results have already been received for request 4.
//
// ------------------------------------------------------------------------


/// Manages search on an Algolia index.
///
/// The purpose of this class is to maintain a state between searches and handle pagination.
///
@objc public class Searcher: NSObject {
    
    // MARK: Types
    
    /// Handler for search results.
    ///
    /// - parameter results: The results (in case of success).
    /// - parameter error: The error (in case of failure).
    ///
    public typealias ResultHandler = @convention(block) (_ results: SearchResults?, _ error: Error?) -> Void

    /// Pluggable state representation.
    private struct State: CustomStringConvertible {
        /// Search query.
        ///
        /// - Note: The page may be overridden when loading more content.
        ///
        var query: Query = Query()
        
        /// List of facets to be treated as disjunctive facets. Defaults to the empty list.
        var disjunctiveFacets: [String] = []
        
        /// Initial page.
        var initialPage: UInt { return query.page ?? 0 }
        
        /// Current page.
        var page: UInt = 0
        
        /// Whether the current page is the initial page for this search state.
        var isInitialPage: Bool { return initialPage == page }
        
        /// This state's sequence number.
        var sequenceNumber: Int = 0
        
        /// Construct a default state.
        init() {
        }

        // WARNING: Although `State` is a value type, `Query` is not (because of Objective-C bridgeability).
        // Consequently, the memberwise assignment of `State` leads to unintended state sharing.
        //
        // TODO: I found no way to customize the assignment of a struct in Swift (something like C++'s assignment
        // operator or copy constructor). So I resort to explicitly constructing copies so far.

        /// Copy a state.
        init(copy: State) {
            // WARNING: Query is not a value type (because of Objective-C bridgeability), so let's make sure to copy it.
            self.query = Query(copy: copy.query)
            self.disjunctiveFacets = copy.disjunctiveFacets
            self.page = copy.page
        }
        
        var description: String {
            return "State#\(sequenceNumber){query=\(query), disjunctiveFacets=\(disjunctiveFacets), page=\(page)}"
        }
    }
    
    // MARK: Properties

    /// The index used by this search helper.
    ///
    /// + Note: Modifying the index doesn't alter the searcher's state. In particular, pending requests are left
    /// running. Depending on your use case, you might want to call `reset()` after changing the index.
    ///
    @objc public var index: Index
    
    /// User callbacks for handling results.
    /// There should be at least one, but multiple handlers may be registered if necessary.
    ///
    private var resultHandlers: [ResultHandler] = []
    
    /// The query that will be used for the next search.
    ///
    /// **Warning:** The value of `facetFilters` will be discarded and overridden by the `refinements` property.
    @objc public var query: Query {
        get { return nextState.query }
        set { nextState.query = newValue }
    }
    
    /// The disjunctive facets that will be used for the next search.
    @objc public var disjunctiveFacets: [String] {
        get { return nextState.disjunctiveFacets }
        set { nextState.disjunctiveFacets = newValue }
    }
    
    /// Facet refinements that will be used for the next search. Maps facet names to a list of refined values.
    /// The format is the same as `Index.searchDisjunctiveFaceting()`.
    ///
    /// + Note: You are encouraged to use the helper methods to manipulate this property. See `hasFacetRefinement(_:value:)`,
    /// `addFacetRefinement(_:value:)`, `removeFacetRefinement(_:value:)` and `toggleFacetRefinement(_:value:)`.
    ///
    /// + Warning: Any refinements specified here will override those manually specified in `query`.
    ///
    @objc public var refinements: [String: [String]] = [:]
    
    // State management
    // ----------------
    
    /// Sequence number for the next request.
    private var nextSequenceNumber: Int = 0
    
    /// The state that will be used for the next search.
    /// It can be modified at will. It is not taken into account until the `search()` method is called; then it is
    /// copied and transferred to `requestedState`.
    private var nextState: State = State()

    /// The state corresponding to the last issued request.
    ///
    /// + Warning: Only valid after the first call to `search()`.
    ///
    private var requestedState: State!

    /// The state corresponding to the last received results.
    ///
    /// + Warning: Only valid after the first call to the result handler.
    ///
    private var receivedState: State!
    
    /// The last received results.
    private var results: SearchResults?
    
    /// All currently ongoing requests.
    private var pendingRequests: [Int: Operation] = [:]

    // MARK: - Initialization, termination
    
    /// Create a new searcher targeting the specified index.
    ///
    /// - parameter index: The index to target when searching.
    ///
    @objc public init(index: Index) {
        self.index = index
        super.init()
        updateClientUserAgents()
    }
    
    /// Create a new searcher targeting the specified index and register a result handler with it.
    ///
    /// - parameter index: The index to target when searching.
    /// - parameter resultHandler: The result handler to register.
    ///
    @objc public convenience init(index: Index, resultHandler: @escaping ResultHandler) {
        self.init(index: index)
        self.resultHandlers = [resultHandler]
    }
    
    /// Add the helper library's version to the client's user agents, if not already present.
    private func updateClientUserAgents() {
        let bundleInfo = Bundle(for: type(of: self)).infoDictionary!
        let name = bundleInfo["CFBundleName"] as! String
        let version = bundleInfo["CFBundleShortVersionString"] as! String
        let libraryVersion = LibraryVersion(name: name, version: version)
        let client = index.client
        if client.userAgents.index(where: { $0 == libraryVersion }) == nil {
            client.userAgents.append(libraryVersion)
        }
    }
    
    /// Register a result handler with this searcher.
    ///
    /// + Note: Because of the way closures are handled in Swift, the handler cannot be removed.
    ///
    @objc public func addResultHandler(_ resultHandler: @escaping ResultHandler) {
        self.resultHandlers.append(resultHandler)
    }
    
    /// Reset the search state.
    /// This resets the `query`, `disjunctiveFacets` and `refinements` properties. It also cancels any pending request.
    ///
    /// + Note: It does *not* remove registered result handlers.
    ///
    @objc public func reset() {
        query = Query()
        disjunctiveFacets.removeAll()
        refinements.removeAll()
        cancelPendingRequests()
    }
    
    // MARK: - Search
    
    /// Search using the current settings.
    /// This uses the current value for `query`, `disjunctiveFacets` and `refinements`.
    ///
    @objc public func search() {
        requestedState = State(copy: nextState)
        requestedState.page = requestedState.initialPage
        _doNextRequest()
    }
    
    /// Load more content, if possible.
    @objc public func loadMore() {
        if !canLoadMore() {
            return
        }
        if !hasMore() {
            return
        }
        let nextPage = receivedState.page + 1
        // Don't load more if already loading.
        if nextPage <= requestedState.page {
            return
        }
        // OK, everything's fine; let's go!
        requestedState.page = nextPage
        _doNextRequest()
    }
    
    /// Test whether the current state allows loading more results.
    /// Loading more requires that we have already received results (obviously) and also that another more recent
    /// request is not pending.
    ///
    /// + Note: It does indicate whether they are actually more results to load. For this, see `hasMore()`.
    ///
    /// - returns: true if the current state allows loading more results, false otherwise.
    ///
    private func canLoadMore() -> Bool {
        // Cannot load more when no results have been received.
        if results == nil {
            return false
        }
        // Must not load more if the results are outdated with respect to the currently on-going search.
        if requestedState.query != receivedState.query {
            return false
        }
        return true
    }
    
    /// Test whether the current results have more pages to load.
    ///
    /// - returns: true if more pages are available, false otherwise or if no results have been received yet.
    ///
    private func hasMore() -> Bool {
        // If no results have been received yet, there are obviously no additional pages.
        guard let receivedState = receivedState, let results = results else { return false }
        return receivedState.page + 1 < results.nbPages
    }
    
    private func _doNextRequest() {
        // Create a new request
        // --------------------
        var state = State(copy: requestedState)
        
        // Increase sequence number.
        let currentSeqNo = nextSequenceNumber
        state.sequenceNumber = currentSeqNo
        nextSequenceNumber += 1
        
        // Build query.
        let query = Query(copy: state.query)
        query.page = state.page
        query.facetFilters = [] // NOTE: will be overridden below
        
        // User info for notifications.
        let userInfo: [String: Any] = [
            Searcher.NotificationQueryKey: query,
            Searcher.NotificationSeqNoKey: currentSeqNo
        ]
        
        // Run request
        // -----------
        var operation: Operation!
        let completionHandler: CompletionHandler = {
            [weak self]
            (content, error) in
            // NOTE: We do not control the lifetime of the searcher. => Fail gracefully if already released.
            guard let this = self else {
                return
            }
            // Cancel all previous requests (as this one is deemed more recent).
            let previousRequests = this.pendingRequests.filter({ $0.0 < state.sequenceNumber })
            for (seqNo, _) in previousRequests {
                this.cancelRequest(seqNo: seqNo)
            }
            // Remove the current request.
            this.pendingRequests.removeValue(forKey: currentSeqNo)
            
            // Obsolete requests should not happen since they have been cancelled by more recent requests (see above).
            // WARNING: Only works if the current queue is serial!
            assert(this.receivedState == nil || this.receivedState!.sequenceNumber < state.sequenceNumber)

            this.receivedState = state
            
            // Call the result handler.
            this.handleResults(content: content, error: error, userInfo: userInfo)
        }
        if state.disjunctiveFacets.isEmpty {
            // All facets are conjunctive; build facet filters accordingly.
            let queryHelper = QueryHelper(query: query)
            for (facetName, values) in refinements {
                for value in values {
                    queryHelper.addConjunctiveFacetRefinement(FacetRefinement(name: facetName, value: value))
                }
            }
            operation = index.search(query, completionHandler: completionHandler)
        } else {
            // Facet filters are built directly by the disjunctive faceting search helper method.
            operation = index.searchDisjunctiveFaceting(query, disjunctiveFacets: state.disjunctiveFacets, refinements: refinements, completionHandler: completionHandler)
        }
        self.pendingRequests[state.sequenceNumber] = operation
        
        // Notify observers.
        NotificationCenter.default.post(name: Searcher.SearchNotification, object: self, userInfo: userInfo)
    }
    
    /// Completion handler for search requests.
    private func handleResults(content: JSONObject?, error: Error?, userInfo: [String: Any]) {
        do {
            if let content = content {
                try self.results = SearchResults(content: content, disjunctiveFacets: receivedState.disjunctiveFacets)
                callResultHandlers(results: self.results, error: nil, userInfo: userInfo)
            } else {
                callResultHandlers(results: nil, error: error, userInfo: userInfo)
            }
        } catch let e {
            callResultHandlers(results: nil, error: e, userInfo: userInfo)
        }
    }
    
    private func callResultHandlers(results: SearchResults?, error: Error?, userInfo: [String: Any]) {
        // Notify result handlers.
        for resultHandler in resultHandlers {
            resultHandler(results, error)
        }
        // Notify observers.
        var userInfo = userInfo
        if let results = results {
            userInfo[Searcher.ResultNotificationResultsKey] = results
            NotificationCenter.default.post(name: Searcher.ResultNotification, object: self, userInfo: userInfo)
        }
        else if let error = error {
            userInfo[Searcher.ErrorNotificationErrorKey] = error
            NotificationCenter.default.post(name: Searcher.ErrorNotification, object: self, userInfo: userInfo)
        }
    }
    
    // MARK: - Facets
    
    /// Set a given facet as disjunctive or conjunctive.
    /// This is a convenience method to set the `disjunctiveFacets` property.
    ///
    /// - parameter name: The facet's name.
    /// - parameter disjunctive: true to treat this facet as disjunctive (`OR`), false to treat it as conjunctive
    ///   (`AND`, the default).
    ///
    @objc public func setFacet(withName name: String, disjunctive: Bool) {
        if disjunctive {
            if !disjunctiveFacets.contains(name) {
                disjunctiveFacets.append(name)
            }
        } else {
            if let index = disjunctiveFacets.index(of: name) {
                disjunctiveFacets.remove(at: index)
            }
        }
    }
    
    /// Add a refinement for a given facet.
    /// The refinement will be treated as conjunctive (`AND`) or disjunctive (`OR`) based on the facet's own
    /// disjunctive/conjunctive status.
    ///
    /// - parameter name: The facet's name.
    /// - parameter value: The refined value to add.
    ///
    @objc public func addFacetRefinement(name: String, value: String) {
        if refinements[name] == nil {
            refinements[name] = []
        }
        refinements[name]!.append(value)
    }
    
    /// Remove a refinement for a given facet.
    ///
    /// - parameter name: The facet's name.
    /// - parameter value: The refined value to remove.
    ///
    @objc public func removeFacetRefinement(name: String, value: String) {
        if let index = refinements[name]?.index(of: value) {
            refinements[name]?.remove(at: index)
        }
    }
    
    /// Test whether a facet has a refinement for a given value.
    ///
    /// - parameter name: The facet's name.
    /// - parameter value: The refined value to look for.
    /// - returns: true if the refinement exists, false otherwise.
    ///
    @objc public func hasFacetRefinement(name: String, value: String) -> Bool {
        return refinements[name]?.contains(value) ?? false
    }
    
    /// Add or remove a facet refinement, based on its current state: if it exists, it is removed; otherwise it is
    /// added.
    ///
    /// - parameter name: The facet's name.
    /// - parameter value: The refined value to toggle.
    ///
    @objc public func toggleFacetRefinement(name: String, value: String) {
        if hasFacetRefinement(name: name, value: value) {
            removeFacetRefinement(name: name, value: value)
        } else {
            addFacetRefinement(name: name, value: value)
        }
    }
    
    /// Remove all refinements for all facets.
    ///
    @objc public func clearFacetRefinements() {
        refinements.removeAll()
    }
    
    /// Remove all refinements for a given facet.
    ///
    /// - parameter name: The facet's name.
    ///
    @objc public func clearFacetRefinements(name: String) {
        refinements.removeValue(forKey: name)
    }
    
    // MARK: - Managing requests
    
    /// Indicates whether there are any pending requests.
    @objc public var hasPendingRequests: Bool {
        return !pendingRequests.isEmpty
    }

    /// Cancel all pending requests.
    @objc public func cancelPendingRequests() {
        for seqNo in pendingRequests.keys {
            cancelRequest(seqNo: seqNo)
        }
        assert(pendingRequests.isEmpty)
    }
    
    /// Cancel a specific request.
    ///
    /// - parameter seqNo: The request's sequence number.
    ///
    @objc public func cancelRequest(seqNo: Int) {
        if let request = pendingRequests[seqNo] {
            request.cancel()
            pendingRequests.removeValue(forKey: seqNo)
            NotificationCenter.default.post(name: Searcher.CancelNotification, object: self, userInfo: [
                Searcher.NotificationSeqNoKey: seqNo
            ])
        }
    }
    
    // MARK: Notifications
    
    /// Notification sent when a request is sent through the API Client.
    /// This can be either on `search()` or `loadMore()`.
    ///
    @objc public static let SearchNotification = Notification.Name("search")
    
    /// Notification sent when a successful response is received from the API Client.
    @objc public static let ResultNotification = Notification.Name("result")
    
    /// Key containing the search results in a `ResultNotification`.
    /// Type: `SearchResults`.
    ///
    @objc public static let ResultNotificationResultsKey: String = "results"

    /// Notification sent when an erroneous response is received from the API Client.
    @objc public static let ErrorNotification = Notification.Name("error")
    
    /// Key containing the request sequence number in a `SearchNotification`, `ResultNotification`, `ErrorNotification`
    /// or `CancelNotification`. The sequence number uniquely identifies the request within a given `Searcher` instance.
    /// Type: `Int`.
    ///
    @objc public static let NotificationSeqNoKey: String = "seqNo"
    
    /// Key containing the search query in a `SearchNotification`, `ResultNotification` or `ErrorNotification`.
    /// Type: `Query`.
    ///
    @objc public static let NotificationQueryKey: String = "query"
    
    /// Key containing the error in an `ErrorNotification`.
    /// Type: `Error`.
    ///
    @objc public static let ErrorNotificationErrorKey: String = "error"

    /// Notification sent when a request is cancelled by the searcher.
    /// The result handler will not be called for cancelled requests, nor will any `ResultNotification` or
    /// `ErrorNotification` be posted, so this is your only chance of being informed of cancelled requests.
    ///
    @objc public static let CancelNotification = Notification.Name("cancel")
}
