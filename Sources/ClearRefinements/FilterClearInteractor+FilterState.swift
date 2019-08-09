//
//  FilterClearInteractor+FilterState.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 24/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension FilterClearInteractor {
  
  func connectFilterState(_ filterState: FilterState,
                          filterGroupIDs: [FilterGroup.ID]? = nil,
                          clearMode: ClearMode = .specified) {
    onTriggered.subscribe(with: self) { [weak filterState] _, _ in
      defer {
        filterState?.notifyChange()
      }

      guard let filterGroupIDs = filterGroupIDs else {
        filterState?.filters.removeAll()
        return
      }
      
      switch clearMode {
      case .specified:
        filterState?.filters.removeAll(fromGroupWithIDs: filterGroupIDs)
      case .except:
        filterState?.filters.removeAllExcept(filterGroupIDs)
      }
      
    }
  }

}

public enum ClearMode {
  case specified
  case except
}
