//
//  StatsInteractor+Controller.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 29/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension StatsInteractor {
  
  func connectController<C: StatsTextController>(_ controller: C) {
    connectController(controller, presenter: DefaultPresenter.Stats.present)
  }
  
}
