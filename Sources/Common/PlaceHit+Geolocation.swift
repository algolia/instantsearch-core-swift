//
//  PlaceHit+Geolocation.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 28/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension PlaceHit {
  
  struct Geolocation: Codable {
    
    let latitude: Double
    let longitude: Double
    
    enum CodingKeys: String, CodingKey {
      case latitude = "lat"
      case longitude = "lng"
    }
    
  }
  
}

extension PlaceHit.Geolocation: CustomDebugStringConvertible {
  
  var debugDescription: String {
    return "{ lat: \(latitude), lon: \(longitude) }"
  }
  
}
