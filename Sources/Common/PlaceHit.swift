//
//  PlaceHit.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 28/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public struct PlaceHit: Codable {
  
  public let id: String
  public let localeNames: [String]
  public let country: String
  public let county: [String]?
  public let administrative: [String]
  public let geolocation: Geolocation
  
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
  
  public var description: String {
    return localeNames.first ?? ""
  }
  
}

extension PlaceHit: CustomDebugStringConvertible {
  
  public var debugDescription: String {
    return "{ id: \(id), locale names: \(localeNames), country: \(country), county: \(county ?? []), administrative: \(administrative), location: \(geolocation) }"
  }
  
}
