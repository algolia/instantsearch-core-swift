//
//  QueryInputViewModel+Controller.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 28/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension QueryInputViewModel {
  
  public func connect<C: QueryInputController>(_ controller: C) {
    onQueryChanged.subscribePast(with: controller, callback: controller.setQuery)
    controller.onQueryChanged = { self.query = $0 }
    controller.onQuerySubmitted = {
      self.query = $0
      self.submitQuery()
    }
  }
  
}
