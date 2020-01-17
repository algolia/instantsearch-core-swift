//
//  TestHitsTracker.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 20/12/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore

class TestHitsTracker: HitsAfterSearchTrackable {
  
  var didClick: (((eventName: String, indexName: String, objectIDsWithPositions: [(String, Int)], queryID: String, userToken: String?)) -> Void)?
  var didConvert: (((eventName: String, indexName: String, objectIDs: [String], queryID: String, userToken: String?)) -> Void)?
  var didView: (((eventName: String, indexName: String, objectIDs: [String], userToken: String?)) -> Void)?
  
  func clickedAfterSearch(eventName: String, indexName: String, objectIDsWithPositions: [(String, Int)], queryID: String, userToken: String?) {
      didClick?((eventName, indexName, objectIDsWithPositions, queryID, userToken))
  }
  
  func convertedAfterSearch(eventName: String, indexName: String, objectIDs: [String], queryID: String, userToken: String?) {
    didConvert?((eventName, indexName, objectIDs, queryID, userToken))
  }
  
  func viewed(eventName: String, indexName: String, objectIDs: [String], userToken: String?) {
    didView?((eventName, indexName, objectIDs, userToken))
  }
  
  
}
