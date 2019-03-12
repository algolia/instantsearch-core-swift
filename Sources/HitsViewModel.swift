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

  public var settings: Settings

  var hits: ItemsPages<RecordType>?
  var lastReceivedQueryMetadata: QueryMetadata?

  var lastSentPage: UInt = 0

  public let onNewPage = Signal<UInt>()

  public init(infiniteScrolling: Bool = true,
              remainingItemsBeforeLoading: UInt = 5,
              showItemsOnEmptyQuery: Bool = true) {
    self.settings = Settings(infiniteScrolling: infiniteScrolling,
                                 remainingItemsBeforeLoading: remainingItemsBeforeLoading,
                                 showItemsOnEmptyQuery: showItemsOnEmptyQuery)
  }

  public init(hitsSettings: Settings? = nil) {
    self.settings = hitsSettings ?? Settings()
  }

  func extractHitsPage(from searchResults: SearchResults<RecordType>) -> (pageNumber: Int, hits: [RecordType]) {
    return (searchResults.page, searchResults.hits)
  }

  // TODO: What if there was an error? What do we do with "LoadMore" functionality (lastSentPage to decrement?)
  public func update(with queryMetadata: QueryMetadata, and searchResults: SearchResults<RecordType>) {

    let (pageNumber, pageHits) = extractHitsPage(from: searchResults)

    print("lastQM: \(self.lastReceivedQueryMetadata), receivedQM \(queryMetadata)")
    if let currentHits = hits,
      let lastQueryMetadata = lastReceivedQueryMetadata,
      queryMetadata.isLoadMoreRequest(lastQueryMetadata: lastQueryMetadata) {
      hits = currentHits.inserting(pageHits, withNumber: pageNumber)
    } else {
      hits = ItemsPages(searchResults: searchResults)
    }

    self.lastReceivedQueryMetadata = queryMetadata
  }

  public func numberOfRows() -> Int {
    guard let hits = hits else { return 0 }
    let query = lastReceivedQueryMetadata?.queryText ?? ""

    if query.isEmpty && !settings.showItemsOnEmptyQuery {
      return 0
    } else {
      return hits.count
    }
  }

  public func hasMoreResults() -> Bool {
    guard let hits = hits else { return false }
    return hits.hasMorePages
  }

  public func loadMoreResults() {
    guard let hits = hits, hits.hasMorePages else { return } // Throw error?
    notifyNextPage()
  }

  public func hitForRow(_ row: Int) -> RecordType? {
    guard let hits = hits else { return nil }

    loadMoreIfNecessary(rowNumber: row)
    return hits[row]
  }

  private func notifyNextPage() {
    guard let lastReceivedQueryMetadata = lastReceivedQueryMetadata else { return }
    let newPageToRequest = lastReceivedQueryMetadata.page + 1
    if newPageToRequest > lastSentPage {
      lastSentPage += 1
      print("Requesting New page newPageToRequest \(newPageToRequest) and new lastRequestedPage \(lastSentPage)")
      //onNewPage.fire(hits.latestPage + 1)
      onNewPage.fire(lastSentPage)
    }
  }

  // TODO: Here we're always loading the next page, but we don't handle the case where a page is missing in the middle for some reason
  // So we will need to detect which page the row corresponds at, and check if we're missing the page. then check the threshold offset to determine
  // if we load previous or next page (in case we don't have them loaded/cached already in our itemsPage struct
  private func loadMoreIfNecessary(rowNumber: Int) {

    guard settings.infiniteScrolling, let hits = hits else { return }

    let rowToLoad = rowNumber + Int(settings.pageLoadOffset)
    print("notify next page with row \(rowNumber) and rowToLoad \(rowToLoad), lastRequestPage \(lastSentPage), latestPage \(hits.latestPage), hitsCount \(hits.count)")

    if !hits.containsItem(atIndex: rowToLoad), hits.hasMorePages {
      print("notifying next page")
      notifyNextPage()
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

struct ItemsPages<Item: Decodable> {

  var pageToItems: [Int: [Item]]

  let latestPage: UInt
  let totalPageCount: Int
  let totalItemsCount: Int

  fileprivate var itemsSequence: [Item]

  mutating func insert(_ page: [Item], withNumber pageNumber: Int) {
    pageToItems[pageNumber] = page
    itemsSequence = pageToItems.sorted { $0.key < $1.key } .flatMap { $0.value }
  }

  func inserting(_ page: [Item], withNumber pageNumber: Int) -> ItemsPages {
    var mutableCopy = self
    mutableCopy.insert(page, withNumber: pageNumber)
    return mutableCopy
  }

  var hasMorePages: Bool {
    return totalPageCount > latestPage + 1
  }

  func containsItem(atIndex index: Int) -> Bool {
      return count > index
  }

}

extension ItemsPages: Sequence {
  func makeIterator() -> ItemsPageIterator<Item> {
    return ItemsPageIterator(itemsPages: self)
  }
}

extension ItemsPages: Collection {
  // Required nested types, that tell Swift what our collection contains
  typealias Index = Array<Item>.Index
  typealias Element = Array<Item>.Element

  // The upper and lower bounds of the collection, used in iterations
  var startIndex: Index { return itemsSequence.startIndex }
  var endIndex: Index { return itemsSequence.endIndex }

  // Required subscript, based on a dictionary index
  subscript(index: Index) -> Iterator.Element {
    get { return itemsSequence[index] }
  }

  // Method that returns the next index when iterating
  func index(after i: Index) -> Index {
    return itemsSequence.index(after: i)
  }
}

struct ItemsPageIterator<Item: Decodable>: IteratorProtocol {

  private let itemsPages: ItemsPages<Item>
  private var iterator: Array<Item>.Iterator

  init(itemsPages: ItemsPages<Item>) {
    self.itemsPages = itemsPages
    self.iterator = itemsPages.itemsSequence.makeIterator()
  }

  mutating func next() -> Item? {
    return iterator.next()
  }

}

extension ItemsPages {

  init(searchResults: SearchResults<Item>) {
    let pageNumber = searchResults.page
    let hits = searchResults.hits
    pageToItems = [pageNumber: hits]
    latestPage = UInt(searchResults.page)
    totalPageCount = searchResults.pagesCount
    totalItemsCount = searchResults.totalHitsCount
    itemsSequence = searchResults.hits
  }

}

public struct QueryMetadata {
  // This is the query in the search bar
  let queryText: String?

  // This is all params that were applied (query, filters etc)
  let filters: String?

  let page: UInt

  init(query: Query) {
    queryText = query.query
    filters = query.filters
    page = query.page ?? 0
  }

  func isLoadMoreRequest(lastQueryMetadata: QueryMetadata) -> Bool {
    return queryText == lastQueryMetadata.queryText && filters == lastQueryMetadata.filters
  }
}

struct SearchResultsMetaData {
  // This is the query Id
  let queryID: String?

  public init<RecordType>(searchResults: SearchResults<RecordType>) {
    self.queryID = searchResults.queryID
  }
}
