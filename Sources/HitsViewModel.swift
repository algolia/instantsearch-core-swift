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

public class HitsViewModel<RecordType: Codable> {

  public let settings: Settings

  private let hitsPaginationController: Paginator<RecordType, QueryMetadata>
  
  private var isLastQueryEmpty: Bool = true
  
  public var hasMoreResults: Bool {
    return hitsPaginationController.pageMap?.hasMorePages ?? false
  }
  
  public let onNewPage = Observer<UInt>()

  convenience public init(infiniteScrolling: InfiniteScrolling = Constants.Defaults.infiniteScrolling,
                          showItemsOnEmptyQuery: Bool = Constants.Defaults.showItemsOnEmptyQuery) {
    let settings = Settings(infiniteScrolling: infiniteScrolling,
                            showItemsOnEmptyQuery: showItemsOnEmptyQuery)
    self.init(settings: settings)
  }

  public init(settings: Settings? = nil) {
    self.settings = settings ?? Settings()
    self.hitsPaginationController = Paginator<RecordType, QueryMetadata>()
    self.hitsPaginationController.delegate = self
  }
  
  internal init(settings: Settings? = nil,
                paginationController: Paginator<RecordType, QueryMetadata>) {
    self.settings = settings ?? Settings()
    self.hitsPaginationController = paginationController
  }

  // TODO: What if there was an error? What do we do with "LoadMore" functionality (lastSentPage to decrement?)
  public func update(_ searchResults: SearchResults<RecordType>, with queryMetadata: QueryMetadata) {
    isLastQueryEmpty = queryMetadata.queryText.isNilOrEmpty
    hitsPaginationController.process(searchResults, with: queryMetadata)
  }

  public func numberOfRows() -> Int {
    guard let hitsPageMap = hitsPaginationController.pageMap else { return 0 }
    
    if isLastQueryEmpty && !settings.showItemsOnEmptyQuery {
      return 0
    } else {
      return hitsPageMap.count
    }
  }

  public func hitForRow(_ row: Int) -> RecordType? {
    guard let hitsPageMap = hitsPaginationController.pageMap else { return nil }

    loadMoreIfNeeded(rowNumber: row)
    return hitsPageMap[row]
  }
  
  public func rawHitForRow(_ row: Int) -> [String: Any]? {
    guard let hit = hitForRow(row) else { return nil }
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

public extension HitsViewModel where RecordType == JSON {
  
  func rawHitForRow(_ row: Int) -> [String: Any]? {
    return hitForRow(row).flatMap([String: Any].init)
  }
  
}

extension HitsViewModel: PaginatorDelegate {
  
  func didRequestLoadPage(withNumber number: UInt) {
    onNewPage.fire(number)
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
