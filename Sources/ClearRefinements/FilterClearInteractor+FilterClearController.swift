//
//  FilterClearInteractor+FilterClearController.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 13/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension FilterClearInteractor {
  
  func connectController(_ controller: FilterClearController) {
    controller.onClick = { [weak self] in
      self?.onTriggered.fire(())
    }
  }
  
}
