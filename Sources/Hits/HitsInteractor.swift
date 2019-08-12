//
//  HitsInteractor.swift
//  InstantSearch
//
//  Created by Guy Daher on 15/02/2019.
//

import Foundation
import InstantSearchClient

public class HitsInteractor<Record: Codable>: AnyHitsInteractor {
  
  public let settings: Settings

  private let paginator: Paginator<Record>
  private var isLastQueryEmpty: Bool = true
  private let infiniteScrollingController: InfiniteScrollable
  
  public let onRequestChanged: Observer<Void>
  public let onResultsUpdated: Observer<SearchResults>
  public let onError: Observer<Swift.Error>
  
  public var pageLoader: PageLoadable? {
    
    get {
      return infiniteScrollingController.pageLoader
    }
    
    set {
      infiniteScrollingController.pageLoader = newValue
    }
    
  }
  
  convenience public init(infiniteScrolling: InfiniteScrolling = Constants.Defaults.infiniteScrolling,
                          showItemsOnEmptyQuery: Bool = Constants.Defaults.showItemsOnEmptyQuery) {
    let settings = Settings(infiniteScrolling: infiniteScrolling,
                            showItemsOnEmptyQuery: showItemsOnEmptyQuery)
    self.init(settings: settings)
  }

  public convenience init(settings: Settings? = nil) {
    self.init(settings: settings,
              paginationController: Paginator<Record>(),
              infiniteScrollingController: InfiniteScrollingController())
  }
  
  internal init(settings: Settings? = nil,
                paginationController: Paginator<Record>,
                infiniteScrollingController: InfiniteScrollable) {
    self.settings = settings ?? Settings()
    self.paginator = paginationController
    self.infiniteScrollingController = infiniteScrollingController
    self.onRequestChanged = .init()
    self.onResultsUpdated = .init()
    self.onError = .init()
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
    notifyForInfiniteScrolling(rowNumber: index)
    return hitsPageMap[index]
  }
  
  public func rawHitAtIndex(_ row: Int) -> [String: Any]? {
    guard let hit = hit(atIndex: row) else { return nil }
    guard let data = try? JSONEncoder().encode(hit) else { return nil }
    guard let jsonValue = try? JSONDecoder().decode(JSON.self, from: data) else { return nil }
    return [String: Any](jsonValue)
  }
  
  public func notifyPending(atIndex index: Int) {
    infiniteScrollingController.notifyPending(pageIndex: index)
  }
  
  public func genericHitAtIndex<R: Decodable>(_ index: Int) throws -> R? {
    
    guard let hit = hit(atIndex: index) else {
      return .none
    }
    
    if let castedHit = hit as? R {
      return castedHit
    } else {
      throw Error.incompatibleRecordType
    }
    
  }

}

extension HitsInteractor {
  
  public enum Error: Swift.Error, LocalizedError {
    case incompatibleRecordType
    
    var localizedDescription: String {
      return "Unexpected record type: \(String(describing: Record.self))"
    }
    
  }
  
}

private extension HitsInteractor {
  
  func notifyForInfiniteScrolling(rowNumber: Int) {
    guard
      case .on(let pageLoadOffset) = settings.infiniteScrolling,
      let hitsPageMap = paginator.pageMap else { return }
    
    infiniteScrollingController.calculatePagesAndLoad(currentRow: rowNumber, offset: pageLoadOffset, pageMap: hitsPageMap)
  }
  
}

public extension HitsInteractor where Record == JSON {
  
  func rawHitForRow(_ row: Int) -> [String: Any]? {
    return hit(atIndex: row).flatMap([String: Any].init)
  }
  
}

extension HitsInteractor {
  
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
  case on(withOffset: Int)
  case off
}

extension HitsInteractor {
  
  public func notifyQueryChanged() {
    if case .on = settings.infiniteScrolling {
      infiniteScrollingController.notifyPendingAll()
    }
    
    paginator.invalidate()
    onRequestChanged.fire(())
  }
  
  public func update(_ searchResults: SearchResults) throws {
    
    if case .on = settings.infiniteScrolling {
      infiniteScrollingController.notifyPending(pageIndex: searchResults.stats.page)
      infiniteScrollingController.lastPageIndex = searchResults.stats.pagesCount - 1
    }
    isLastQueryEmpty = searchResults.stats.query.isNilOrEmpty

    do {
      let page: HitsPage<Record> = try HitsPage(searchResults: searchResults)
      paginator.process(page)
      onResultsUpdated.fire(searchResults)
    } catch let error {
      onError.fire(error)
      throw error
    }
    
  }
  
  public func process(_ error: Swift.Error, for query: Query) {
    if let pendingPage = query.page {
      infiniteScrollingController.notifyPending(pageIndex: Int(pendingPage))
    }
  }
  
}
