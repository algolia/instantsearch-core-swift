//
//  HitsAfterSearchTrackable.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 19/12/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import InstantSearchInsights

protocol HitsAfterSearchTrackable {
  
  func clickedAfterSearch(eventName: String,
                          indexName: String,
                          objectIDsWithPositions: [(String, Int)],
                          queryID: String,
                          userToken: String?)
  
  func convertedAfterSearch(eventName: String,
                            indexName: String,
                            objectIDs: [String],
                            queryID: String,
                            userToken: String?)
  
  func viewed(eventName: String,
              indexName: String,
              objectIDs: [String],
              userToken: String?)
  
}

extension Insights: HitsAfterSearchTrackable {}
