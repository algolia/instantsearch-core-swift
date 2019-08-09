//
//  QueryInputInteractor+Controller.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 28/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension QueryInputInteractor {
  
  public func connectController<Controller: QueryInputController>(_ controller: Controller) {
    
    onQueryChanged.subscribePast(with: controller) { controller, query in
      controller.setQuery(query)
    }
    controller.onQueryChanged = { [weak self] in
      self?.query = $0
    }
    controller.onQuerySubmitted = { [weak self] in
      self?.query = $0
      self?.submitQuery()
    }
    
  }
  
}
