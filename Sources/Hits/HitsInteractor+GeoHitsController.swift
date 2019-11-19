//
//  HitsInteractor+GeoHitsController.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/10/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension HitsInteractor where Record: Geolocated {
  
  func connectController<Controller: GeoHitsController>(_ controller: Controller) where Controller.DataSource == HitsInteractor<Record> {

    controller.hitsSource = self
        
    onResultsUpdated.subscribePast(with: controller) { (controller, _) in
      controller.reload()
    }.onQueue(.main)
    
  }

}
