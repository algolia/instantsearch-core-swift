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
    /// Handler for search results.
    ///
    /// - parameter results: The results (in case of success).
    /// - parameter error: The error (in case of failure).
    ///
    public typealias ResultHandler = @convention(block) (results: SearchResults?, error: NSError?) -> Void

    /// Pluggable state representation.
    private struct State: CustomStringConvertible {
        /// Search query.
        /// NOTE: The page may be overridden when loading more content.
        ///
        public var query: Query = Query()
        
        /// List of facets to be treated as disjunctive facets. Defaults to the empty list.
        public var disjunctiveFacets: [String] = []
        
        /// Initial page.
        public var initialPage: Int { return query.page?.integerValue ?? 0 }
        
        /// Current page.
        public var page: Int = 0
        
        /// Whether the current page is the initial page for this search state.
        public var isInitialPage: Bool { return initialPage == page }
        
        /// This state's sequence number.
        public var sequenceNumber: Int = 0
        
        /// Construct a default state.
        public init() {
        }

        // WARNING: Although `State` is a value type, `Query` is not (because of Objective-C bridgeability).
        // Consequently, the memberwise assignment of `State` leads to unintended state sharing.
        //
        // TODO: I found no way to customize the assignment of a struct in Swift (something like C++'s assignment
        // operator or copy constructor). So I resort to explicitly constructing copies so far.

        /// Copy a state.
        public init(copy: State) {
            // WARNING: Query is not a value type (because of Objective-C bridgeability), so let's make sure to copy it.
            self.query = Query(copy: copy.query)
            self.disjunctiveFacets = copy.disjunctiveFacets
            self.page = copy.page
        }
        
        public var description: String {
            return "State#\(sequenceNumber){query=\(query), disjunctiveFacets=\(disjunctiveFacets), page=\(page)}"
        }
    }

    /// The index used by this search helper.
    @objc public let index: Index
    
    /// User callbacks for handling results.
    /// There should be at least one, but multiple handlers may be registered if necessary.
    ///
    private var resultHandlers: [ResultHandler] = []
    
    // MARK: State management
    // ----------------------
    
    /// The query that will be used for the next search.
    @objc public var query: Query {
        get { return nextState.query }
        set { nextState.query = newValue }
    }
    
    /// The disjunctive facets that will be used for the next search.
    @objc public var disjunctiveFacets: [String] {
        get { return nextState.disjunctiveFacets }
        set { nextState.disjunctiveFacets = newValue }
    }
    
    /// Sequence number for the next request.
    private var nextSequenceNumber: Int = 0
    
    /// The state that will be used for the next search.
    /// It can be modified at will. It is not taken into account until the `search()` method is called; then it is
    /// copied and transferred to `requestedState`.
    private var nextState: State = State()

    /// The state corresponding to the last issued request.
    /// WARNING: Only valid after the first call to `search()`.
    private var requestedState: State!

    /// The state corresponding to the last received results.
    /// WARNING: Only valid after the first call to the result handler.
    private var receivedState: State!
    
    /// The last received results.
    @objc public private(set) var results: SearchResults?
    
    /// All currently ongoing requests.
    @objc public private(set) dynamic var pendingRequests: [NSOperation] = []

    // MARK: -
    
    @objc public init(index: Index) {
        self.index = index
        super.init()
        updateClientUserAgents()
    }
    
    @objc public convenience init(index: Index, resultHandler: ResultHandler) {
        self.init(index: index)
        self.resultHandlers = [resultHandler]
    }
    
    /// Add the helper library's version to the client's user agents, if not already present.
    private func updateClientUserAgents() {
        let bundleInfo = NSBundle(forClass: self.dynamicType).infoDictionary!
        let name = bundleInfo["CFBundleName"] as! String
        let version = bundleInfo["CFBundleShortVersionString"] as! String
        let libraryVersion = LibraryVersion(name: name, version: version)
        let client = index.client
        if client.userAgents.indexOf({ $0 == libraryVersion }) == nil {
            client.userAgents.append(libraryVersion)
        }
    }
    
    @objc public func addResultHandler(resultHandler: ResultHandler) {
        self.resultHandlers.append(resultHandler)
    }
    
    /// Search.
    @objc public func search() {
        requestedState = State(copy: nextState)
        requestedState.page = requestedState.initialPage
        _doNextRequest()
    }
    
    /// Load more content, if possible.
    @objc public func loadMore() {
        // Cannot load more when no results have been received.
        if results == nil {
            return
        }
        // Must not load more if the results are outdated with respect to the currently on-going search.
        if requestedState.query != receivedState.query {
            return
        }
        let nextPage = receivedState.page + 1
        // Cannot load more if the end has already been reached.
        if nextPage >= results!.nbPages {
            return
        }
        // Must not load more if already loading.
        if nextPage <= requestedState.page {
            return
        }
        // OK, everything's fine; let's go!
        requestedState.page = nextPage
        _doNextRequest()
    }
    
    private func _doNextRequest() {
        var operation: NSOperation!
        var state = State(copy: requestedState)
        state.sequenceNumber = nextSequenceNumber
        nextSequenceNumber += 1
        var requestCompleted = false
        let completionHandler: CompletionHandler = { (content: [String: AnyObject]?, error: NSError?) in
            requestCompleted = true
            
            // Remove request from list of pending requests.
            // Also cancel and remove all previous requests (as this one is deemed more recent).
            if let index = self.pendingRequests.indexOf(operation) {
                for i in 0..<index {
                    self.pendingRequests[i].cancel()
                }
                self.pendingRequests.removeRange(0...index)
            }
            
            // Obsolete requests should not happen since they have been cancelled by more recent requests (see above).
            // WARNING: Only works if the current queue is serial!
            assert(self.receivedState == nil || self.receivedState!.sequenceNumber < state.sequenceNumber)

            self.receivedState = state
            
            // Call the result handler.
            self.handleResults(content, error: error)
        }
        let query = Query(copy: state.query)
        query.page = state.page
        if state.disjunctiveFacets.isEmpty {
            operation = index.search(query, completionHandler: completionHandler)
        } else {
            let queryHelper = QueryHelper(query: query)
            operation = index.searchDisjunctiveFaceting(query, disjunctiveFacets: state.disjunctiveFacets, refinements: queryHelper.buildFacetRefinementsForDisjunctiveFaceting(), completionHandler: completionHandler)
        }
        self.pendingRequests.append(operation)
    }
    
    /// Completion handler for search requests.
    private func handleResults(content: [String: AnyObject]?, error: NSError?) {
        if let content = content {
            if receivedState.page == receivedState.initialPage {
                self.results = SearchResults(content: content, disjunctiveFacets: receivedState.disjunctiveFacets)
            } else {
                self.results?.add(content)
            }
            callResultHandlers(self.results, error: nil)
        } else {
            callResultHandlers(nil, error: error)
        }
    }
    
    private func callResultHandlers(results: SearchResults?, error: NSError?) {
        for resultHandler in resultHandlers {
            resultHandler(results: results, error: error)
        }
    }

    /// Toggle a facet refinement on/off, in a way suitable for high latency environments.
    ///
    /// The trick here is that the toggle reads the *received* query state, but updates the *next* query. Why?
    /// Because if search results are slow to come, the user will be acting on the received state. If you just toggle
    /// the next query state, it might lead to inconsistent results.
    ///
    @objc public func toggleFacetRefinement(facetRefinement: FacetRefinement) {
        let receivedQueryHelper = QueryHelper(query: receivedState.query)
        var enabled = receivedQueryHelper.hasFacetRefinement(facetRefinement)
        enabled = !enabled
        let newQueryHelper = QueryHelper(query: nextState.query)
        if enabled {
            if receivedState.disjunctiveFacets.contains(facetRefinement.name) {
                newQueryHelper.addDisjunctiveFacetRefinement(facetRefinement)
            } else {
                newQueryHelper.addConjunctiveFacetRefinement(facetRefinement)
            }
        } else {
            newQueryHelper.removeFacetRefinement(facetRefinement)
        }
    }
}
