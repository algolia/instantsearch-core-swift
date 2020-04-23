//
//  RelatedItemsInteractor+SingleIndexSearcher.swift
//  InstantSearchCore
//
//  Created by test test on 23/04/2020.
//  Copyright © 2020 Algolia. All rights reserved.
//

import Foundation

extension HitsInteractor {
  
  @discardableResult public func connectSearcher<T>(_ searcher: SingleIndexSearcher, withRelatedItemsTo hit: Hit<T>, with matchingPatterns: [MatchingPattern<T>]) -> SingleIndexSearcherConnection {
    let connection = SingleIndexSearcherConnection(interactor: self, searcher: searcher)
    connection.connect()
        
    let legacyFilters = generateOptionalFilters(from: matchingPatterns, and: hit)
    
    // Temporary workaround as the api client only accepts optionalFilters [Stirng] and not [[String]] for now...
    let reducedOptionalFilters = convertLegacy2DArrayTo1DArray(with: legacyFilters)
    
    searcher.indexQueryState.query.sumOrFiltersScores = true
    searcher.indexQueryState.query.facetFilters = ["objectID:-\(hit.objectID)"]
    searcher.indexQueryState.query.optionalFilters = reducedOptionalFilters
    
    return connection
  }
  
  func generateOptionalFilters<T>(from matchingPatterns: [MatchingPattern<T>], and hit: Hit<T>) -> [[String]]? {
    let filterState = FilterState()
    
    for matchingPattern in matchingPatterns {
      switch matchingPattern.oneOrManyElementsInKeyPath {
      case .one(let keyPath): // // in the case of a single facet associated to a filter -> AND Behaviours
        let facetValue = hit.object[keyPath: keyPath]
        let facetFilter = Filter.Facet.init(attribute: matchingPattern.attribute, value: .string(facetValue), score: matchingPattern.score)
        filterState[and: matchingPattern.attribute.name].add(facetFilter)
      case .many(let keyPath): // in the case of multiple facets associated to a filter -> OR Behaviours
        let facetFilters = hit.object[keyPath: keyPath].map { Filter.Facet.init(attribute: matchingPattern.attribute, value: .string($0), score: matchingPattern.score) }
        filterState[or: matchingPattern.attribute.name].addAll(facetFilters)
      }
    }
    
    return FilterGroupConverter().legacy(filterState.toFilterGroups())
  }
  
  func convertLegacy2DArrayTo1DArray(with legacyFilters: [[String]]?) -> [String] {
    var reducedOptionalFilters: [String] = []
    if let legacyFilters = legacyFilters {
    
      for legacyFilter in legacyFilters {
        if legacyFilter.count == 1 {
          let string = legacyFilter.first!
          reducedOptionalFilters.append(string)
        } else if legacyFilter.count > 1 {
          let string = "[\(legacyFilter.joined(separator: ","))]" // we won't be doing this hack once we use [[String]] for optionalFilters in new client.
          if let escapedString = string.addingPercentEncoding(withAllowedCharacters: .alphanumerics) {
            reducedOptionalFilters.append(escapedString)
          }
        }
      }
    }
    
    return reducedOptionalFilters
  }
  
}
