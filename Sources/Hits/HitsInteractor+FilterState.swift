//
//  HitsInteractor+FilterState.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 25/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension AnyHitsInteractor {
  
  public func connectFilterState(_ filterState: FilterState) {
    filterState.onChange.subscribePast(with: self) { interactor, _ in
      interactor.notifyQueryChanged()
    }
  }
  
}
