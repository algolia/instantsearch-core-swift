//
//  MultiIndexHitsInteractor.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 15/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

/**
 Interactor which constitutes the aggregation of nested hits interactors providing a convenient functions for managing them.
 Designed for a joint usage with multi index searcher, but can be used with multiple separate single index searchers as well.
 */

public class MultiIndexHitsInteractor {
  
  public let onRequestChanged: Observer<Void>
  public let onResultsUpdated: Observer<[SearchResults]>
  public let onError: Observer<Swift.Error>
  
  /// List of nested hits interactors
  
  let hitsInteractors: [AnyHitsInteractor]
  
  /// Common initializer
  
  public init(hitsInteractors: [AnyHitsInteractor]) {
    self.hitsInteractors = hitsInteractors
    self.onRequestChanged = .init()
    self.onResultsUpdated = .init()
    self.onError = .init()
  }
  
  /// Returns the index of provided hits interactor.
  /// - Parameter hitsInteractor: the interactor to search for
  /// - Returns: The index of desired interactor. If no there is no such interactor, returns `nil`
  
  public func section<R>(of hitsInteractor: HitsInteractor<R>) -> Int? {
    return hitsInteractors.firstIndex { ($0 as? HitsInteractor<R>) === hitsInteractor }
  }
  
  /// Returns boolean value indicating if desired hitsInteractor is nested in current multi hits hitsInteractor
  /// - Parameter hitsInteractor: the interactor to check
  
  public func contains<R>(_ hitsInteractor: HitsInteractor<R>) -> Bool {
    return section(of: hitsInteractor) != nil
  }
  
  /// Returns a hits interactor at specified index
  /// - Parameter section: the section index of nested hits interactor
  /// - Throws: HitsInteractor.Error.incompatibleRecordType if the derived record type mismatches the record type of corresponding hits interactor
  /// - Returns: The nested interactor at specified index.
  
  public func hitsViewModel<R>(forSection section: Int) throws -> HitsInteractor<R> {
    guard let typedViewModel = hitsInteractors[section] as? HitsInteractor<R> else {
      throw HitsInteractor<R>.Error.incompatibleRecordType
    }
    
    return typedViewModel
  }
  
  /// Updates the results of a nested hits ViewModel at specified index
  /// - Parameter results: list of typed search results.
  /// - Parameter section: the section index of nested hits ViewModel
  /// - Throws: HitsViewModel.Error.incompatibleRecordType if the record type of results mismatches the record type of corresponding hits ViewModel
  
  public func update(_ results: SearchResults, forViewModelInSection section: Int) throws {
    try hitsInteractors[section].update(results)
  }
  
  /// Updates the results of all nested hits ViewModels.
  /// Each search results element will be converted to a corresponding nested hits ViewModel search results type.
  /// - Parameter results: list of generic search results. Order of results must match the order of nested hits ViewModels.
  /// - Parameter metadata: the metadata of query corresponding to results
  /// - Throws: HitsViewModel.Error.incompatibleRecordType if the conversion of search results for one of a nested hits ViewModels is impossible due to a record type mismatch
  
  public func update(_ results: [SearchResults]) throws {
    try zip(hitsInteractors, results).forEach { arg in
      let (viewModel, results) = arg
      try viewModel.update(results)
    }
    onResultsUpdated.fire(results)
  }
  
  public func process(_ error: Error, for queries: [Query]) {
    let pages = queries.compactMap { $0.page }.map { Int($0) }
    zip(hitsInteractors, pages).forEach { (hitsViewModel, page) in
      hitsViewModel.notifyPending(atIndex: page)
    }
  }
  
  public func notifyQueryChanged() {
    hitsInteractors.forEach {
      $0.notifyQueryChanged()
    }
    onRequestChanged.fire(())
  }
  
  /// Returns the hit of a desired type
  /// - Parameter index: the index of a hit in a nested hits ViewModel
  /// - Parameter section: the index of a nested hits ViewModel
  /// - Throws: HitsViewModel.Error.incompatibleRecordType if desired type of record doesn't match with record type of corresponding hits ViewModel
  /// - Returns: The hit at row for index path or `nil` if there is no element at index in a specified section
  
  public func hit<R: Codable>(atIndex index: Int, inSection section: Int) throws -> R? {
    return try hitsInteractors[section].genericHitAtIndex(index)
  }
  
  /// Returns the hit in raw dictionary form
  /// - Parameter index: the index of a hit in a nested hits ViewModel
  /// - Parameter section: the index of a nested hits ViewModel
  /// - Returns: The hit in raw dictionary form or `nil` if there is no element at index in a specified section
  
  public func rawHit(atIndex index: Int, inSection section: Int) -> [String: Any]? {
    return hitsInteractors[section].rawHitAtIndex(index)
  }
  
  /// Returns number of nested hits ViewModels
  
  public func numberOfSections() -> Int {
    return hitsInteractors.count
  }
  
  /// Returns number rows in the nested hits ViewModel at section
  /// - Parameter section: the index of nested hits ViewModel
  
  public func numberOfHits(inSection section: Int) -> Int {
    return hitsInteractors[section].numberOfHits()
  }
  
}

#if os(iOS) || os(tvOS)

public extension MultiIndexHitsInteractor {
  
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
