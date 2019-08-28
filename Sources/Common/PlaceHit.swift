//
//  PlaceHit.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 28/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

struct PlaceHit: Codable {
  
  let id: String
  let localeNames: [String]
  let country: String
  let county: [String]?
  let administrative: [String]
  let geolocation: Geolocation
  
  enum CodingKeys: String, CodingKey {
    case id = "objectID"
    case geolocation = "_geoloc"
    case localeNames = "locale_names"
    case country
    case county
    case administrative
  }
  
}

extension PlaceHit: CustomStringConvertible {
  
  var description: String {
    return localeNames.first ?? ""
  }
  
}

extension PlaceHit: CustomDebugStringConvertible {
  
  var debugDescription: String {
    return "{ id: \(id), locale names: \(localeNames), country: \(country), county: \(county ?? []), administrative: \(administrative), location: \(geolocation) }"
  }
  
}
