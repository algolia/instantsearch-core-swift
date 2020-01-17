//
//  FilterTrackable.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 19/12/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import InstantSearchInsights

extension Insights: FilterTrackable {}

protocol FilterTrackable {
  
  func viewed(eventName: String,
              indexName: String,
              filters: [String],
              userToken: String?)
  
  func clicked(eventName: String,
               indexName: String,
               filters: [String],
               userToken: String?)
  
  func converted(eventName: String,
                 indexName: String,
                 filters: [String],
                 userToken: String?)
  
}
