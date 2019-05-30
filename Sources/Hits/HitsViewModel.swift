//
//  HitsViewModel.swift
//  InstantSearch
//
//  Created by Guy Daher on 15/02/2019.
//

import Foundation
import InstantSearchClient

public class HitsViewModel<Record: Codable> {
  
  public let settings: Settings

  private let paginator: Paginator<Record>
  
  private var isLastQueryEmpty: Bool = true
  
  private var latestPageIndex: Int?
  
  public let onPageRequest = Observer<Int>()
  public let onRequestChanged = Observer<Void>()
  public let onResultsUpdated = Observer<SearchResults<Record>>()
  
  convenience public init(infiniteScrolling: InfiniteScrolling = Constants.Defaults.infiniteScrolling,
                          showItemsOnEmptyQuery: Bool = Constants.Defaults.showItemsOnEmptyQuery) {
    let settings = Settings(infiniteScrolling: infiniteScrolling,
                            showItemsOnEmptyQuery: showItemsOnEmptyQuery)
    self.init(settings: settings)
  }

  public init(settings: Settings? = nil) {
    self.settings = settings ?? Settings()
    self.paginator = Paginator<Record>()
    self.latestPageIndex = .none
    self.paginator.delegate = self
  }
  
  internal init(settings: Settings? = nil,
                paginationController: Paginator<Record>) {
    self.settings = settings ?? Settings()
    self.paginator = paginationController
    self.latestPageIndex = .none
  }

  public func numberOfHits() -> Int {
    guard let hitsPageMap = paginator.pageMap else { return 0 }
    
    if isLastQueryEmpty && !settings.showItemsOnEmptyQuery {
      return 0
    } else {
      return hitsPageMap.count
    }
  }

  public func hit(atIndex index: Int) -> Record? {
    guard let hitsPageMap = paginator.pageMap else { return nil }

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
    paginator.loadNextPageIfNeeded()
  }

}

private extension HitsViewModel {
  
  func loadMoreIfNeeded(rowNumber: Int) {
    
    debugPrint("[HitsViewModel] Row: \(rowNumber)")
    
    guard
      case .on(let pageLoadOffset) = settings.infiniteScrolling,
      let hitsPageMap = paginator.pageMap else { return }
    
    let lowerBoundRow = rowNumber - Int(pageLoadOffset)
  
    if lowerBoundRow >= hitsPageMap.startIndex, !hitsPageMap.containsItem(atIndex: lowerBoundRow) {
      let lowerBoundPage = hitsPageMap.pageIndex(for: lowerBoundRow)
      paginator.loadPage(withIndex: lowerBoundPage)
    }
    
    let upperBoundRow = rowNumber + Int(pageLoadOffset)
    
    let isLatestPageLoaded = latestPageIndex.flatMap { hitsPageMap.containsPage(atIndex: $0) } ?? false
    
    if isLatestPageLoaded {
      debugPrint("[HitsViewModel] Latest page loaded")
    }
    
    if !hitsPageMap.containsItem(atIndex: upperBoundRow) && !isLatestPageLoaded {
      let lowerBoundPage = hitsPageMap.pageIndex(for: upperBoundRow)
      paginator.loadPage(withIndex: lowerBoundPage)
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
    if let latestPageIndex = latestPageIndex, pageIndex > latestPageIndex {
      return
    }
    onPageRequest.fire(pageIndex)
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
  public func update(_ searchResults: SearchResults<Record>, with query: Query) {
    isLastQueryEmpty = query.query.isNilOrEmpty
    paginator.process(searchResults)
    latestPageIndex = searchResults.pagesCount - 1
    onResultsUpdated.fire(searchResults)
  }
  
  public func connect(to filterState: FilterState) {
    filterState.onChange.subscribePast(with: self) { [weak self] _ in
      self?.onRequestChanged.fire(())
      self?.paginator.invalidate()
    }
  }
  
  public func connect(to searcher: SingleIndexSearcher<Record>) {
    
    searcher.onResultsChanged.subscribePast(with: self) { [weak self] (query, _, result) in
      switch result {
      case .success(let result):
        self?.update(result, with: query)
        
      case .failure(let error):
        print(error)
      }
    }
    
    onPageRequest.subscribePast(with: self) { [weak searcher] page in
      searcher?.indexSearchData.query.page = UInt(page)
      searcher?.search()
    }
    
    searcher.onQueryChanged.subscribePast(with: self) { [weak self] _ in
      self?.paginator.invalidate()
      self?.onRequestChanged.fire(())
    }
    
  }
  
}
