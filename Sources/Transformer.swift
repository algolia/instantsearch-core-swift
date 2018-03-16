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
import AlgoliaSearch

/// A Transformable data source
public protocol Transformable {
    associatedtype IResults
    associatedtype IParameters
    
    typealias SearchResultsHandler = (_ results: IResults?, _ error: Error?) -> Void
    
    // Search operation
    func search(_ query: IParameters, searchResultsHandler: @escaping SearchResultsHandler)
    
    // Transforms the Algolia params to custom backend params.
    func map(query: Query) -> IParameters
    
    // Transforms the custom backend result to an Algolia result.
    func map(results: IResults) -> SearchResults
    
    
    // Disjunctive Search operation
    func searchDisjunctiveFaceting(_ query: IParameters, searchResultsHandler: @escaping SearchResultsHandler)
    
    // Transforms the Algolia disjunctive params to custom backend params.
    func map(query: Query, disjunctiveFacets: [String], refinements: [String : [String]]) -> IParameters
    
    
    // Search for facet value operation
    func searchForFacetValues(_ query: IParameters, searchResultsHandler: @escaping SearchResultsHandler)
    
    // Transforms the Algolia facet value params to custom backend params.
    func map(query: Query?, facetName: String, matching text: String) -> IParameters
}

/// Base class used to implement a custom backend with Algolia
/// You need to make sure to implement the following method:
/// - search(query:searchResultsHandler:)
/// - map(query:)
/// - map(results:)
open class SearchTransformer<Parameters, Results>: Transformable, Searchable {
    
    public typealias IParameters = Parameters
    public typealias IResults = Results
    
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
    
    /// By default, it does the same thing as search. Override for extending the functionality.
    open func searchDisjunctiveFaceting(_ query: IParameters, searchResultsHandler: @escaping SearchResultsHandler) {
        search(query, searchResultsHandler: searchResultsHandler)
    }
    
    /// By default, it does the same thing as search. Override to access more parameters.
    open func map(query: Query, disjunctiveFacets: [String], refinements: [String : [String]]) -> Parameters {
        return map(query: query)
    }
    
    /// By default, it does the same thing as search. Override for extending the functionality.
    open func searchForFacetValues(_ query: IParameters, searchResultsHandler: @escaping SearchResultsHandler) {
        search(query, searchResultsHandler: searchResultsHandler)
    }
    
    /// By default, it does the same thing as search. Override to access more parameters.
    open func map(query: Query?, facetName: String, matching text: String) -> IParameters {
        return map(query: query ?? Query(query: ""))
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
    
    public func searchDisjunctiveFaceting(_ query: Query, disjunctiveFacets: [String], refinements: [String : [String]], requestOptions: RequestOptions?, completionHandler: @escaping CompletionHandler) -> Operation {
        let operation = BlockOperation()
        operation.addExecutionBlock {
            let params = self.map(query: query, disjunctiveFacets: disjunctiveFacets, refinements: refinements)
            self.searchDisjunctiveFaceting(params) { (results, error) in
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
}
