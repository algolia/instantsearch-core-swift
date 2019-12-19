//
//  HitsInteractor+Tracker.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 18/12/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import InstantSearchClient
import InstantSearchInsights

public class HitsTracker {
  
  public let eventName: String
  public let searcher: SingleIndexSearcher
  public var insights: Insights?
  private var queryID: String?
  
  private var indexName: String {
    return searcher.indexQueryState.index.name
  }
  
  public init(eventName: String,
              searcher: SingleIndexSearcher,
              insights: Insights? = .shared) {
    self.eventName = eventName
    self.searcher = searcher
    self.insights = insights
    searcher.indexQueryState.query.clickAnalytics = true
    searcher.onResults.subscribe(with: self) { (tracker, results) in
      tracker.queryID = results.queryID
    }
  }
  
  deinit {
    searcher.onResults.cancelSubscription(for: self)
  }
  
}

// MARK: - Hits tracking methods

public extension HitsTracker {
  
  func trackClick<Record: Codable>(for hit: Hit<Record>,
                                   position: Int,
                                   eventName customEventName: String? = nil) {
    guard let queryID = queryID else { return }
    insights?.clickedAfterSearch(eventName: customEventName ?? self.eventName, indexName: indexName, objectID: hit.objectID, position: position, queryID: queryID)
  }
  
  func trackConvert<Record: Codable>(for hit: Hit<Record>,
                                     eventName customEventName: String? = nil) {
    guard let queryID = queryID else { return }
    insights?.convertedAfterSearch(eventName: customEventName ?? self.eventName, indexName: indexName, objectID: hit.objectID, queryID: queryID)
  }
  
  func trackView<Record: Codable>(for hit: Hit<Record>,
                                  eventName customEventName: String? = nil) {
    insights?.viewed(eventName: customEventName ?? self.eventName, indexName: indexName, objectID: hit.objectID)
  }
  
}
