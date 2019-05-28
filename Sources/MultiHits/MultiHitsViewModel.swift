//
//  MultiHitsViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 15/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

/**
 ViewModel which constitutes the aggregation of nested hits ViewModels providing a convenient functions for managing them.
 Designed for a joint usage with multi index searcher, but can be used with multiple separate single index searchers as well.
 */

public class MultiHitsViewModel {
  
  /// List of nested hits ViewModels
  
  private var hitsViewModels: [AnyHitsViewModel]
  
  /// Common initializer
  
  public init() {
    hitsViewModels = []
  }
  
  /// Adds a new hits ViewModel at the end of the view models list.
  /// - Parameter hitsViewModel: the hits ViewModel to append
  
  public func append<R>(_ hitsViewModel: HitsViewModel<R>) {
    hitsViewModels.append(hitsViewModel)
  }
  
  /// Inserts a hits ViewModel at the specified section
  /// - Parameter hitsViewModel: the hits ViewModel to insert
  /// - Parameter section: the position at which to insert the new hits ViewModel.
  
  public func insert<R>(hitsViewModel: HitsViewModel<R>, inSection section: Int) {
    hitsViewModels.insert(hitsViewModel, at: section)
  }
  
  /// Replaces the hits ViewModel at the specified position by a provided one
  /// - Parameter hitsViewModel: the hits ViewModel replacement
  /// - Parameter section: the position at which to replace the hits ViewModel
  
  public func replace<R>(by hitsViewModel: HitsViewModel<R>, inSection section: Int) {
    hitsViewModels[section] = hitsViewModel
  }
  
  /// Removes a hits ViewModel at the specified position
  /// - Parameter section: the position of the hits ViewModel to remove
  
  public func remove(inSection section: Int) {
    hitsViewModels.remove(at: section)
  }
  
  /// Returns the index of provided hits ViewModel.
  /// - Parameter desiredViewModel: the ViewModel to search for
  /// - Returns: The index of desired ViewModel. If no there is no such ViewModel, returns `nil`
  
  public func section<R>(of desiredViewModel: HitsViewModel<R>) -> Int? {
    return hitsViewModels.firstIndex { ($0 as? HitsViewModel<R>) === desiredViewModel }
  }
  
  /// Returns boolean value indicating if desired ViewModel is nested in current multi hits ViewModel
  /// - Parameter desiredViewModel: the ViewModel to check
  
  public func contains<R>(_ desiredViewModel: HitsViewModel<R>) -> Bool {
    return section(of: desiredViewModel) != nil
  }
  
  /// Removes all hits ViewModels
  
  public func removeAll() {
    hitsViewModels.removeAll()
  }
  
  /// Returns a hits ViewModel at specified index
  /// - Parameter section: the section index of nested hits ViewModel
  /// - Throws: HitsViewModel.Error.incompatibleRecordType if the derived record type mismatches the record type of corresponding hits ViewModel
  /// - Returns: The nested ViewModel at specified index.
  
  public func hitsViewModel<R>(forSection section: Int) throws -> HitsViewModel<R> {
    guard let typedViewModel = hitsViewModels[section] as? HitsViewModel<R> else {
      throw HitsViewModel<R>.Error.incompatibleRecordType
    }
    
    return typedViewModel
  }
  
  /// Updates the results of a nested hits ViewModel at specified index
  /// - Parameter results: list of typed search results.
  /// - Parameter metadata: the metadata of query corresponding to results
  /// - Parameter section: the section index of nested hits ViewModel
  /// - Throws: HitsViewModel.Error.incompatibleRecordType if the record type of results mismatches the record type of corresponding hits ViewModel
  
  public func update<R>(_ results: SearchResults<R>, with query: Query, forViewModelInSection section: Int) throws {
    guard let typedViewModel = hitsViewModels[section] as? HitsViewModel<R> else {
      throw HitsViewModel<R>.Error.incompatibleRecordType
    }
    
    typedViewModel.update(results, with: query)
  }
  
  /// Updates the results of all nested hits ViewModels.
  /// Each search results element will be converted to a corresponding nested hits ViewModel search results type.
  /// - Parameter results: list of generic search results. Order of results must match the order of nested hits ViewModels.
  /// - Parameter metadata: the metadata of query corresponding to results
  /// - Throws: HitsViewModel.Error.incompatibleRecordType if the conversion of search results for one of a nested hits ViewModels is impossible due to a record type mismatch
  
  public func update(_ results: [(query: Query, results: SearchResults<JSON>)]) throws {
    try zip(hitsViewModels, results).forEach { arg in
      let (viewModel, results) = arg
      try viewModel.update(withGeneric: results.results, with: results.query)
    }
  }
  
  /// Returns the hit of a desired type
  /// - Parameter index: the index of a hit in a nested hits ViewModel
  /// - Parameter section: the index of a nested hits ViewModel
  /// - Throws: HitsViewModel.Error.incompatibleRecordType if desired type of record doesn't match with record type of corresponding hits ViewModel
  /// - Returns: The hit at row for index path or `nil` if there is no element at index in a specified section
  
  public func hit<R: Codable>(atIndex index: Int, inSection section: Int) throws -> R? {
    return try hitsViewModels[section].genericHitAtIndex(index)
  }
  
  /// Returns the hit in raw dictionary form
  /// - Parameter index: the index of a hit in a nested hits ViewModel
  /// - Parameter section: the index of a nested hits ViewModel
  /// - Returns: The hit in raw dictionary form or `nil` if there is no element at index in a specified section
  
  public func rawHit(atIndex index: Int, inSection section: Int) -> [String: Any]? {
    return hitsViewModels[section].rawHitAtIndex(index)
  }
  
  /// Returns number of nested hits ViewModels
  
  public func numberOfSections() -> Int {
    return hitsViewModels.count
  }
  
  /// Returns number rows in the nested hits ViewModel at section
  /// - Parameter section: the index of nested hits ViewModel
  
  public func numberOfHits(inSection section: Int) -> Int {
    return hitsViewModels[section].numberOfHits()
  }
  
  /// Triggers loading of following results in the nested hits ViewModel at specified index
  /// - Parameter section: the index of nested hits ViewModel
  
  public func loadMoreResults(forSection section: Int) {
    hitsViewModels[section].loadMoreResults()
  }
  
}

internal extension MultiHitsViewModel {
  
  /// Appending a common AnyHitsViewModel hits ViewModel
  /// Used for testing purposes
  
  func appendGeneric(_ hitsViewModel: AnyHitsViewModel) {
    hitsViewModels.append(hitsViewModel)
  }

}

#if os(iOS) || os(tvOS)

public extension MultiHitsViewModel {
  
  /// Returns the hit of a desired type
  /// - Parameter indexPath: the pointer to a hit, where section points to a nested hits ViewModel, and item defines the index of a hit in a ViewModel
  /// - Throws: HitsViewModel.Error.incompatibleRecordType if desired type of record doesn't match with record type of corresponding hits ViewModel
  /// - Returns: The hit at row for index path or `nil` if there is no element at index in a specified section
  
  func hit<R: Codable>(at indexPath: IndexPath) throws -> R? {
    return try hit(atIndex: indexPath.item, inSection: indexPath.section)
  }
  
  /// Returns the hit in raw dictionary form
  /// - Parameter indexPath: the pointer to a hit, where section points to a nested hits ViewModel, and item defines the index of a hit in a ViewModel
  /// - Returns: The hit in raw dictionary form or `nil` if there is no element at index in a specified section
  
  func rawHit(at indexPath: IndexPath) -> [String: Any]? {
    return rawHit(atIndex: indexPath.item, inSection: indexPath.section)
  }
  
}

#endif
