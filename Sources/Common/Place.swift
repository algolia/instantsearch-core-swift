//
//  PlaceHit.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 28/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

enum PlaceCodingKeys: String, CodingKey {
  case localeNames = "locale_names"
  case country
  case county
  case postcode
  case city
  case isCity = "is_city"
}

public struct GenericPlace: Codable {
  
  public let localeNames: [String: [String]]?
  public let country: [String: String]?
  public let county: [String: [String]]?
  public let postcode: [String]?
  public let city: [String: [String]]?
  public let isCity: Bool

  typealias CodingKeys = PlaceCodingKeys
}

public struct Place: Codable {
  
  public let localeNames: [String]?
  public let country: String?
  public let county: [String]?
  public let postcode: [String]?
  public let city: [String]?
  public let isCity: Bool
  
  typealias CodingKeys = PlaceCodingKeys

  init(genericPlace: GenericPlace, language: String = "default") {
    self.localeNames = genericPlace.localeNames?[language] ?? []
    self.country = genericPlace.country?[language] ?? ""
    self.county = genericPlace.county?[language] ?? []
    self.postcode = genericPlace.postcode
    self.city = genericPlace.city?[language] ?? []
    self.isCity = genericPlace.isCity
  }
  
}

extension Place: CustomStringConvertible {
  
  public var description: String {
    return localeNames?.first ?? ""
  }
  
}

extension Place: CustomDebugStringConvertible {
  
  public var debugDescription: String {
    return "{ locale names: \(localeNames ?? []), country: \(country ?? ""), county: \(county ?? []) }"
  }
  
}
