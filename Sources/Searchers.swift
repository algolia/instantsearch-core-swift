//
//  Searchers.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 05/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
//
//  Searchers.swift
//  InstantSearch
//
//  Created by Guy Daher on 25/02/2019.
//

import Foundation
import InstantSearchClient
import Signals

public protocol Searcher {
  func search()
  func cancel()
  func setQuery(text: String)
  var sequencer: Sequencer { get }
}

extension Searcher {

  public func cancel() {
    sequencer.cancelPendingOperations()
  }

  func transform<T: Decodable>(content: [String: Any]?, error: Error?) -> Result<T> {
    let result = Result(value: content, error: error)

    switch result {
    case .success(let value):
      do {
        let data = try JSONSerialization.data(withJSONObject: value, options: [])
        let decoder = JSONDecoder()

        let result = try decoder.decode(T.self, from: data)
        return Result(value: result)
      } catch let error {
        return Result(error: error)
      }
    case .fail(let error):
      return Result(error: error)
    }

  }
}

// TODO: don t forget to add RequestOption everywhere

public class SingleIndexSearcher<RecordType: Decodable>: Searcher {

  public let sequencer: Sequencer

  var index: Index
  var query: Query


  let onSearchResults = Signal<Result<SearchResults<RecordType>>>()

  public var applyDisjunctiveFacetingWhenNecessary = true

  public init(index: Index, query: Query) {
    self.index = index
    self.query = query
    sequencer = Sequencer()

  }

  public func setQuery(text: String) {
    self.query.query = text
  }

  func handle(value: [String: Any]?, error: Error?) {
    let result: Result<SearchResults<RecordType>> = transform(content: value, error: error)
      onSearchResults.fire(result)
  }

  public func search() {

    // TODO: weak self...
//    sequencer.orderOperation {
//
//      if applyDisjunctiveFacetingWhenNecessary && query.filterBuilder.isDisjunctiveFacetingAvailable() {
//        let disjunctiveFacets = Array(query.filterBuilder.getDisjunctiveFacetsAttributes()).map { $0.description }
//        let refinements = query.filterBuilder.getRawFacetFilters()
//
//        return self.index.searchDisjunctiveFaceting(query, disjunctiveFacets: disjunctiveFacets, refinements: refinements, completionHandler: handle)
//      } else {
//        return self.index.search(query, completionHandler: handle)
//      }
//    }
  }



  public func cancel() {
    sequencer.cancelPendingOperations()
  }
}


public class MultiIndexSearcher: Searcher {

  let indexQueries: [IndexQuery]
  let client: Client
  public let sequencer: Sequencer

  var onSearchResults = Signal<[Result<SearchResults<JSON>>]>()

  public var applyDisjunctiveFacetingWhenNecessary = true

  public convenience init(client: Client, indices: [Index], queries: [Query]) {
    self.init(client: client, indexQueries: zip(indices, queries).map { IndexQuery(index: $0, query: $1) } )
  }

  public convenience init(client: Client, indices: [Index], query: Query) {
    self.init(client: client, indexQueries: indices.map { IndexQuery(index: $0, query: query) })
  }

  public init(client: Client, indexQueries: [IndexQuery]) {
    self.indexQueries = indexQueries
    self.client = client
    self.sequencer = Sequencer()
  }

  public func setQuery(text: String) {
    self.indexQueries.forEach { $0.query.query = text }
  }

  public func search() {
    sequencer.orderOperation {
      return self.client.multipleQueries(indexQueries) { (content, error) in
        var results: [Result<SearchResults<JSON>>]
        if let content = content, let contentResults = content["results"] as? [[String: Any]] {

          results = contentResults.map { self.transform(content: $0, error: error) }

          self.onSearchResults.fire(results)

        } else if let error = error {
          self.onSearchResults.fire(Array.init(repeating: Result(error: error), count: self.indexQueries.count))
        } else {
          self.onSearchResults.fire(Array.init(repeating: Result(error: ResultError.invalidResultInput), count: self.indexQueries.count))
        }

      }
    }
  }

  public func cancel() {
    sequencer.cancelPendingOperations()
  }
}

public class SearchForFacetValueSearcher: Searcher {

  public let index: Index
  public let query: Query
  public var facetName: String
  public var text: String
  public let sequencer: Sequencer
  let onSearchResults = Signal<Result<FacetResults>>()

  public init(index: Index, query: Query, facetName: String, text: String) {
    self.index = index
    self.query = query
    self.facetName = facetName
    self.text = text
    self.sequencer = Sequencer()
  }

  public func setQuery(text: String) {
    self.text = text
  }

  public func search() {
    sequencer.orderOperation {
      return self.index.searchForFacetValues(of: facetName, matching: text) { (content, error) in
        let result: Result<FacetResults> = self.transform(content: content, error: error)
        self.onSearchResults.fire(result)
      }
    }
  }

}

//// Factory class creating those different kind of MultiIndexSearcher
//
//public class SearcherFactory {
//
//  public enum SearcherType {
//    case singleIndex(Index, Query)
//    case multipleIndex(Client, [IndexQuery])
//    case searchForFacetValue(Index, Query, String, String)
//  }
//
//  static public func createSearcher(searcherType: SearcherType) -> Searcher {
//    switch searcherType {
//    case .singleIndex(let index, let query):
//      return SingleIndexSearcher(index: index, query: query)
//    case .multipleIndex(let client, let indexQueries):
//      return MultiIndexSearcher(client: client, indexQueries: indexQueries)
//    case .searchForFacetValue(let index, let query, let facetName, let text):
//      return SearchForFacetValueSearcher(index: index, query: query, facetName: facetName, text: text)
//    }
//  }
//}


public enum Result<T> {

  case success(T), fail(Error)

  public init(value: T) {
    self = .success(value)
  }

  public init(error: Error) {
    self = .fail(error)
  }

  public var value: T? {
    if case let .success(val) = self { return val } else { return nil }
  }

  public var error: Error? {
    if case let .fail(err) = self { return err } else { return nil }
  }

}

public extension Result {

  public init(value: T?, error: Error?) {
    switch (value, error) {
    case (_, .some(let error)):
      self = .fail(error)
    case (.some(let value), _):
      self = .success(value)
    default:
      self = .fail(ResultError.invalidResultInput)
    }
  }
}

public enum ResultError: Error {
  case invalidResultInput
}
