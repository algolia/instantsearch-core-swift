//
//  MultiHitsViewModel.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 15/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public class MultiHitsViewModel {
  
  private var hitsViewModels: [AnyHitsViewModel]
  
  public init() {
    hitsViewModels = []
  }
  
  /// Adds a new hits ViewModel at the end of the view models list.
  /// - Parameter hitsViewModel: the hits ViewModel to append
  
  public func append<R: Codable>(_ hitsViewModel: HitsViewModel<R>) {
    hitsViewModels.append(hitsViewModel)
  }
  
  /// Inserts a hits ViewModel at the specified position
  /// - Parameter hitsViewModel: the hits ViewModel to insert
  /// - Parameter index: the position at which to insert the new hits ViewModel.
  
  public func insert<R: Codable>(hitsViewModel: HitsViewModel<R>, atIndex index: Int) {
    hitsViewModels.insert(hitsViewModel, at: index)
  }
  
  /// Replaces the hits ViewModel at the specified position by a provided one
  /// - Parameter hitsViewModel: the hits ViewModel replacement
  /// - Parameter index: the position at which to replace the hits ViewModel
  
  public func replace<R: Codable>(by hitsViewModel: HitsViewModel<R>, atIndex index: Int) {
    hitsViewModels[index] = hitsViewModel
  }
  
  /// Removes a hits ViewModel at the specified position
  /// - Parameter index: the position of the element to remove
  
  public func remove(atIndex index: Int) {
    hitsViewModels.remove(at: index)
  }
  
  /// Returns the index of provided hits ViewModel.
  /// - Parameter desiredViewModel: the ViewModel to search for
  /// - Returns: The index of desired ViewModel. If no there is no such ViewModel, returns `nil`
  
  public func index<R>(of desiredViewModel: HitsViewModel<R>) -> Int? {
    return hitsViewModels.firstIndex { ($0 as? HitsViewModel<R>) === desiredViewModel }
  }
  
  /// Returns boolean value indicating if desired ViewModel is nested in current multi hits ViewModel
  /// - Parameter desiredViewModel: the ViewModel to check
  
  public func contains<R>(_ desiredViewModel: HitsViewModel<R>) -> Bool {
    return index(of: desiredViewModel) != nil
  }
  
  /// Removes all hits ViewModels
  
  public func removeAll() {
    hitsViewModels.removeAll()
  }
  
  /// Returns a hits ViewModel at specified index
  /// - Parameter index: the index of nested hits ViewModel
  /// - Throws: HitsViewModel.Error.incompatibleRecordType if the derived record type mismatches the record type of corresponding hits ViewModel
  /// - Returns: The nested ViewModel at specified index.
  
  public func hitsViewModel<R: Codable>(atIndex index: Int) throws -> HitsViewModel<R> {
    guard let typedViewModel = hitsViewModels[index] as? HitsViewModel<R> else {
      throw HitsViewModel<R>.Error.incompatibleRecordType
    }
    
    return typedViewModel
  }
  
  /// Updates the results of a nested hits ViewModel at specified index
  /// - Parameter results: list of typed search results.
  /// - Parameter metadata: the metadata of query corresponding to results
  /// - Parameter index: the index of nested hits ViewModel
  /// - Throws: HitsViewModel.Error.incompatibleRecordType if the record type of results mismatches the record type of corresponding hits ViewModel
  
  public func update<R: Codable>(_ results: SearchResults<R>, with metadata: QueryMetadata, forViewModelAtIndex index: Int) throws {
    guard let typedViewModel = hitsViewModels[index] as? HitsViewModel<R> else {
      throw HitsViewModel<R>.Error.incompatibleRecordType
    }
    
    typedViewModel.update(results, with: metadata)
  }
  
  /// Updates the results of all nested hits ViewModels.
  /// Each search results element will be converted to a corresponding nested hits ViewModel search results type.
  /// - Parameter results: list of generic search results. Order of results must match the order of nested hits ViewModels.
  /// - Parameter metadata: the metadata of query corresponding to results
  /// - Throws: HitsViewModel.Error.incompatibleRecordType if the conversion of search results for one of a nested hits ViewModels is impossible due to a record type mismatch
  
  public func update(_ results: [(metadata: QueryMetadata, results: SearchResults<JSON>)]) throws {
    try zip(hitsViewModels, results).forEach { viewModel, results in
      try viewModel.genericUpdate(results.results, with: results.metadata)
    }
  }
  
  /// Returns the hit at the specified index path
  /// - Parameter indexPath: a pointer to a hit, where section points to a hits ViewModel and row points to a hit in this ViewModel.
  /// - Throws: HitsViewModel.Error.incompatibleRecordType if desired type of record doesn't match with record type of corresponding hits ViewModel
  /// - Returns: The hit at row for index path. Returns `nil` if there is no element for specified index.
  
  public func hitForRow<R: Codable>(at indexPath: IndexPath) throws -> R? {
    return try hitsViewModels[indexPath.section].genericHitForRow(indexPath.row)
  }
  
  /// Returns number of nested hits ViewModels
  
  public func numberOfSections() -> Int {
    return hitsViewModels.count
  }
  
  /// Returns number rows in the nested hits ViewModel at section
  /// - Parameter section: the index of nested hits ViewModel
  
  public func numberOfRows(inSection section: Int) -> Int {
    return hitsViewModels[section].numberOfRows()
  }
  
  /// Triggers loading of following results in the nested hits ViewModel at specified index
  /// - Parameter section: the index of nested hits ViewModel
  
  public func loadMoreResults(forSection section: Int) {
    hitsViewModels[section].loadMoreResults()
  }
  
}

extension MultiHitsViewModel {
  
  func appendGeneric(_ hitsViewModel: AnyHitsViewModel) {
    hitsViewModels.append(hitsViewModel)
  }

}
