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

import Foundation
import InstantSearchClient

/// A Transformable data source
public protocol Transformable {
    associatedtype IResults
    associatedtype IParameters
    
    associatedtype ISFFVResults
    associatedtype ISFFVParameters
    
    typealias SearchResultsHandler = (_ results: IResults?, _ error: Error?) -> Void
    typealias SFFVResultsHandler = (_ results: ISFFVResults?, _ error: Error?) -> Void
    
    // Search operation
    func search(_ query: IParameters, searchResultsHandler: @escaping SearchResultsHandler)
    
    // Transforms the Algolia params to custom backend params.
    func map(query: Query) -> IParameters
    
    // Transforms the Algolia params + disjunctive refinements to custom backend params.
    func map(query: Query, disjunctiveFacets: [String], refinements: [String : [String]]) -> IParameters
    
    // Transforms the custom backend result to an Algolia result.
    func map(results: IResults) -> SearchResults
    
    // Search for facet value operation
    func searchForFacetValues(_ query: ISFFVParameters, sffvResultsHandler: @escaping SFFVResultsHandler)
    
    // Transforms the Algolia facet value params to custom backend params.
    func map(query: Query?, facetName: String, matching text: String) -> ISFFVParameters
    
    // Transforms the search for facet value custom backend result to an Algolia result.
    func map(results: ISFFVResults) -> FacetResults
}

/// Base class used to implement a custom backend with Algolia
/// You need to make sure to implement the following method:
/// - search(query:searchResultsHandler:)
open class DefaultSearchClient: SearchClient<Query, SearchResults> {
    open override func search(_ query: Query, searchResultsHandler: @escaping SearchResultsHandler) {
        fatalError("make sure to override search(query:searchResultsHandler:) for custom backend")
    }
    
    open override func map(query: Query) -> Query {
        return query
    }
    
    open override func map(results: SearchResults) -> SearchResults {
        return results
    }
}

/// Base class used to implement a custom backend with Algolia
/// You need to make sure to implement the following methods:
/// - search(query:searchResultsHandler:)
/// - map(query:)
/// - map(results:)
open class SearchClient<Parameters, Results>: AdvancedSearchClient<Parameters, Results, Parameters, Results> {
    
    open override func searchForFacetValues(_ query: Parameters, sffvResultsHandler: @escaping SFFVResultsHandler) {
        print("No implementation for Search for Facet Values with the SearchClient class. Please use the AdvancedSearchClient class to add your Search for facet Values implementation")
    }
    
    open override func map(query: Query?, facetName: String, matching text: String) -> Parameters {
        return map(query: query ?? Query(query: ""))
    }
    
    open override func map(results: Results) -> FacetResults {
        return FacetResults(content: [:])
    }
}

/// Bass Class used to implement a custom backend with Algolia
/// You need to make sure to implement the following methods:
/// - search(query:searchResultsHandler:)
/// - map(query:)
/// - map(results:)
/// - searchForFacetValues(query:sffvResultsHandler:)
/// - map(facetName:matching:)
/// - map(results:)
open class AdvancedSearchClient<Parameters, Results, SFFVParameters, SFFVResults>: Transformable, Searchable {
    
    public typealias IParameters = Parameters
    public typealias IResults = Results
    
    public typealias ISFFVParameters = SFFVParameters
    public typealias ISFFVResults = SFFVResults
    
    public init() {}
    
    // Transformable protocol
    
    open func search(_ query: Parameters, searchResultsHandler: @escaping SearchResultsHandler) {
        fatalError("make sure to override search(query:searchResultsHandler:) for custom backend")
    }
    
    open func map(query: Query) -> Parameters {
        fatalError("make sure to override map(query:) for custom backend")
    }
    
    open func map(results: Results) -> SearchResults {
        fatalError("make sure to override map(results:) for custom backend")
    }
    
    /// By default, it does the same thing as search. Override to access more parameters.
    open func map(query: Query, disjunctiveFacets: [String], refinements: [String : [String]]) -> Parameters {
        return map(query: query)
    }
    
    /// By default, it does the same thing as search. Override for extending the functionality.
    open func searchForFacetValues(_ query: SFFVParameters, sffvResultsHandler: @escaping SFFVResultsHandler) {
        fatalError("make sure to override search(query:searchResultsHandler:) for custom backend")
    }
    
    open func map(query: Query?, facetName: String, matching text: String) -> SFFVParameters {
        fatalError("make sure to override map(query:facetName:matching:) for custom backend")
    }
    
    open func map(results: SFFVResults) -> FacetResults {
        fatalError("make sure to override map(results:) for custom backend")
    }
    
    // Searchable Protocol
    
    public func search(_ query: Query, requestOptions: RequestOptions?, completionHandler: @escaping CompletionHandler) -> Operation {
        let operation = BlockOperation()
        operation.addExecutionBlock {
            let params = self.map(query: query)
            self.search(params) { (results, error) in
                if let error = error {
                    completionHandler(nil, error)
                } else if let results = results {
                    let searchResults: SearchResults = self.map(results: results)
                    
                    var content = searchResults.content
                    content["hits"] = searchResults.latestHits
                    content["nbHits"] = searchResults.nbHits
                    
                    completionHandler(content, nil)
                }
            }
        }
        
        operation.start()
        
        return operation
    }
    
    public func searchDisjunctiveFaceting(_ query: Query, disjunctiveFacets: [String], refinements: [String : [String]], requestOptions: RequestOptions?, completionHandler: @escaping CompletionHandler) -> Operation {
        let operation = BlockOperation()
        operation.addExecutionBlock {
            let params = self.map(query: query, disjunctiveFacets: disjunctiveFacets, refinements: refinements)
            self.search(params) { (results, error) in
                if let error = error {
                    completionHandler(nil, error)
                } else if let results = results {
                    let searchResults = self.map(results: results)
                    
                    var content = searchResults.content
                    content["hits"] = searchResults.latestHits
                    content["nbHits"] = searchResults.nbHits
                    
                    completionHandler(content, nil)
                }
            }
        }
        
        operation.start()
        
        return operation
    }
    
    public func searchForFacetValues(of facetName: String, matching text: String, query: Query?, requestOptions: RequestOptions?, completionHandler: @escaping CompletionHandler) -> Operation {
        let operation = BlockOperation()
        operation.addExecutionBlock {
            let params = self.map(query: query, facetName: facetName, matching: text)
            self.searchForFacetValues(params) { (results, error) in
                if let error = error {
                    completionHandler(nil, error)
                } else if let results = results {
                    let facetResults: FacetResults = self.map(results: results)
                    completionHandler(facetResults.content, nil)
                }
            }
        }
        
        operation.start()
        
        return operation
    }
}

