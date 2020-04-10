//
//  InsightsTracker.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 20/12/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import InstantSearchInsights

public protocol InsightsTracker: class {
  
  init(eventName: String, searcher: TrackableSearcher, insights: Insights)
  
}

extension InsightsTracker {
  
  public init(eventName: String,
              searcher: SingleIndexSearcher,
              userToken: String? = .none) {
    let index = searcher.indexQueryState.index
    let insights = Insights.register(appId: index.applicationID.rawValue, apiKey: index.apiKey.rawValue, userToken: userToken)
    self.init(eventName: eventName,
              searcher: .singleIndex(searcher),
              insights: insights)
  }

  public init(eventName: String,
              searcher: SingleIndexSearcher,
              insights: Insights) {
    self.init(eventName: eventName,
              searcher: .singleIndex(searcher),
              insights: insights)
  }
  
  public init(eventName: String,
              searcher: MultiIndexSearcher,
              pointer: Int,
              userToken: String? = .none) {
    let index = searcher.indexQueryStates[pointer].index
    let insights = Insights.register(appId: index.applicationID.rawValue, apiKey: index.apiKey.rawValue, userToken: userToken)
    self.init(eventName: eventName,
              searcher: .multiIndex(searcher, pointer: pointer),
              insights: insights)
  }

  public init(eventName: String,
              searcher: MultiIndexSearcher,
              pointer: Int,
              insights: Insights) {
    self.init(eventName: eventName,
              searcher: .multiIndex(searcher, pointer: pointer),
              insights: insights)
  }
  
}
