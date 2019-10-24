//
//  PlaceFormatter.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 11/09/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

class PlaceFormatter {
  
  let place: Place
  
  init(place: Place) {
    self.place = place
  }
  
  func getOutput() -> String {
    
    let name = place.localeNames.first
    let country = place.country
//    let city = place.
    
    return ""
  }
  
}
