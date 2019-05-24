//
//  HitsViewModel.swift
//  InstantSearch
//
//  Created by Guy Daher on 15/02/2019.
//

import Foundation
import InstantSearchClient

// DISCUSSION: should we expose those through KVO? dynamic var in case someone wants to listen to them?
// something like: viewModel.bind(\.navigationTitle, to: navigationItem, at: \.title),

// TODO: Paginator: keep in memory only visible results with offsets
public class HitsViewModel<Record: Codable> {
  
  public let settings: Settings

  private let hitsPaginationController: Paginator<Record>
  
  private var isLastQueryEmpty: Bool = true
  
  public var hasMorePages: Bool
  
  public let onNewPage = Observer<Int>()
  public let onResultsUpdated = Observer<SearchResults<Record>>()
  
  convenience public init(infiniteScrolling: InfiniteScrolling = Constants.Defaults.infiniteScrolling,
                          showItemsOnEmptyQuery: Bool = Constants.Defaults.showItemsOnEmptyQuery) {
    let settings = Settings(infiniteScrolling: infiniteScrolling,
                            showItemsOnEmptyQuery: showItemsOnEmptyQuery)
    self.init(settings: settings)
  }

  public init(settings: Settings? = nil) {
    self.settings = settings ?? Settings()
    self.hitsPaginationController = Paginator<Record>()
    self.hasMorePages = false
    self.hitsPaginationController.delegate = self
  }
  
  internal init(settings: Settings? = nil,
                paginationController: Paginator<Record>) {
    self.settings = settings ?? Settings()
    self.hitsPaginationController = paginationController
    self.hasMorePages = true
  }

  public func numberOfHits() -> Int {
    guard let hitsPageMap = hitsPaginationController.pageMap else { return 0 }
    
    if isLastQueryEmpty && !settings.showItemsOnEmptyQuery {
      return 0
    } else {
      return hitsPageMap.count
    }
  }

  public func hit(atIndex index: Int) -> Record? {
    guard let hitsPageMap = hitsPaginationController.pageMap else { return nil }

    loadMoreIfNeeded(rowNumber: index)
    return hitsPageMap[index]
  }
  
  public func rawHitAtIndex(_ row: Int) -> [String: Any]? {
    guard let hit = hit(atIndex: row) else { return nil }
    guard let data = try? JSONEncoder().encode(hit) else { return nil }
    guard let jsonValue = try? JSONDecoder().decode(JSON.self, from: data) else { return nil }
    return [String: Any](jsonValue)
  }
  
  public func loadMoreResults() {
    hitsPaginationController.loadNextPageIfNeeded()
  }

}

private extension HitsViewModel {
  
  // TODO: Here we're always loading the next page, but we don't handle the case where a page is missing in the middle for some reason
  // So we will need to detect which page the row corresponds at, and check if we're missing the page. then check the threshold offset to determine
  // if we load previous or next page (in case we don't have them loaded/cached already in our itemsPage struct
  func loadMoreIfNeeded(rowNumber: Int) {
    
    guard
      case .on(let pageLoadOffset) = settings.infiniteScrolling,
      let hitsPageMap = hitsPaginationController.pageMap else { return }
    
    let rowToLoad = rowNumber + Int(pageLoadOffset)
    
    if !hitsPageMap.containsItem(atIndex: rowToLoad) {
      hitsPaginationController.loadNextPageIfNeeded()
    }
    
  }
  
}

public extension HitsViewModel where Record == JSON {
  
  func rawHitForRow(_ row: Int) -> [String: Any]? {
    return hit(atIndex: row).flatMap([String: Any].init)
  }
  
}

extension HitsViewModel: PaginatorDelegate {
  
  func didRequestLoadPage(withIndex pageIndex: Int) {
    onNewPage.fire(pageIndex)
  }
  
}

extension HitsViewModel {
  
  public struct Settings {
    
    public var infiniteScrolling: InfiniteScrolling
    public var showItemsOnEmptyQuery: Bool
    
    public init(infiniteScrolling: InfiniteScrolling = Constants.Defaults.infiniteScrolling,
                showItemsOnEmptyQuery: Bool = Constants.Defaults.showItemsOnEmptyQuery) {
      self.infiniteScrolling = infiniteScrolling
      self.showItemsOnEmptyQuery = showItemsOnEmptyQuery
    }
    
  }
  
}

public enum InfiniteScrolling {
  case on(withOffset: UInt)
  case off
}

extension HitsViewModel {
  
  // TODO: What if there was an error? What do we do with "LoadMore" functionality (lastSentPage to decrement?)
  public func update(_ searchResults: SearchResults<Record>, with queryMetadata: QueryMetadata) {
    isLastQueryEmpty = queryMetadata.queryText.isNilOrEmpty
    hitsPaginationController.process(searchResults)
    hasMorePages = !(searchResults.page == searchResults.pagesCount - 1)
    onResultsUpdated.fire(searchResults)
  }
  
  public func connectSearcher(_ searcher: SingleIndexSearcher<Record>) {
    
    searcher.onResultsChanged.subscribe(with: self) { [weak self] (queryMetada, result) in
      switch result {
      case .success(let result):
        self?.update(result, with: queryMetada)
        
      case .failure(let error):
        print(error)
      }
    }
    
    onNewPage.subscribe(with: self) { [weak searcher] page in
      searcher?.indexSearchData.query.page = UInt(page)
      searcher?.search()
    }
    
    searcher.indexSearchData.filterState.onChange.subscribe(with: self) { [weak self] _ in
      self?.hitsPaginationController.invalidate()
    }
    
    searcher.onQueryChanged.subscribe(with: self) { [weak self] _ in
      self?.hitsPaginationController.invalidate()
    }
    
  }
  
}
