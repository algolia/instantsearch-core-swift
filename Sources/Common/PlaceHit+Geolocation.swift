//
//  PlaceHit+Geolocation.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 28/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public extension Place {
  
  struct Geolocation: Codable, Equatable {
    
    public let latitude: Double
    public let longitude: Double
    
    enum CodingKeys: String, CodingKey {
      case latitude = "lat"
      case longitude = "lng"
    }
    
  }
    
}

extension Place.Geolocation: CustomDebugStringConvertible {
  
  public var debugDescription: String {
    return "{ lat: \(latitude), lon: \(longitude) }"
  }
  
}
