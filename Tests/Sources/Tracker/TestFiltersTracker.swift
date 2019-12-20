//
//  TestFiltersTracker.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 20/12/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore

class TestFiltersTracker: FilterTrackable {
  
  enum EventType { case view, click, convert }
  
  var did: (((EventType, eventName: String, indexName: String, filters: [String], userToken: String?)) -> Void)?
  
  func viewed(eventName: String, indexName: String, filters: [String], userToken: String?) {
    did?((.view, eventName, indexName, filters, userToken))
  }
  
  func clicked(eventName: String, indexName: String, filters: [String], userToken: String?) {
    did?((.click, eventName, indexName, filters, userToken))
  }
  
  func converted(eventName: String, indexName: String, filters: [String], userToken: String?) {
    did?((.convert, eventName, indexName, filters, userToken))
  }
  
}
