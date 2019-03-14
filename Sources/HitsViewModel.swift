//
//  HitsViewModel.swift
//  InstantSearch
//
//  Created by Guy Daher on 15/02/2019.
//

import Foundation
import Signals
import InstantSearchClient

// DISCUSSION: should we expose those through KVO? dynamic var in case someone wants to listen to them?
// something like: viewModel.bind(\.navigationTitle, to: navigationItem, at: \.title),

public class HitsViewModel<RecordType: Decodable> {

  public var settings: Settings

  var hitsPaginationController: PaginationController<RecordType, QueryMetadata>
  
  var hitsPageMap: PageMap<RecordType>? {
    return hitsPaginationController.pageMap
  }
  
  private var isLastQueryEmpty: Bool = true
  public let onNewPage = Signal<UInt>()

  convenience public init(infiniteScrolling: Bool = true,
              remainingItemsBeforeLoading: UInt = 5,
              showItemsOnEmptyQuery: Bool = true) {
    let settings = Settings(infiniteScrolling: infiniteScrolling,
                            remainingItemsBeforeLoading: remainingItemsBeforeLoading,
                            showItemsOnEmptyQuery: showItemsOnEmptyQuery)
    self.init(hitsSettings: settings)
  }

  public init(hitsSettings: Settings? = nil) {
    self.hitsPaginationController = PaginationController<RecordType, QueryMetadata>()
    self.settings = hitsSettings ?? Settings()
    self.hitsPaginationController.delegate = self
  }

  // TODO: What if there was an error? What do we do with "LoadMore" functionality (lastSentPage to decrement?)
  public func update(with queryMetadata: QueryMetadata, and searchResults: SearchResults<RecordType>) {
    isLastQueryEmpty = queryMetadata.queryText.isNilOrEmpty
    hitsPaginationController.process(searchResults, with: queryMetadata)
  }

  public func numberOfRows() -> Int {
    guard let hitsPageMap = hitsPageMap else { return 0 }
    
    if isLastQueryEmpty && !settings.showItemsOnEmptyQuery {
      return 0
    } else {
      return hitsPageMap.count
    }
  }

  public func hasMoreResults() -> Bool {
    guard let hitsPageMap = hitsPageMap else { return false }
    return hitsPageMap.hasMorePages
  }

  public func loadMoreResults() {
    guard let hitsPageMap = hitsPageMap, hitsPageMap.hasMorePages else { return } // Throw error?
    notifyNextPage()
  }

  public func hitForRow(_ row: Int) -> RecordType? {
    guard let hitsPageMap = hitsPageMap else { return nil }

    loadMoreIfNecessary(rowNumber: row)
    return hitsPageMap[row]
  }

  private func notifyNextPage() {
    hitsPaginationController.loadNextPageIfNeeded()
  }

  // TODO: Here we're always loading the next page, but we don't handle the case where a page is missing in the middle for some reason
  // So we will need to detect which page the row corresponds at, and check if we're missing the page. then check the threshold offset to determine
  // if we load previous or next page (in case we don't have them loaded/cached already in our itemsPage struct
  private func loadMoreIfNecessary(rowNumber: Int) {

    guard settings.infiniteScrolling, let hits = hitsPageMap else { return }

    let rowToLoad = rowNumber + Int(settings.pageLoadOffset)
    //print("notify next page with row \(rowNumber) and rowToLoad \(rowToLoad), lastRequestPage \(lastSentPage), latestPage \(hits.latestPage), hitsCount \(hits.count)")

    if !hits.containsItem(atIndex: rowToLoad), hits.hasMorePages {
      print("notifying next page")
      notifyNextPage()
    }
  }
  
}

extension HitsViewModel: PaginationControllerDelegate {
  
  func didRequestLoadPage(withNumber number: UInt) {
    onNewPage.fire(number)
  }
  
}

extension HitsViewModel {
  
  public struct Settings {
    public var infiniteScrolling: Bool
    public var pageLoadOffset: UInt
    public var showItemsOnEmptyQuery: Bool
    
    public init(infiniteScrolling: Bool = Constants.Defaults.infiniteScrolling, remainingItemsBeforeLoading: UInt = Constants.Defaults.remainingItemsBeforeLoading, showItemsOnEmptyQuery: Bool = Constants.Defaults.showItemsOnEmptyQuery) {
      self.infiniteScrolling = infiniteScrolling
      self.pageLoadOffset = remainingItemsBeforeLoading
      self.showItemsOnEmptyQuery = showItemsOnEmptyQuery
    }
  }
  
}

extension HitsViewModel {

  // Easy accessor for common settings

  public var infiniteScrolling: Bool {
    set {
      settings.infiniteScrolling = newValue
    }
    get {
      return settings.infiniteScrolling
    }
  }

  public var remainingItemsBeforeLoading: UInt {
    set {
      settings.pageLoadOffset = newValue
    }
    get {
      return settings.pageLoadOffset
    }
  }

  public var showItemsOnEmptyQuery: Bool {
    set {
      settings.showItemsOnEmptyQuery = newValue
    }
    get {
      return settings.showItemsOnEmptyQuery
    }
  }
}
