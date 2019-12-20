//
//  InsightsTracker.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 20/12/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import InstantSearchInsights

protocol InsightsTracker: class {
  
  init(eventName: String, searcher: TrackableSearcher, insights: Insights)
  
}

extension InsightsTracker {
  
  public init(eventName: String,
              searcher: SingleIndexSearcher,
              appID: String,
              apiKey: String,
              userToken: String? = .none) {
    let insights = Insights.register(appId: appID, apiKey: apiKey, userToken: userToken)
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
              appID: String,
              apiKey: String,
              userToken: String? = .none) {
    let insights = Insights.register(appId: appID, apiKey: apiKey, userToken: userToken)
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
