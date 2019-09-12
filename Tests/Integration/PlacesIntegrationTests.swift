//
//  PlacesIntegrationTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 11/09/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import XCTest
@testable import InstantSearchCore

extension SearchResults {
  
  var prettyHitsString: String {
    let hits = self.hits.compactMap([String: Any].init)
    let data = try! JSONSerialization.data(withJSONObject: hits, options: .prettyPrinted)
    return String(data: data, encoding: .utf8)!
  }
  
}

class PlacesIntegrationTests: XCTestCase {
  
  let appID = Bundle(for: OnlineTestCase.self).object(forInfoDictionaryKey: "ALGOLIA_PLACES_APPLICATION_ID") as? String ?? ""
  let apiKey = Bundle(for: OnlineTestCase.self).object(forInfoDictionaryKey: "ALGOLIA_PLACES_API_KEY") as? String ?? ""
  
  enum Language: String, Codable {
    case pl, zh, ja, ru, ro, de, nl, ar, es, hu, it, pt, en, fr, `default`
  }
  
  enum PlaceCodingKeys: String, CodingKey {
    case localeNames = "locale_names"
    case country
    case county
    case postcode
    case city
    case isCity = "is_city"
  }
  
  struct GenericPlace: Codable {
    
    let localeNames: [String: [String]]
    let country: [String: String]
    let county: [String: [String]]
    let postcode: [String]?
    let city: [String: [String]]?
    fileprivate let isCity: Bool

    typealias CodingKeys = PlaceCodingKeys
  }
  
  struct Place: Codable {
    
    let localeNames: [String]
    let country: String
    let county: [String]
    let postcode: [String]?
    let city: [String]?
    fileprivate let isCity: Bool
    
    typealias CodingKeys = PlaceCodingKeys

    init(genericPlace: GenericPlace, language: String = "default") {
      self.localeNames = genericPlace.localeNames[language] ?? []
      self.country = genericPlace.country[language] ?? ""
      self.county = genericPlace.county[language] ?? []
      self.postcode = genericPlace.postcode
      self.city = genericPlace.city?[language] ?? []
      self.isCity = genericPlace.isCity
    }
    
  }
  
  class PlaceFormatter {
    
    func string(for place: Place) -> String {
      let country = place.country
      let county = place.county.first
      let postcode = place.postcode?.first
      let city = (place.isCity ? place.localeNames : place.city)?.first
      let streetName = place.isCity ? nil : place.localeNames.first
      let components = [streetName, city, postcode, county, country].compactMap { $0 }.filter { $0 != "" }
      return components.joined(separator: ", ")
    }
    
    func string(for genericPlace: GenericPlace, forLanguage language: String = "default") -> String {
      return string(for: Place(genericPlace: genericPlace, language: language))
    }
    
  }
  
  func testGenericResponse() {
    
    let searcher = PlacesSearcher(appID: appID, apiKey: apiKey)
    
    searcher.placesQuery.query = "lon"
    searcher.placesQuery.language = nil
    
    let exp = self.expectation(description: "Response expectation")
    searcher.onResults.subscribe(with: self) { (_, result) in

      
      do {
        let genericPlaces: [GenericPlace] = try result.deserializeHits()
        let placesFormatter = PlaceFormatter()
        genericPlaces.map { placesFormatter.string(for: $0) }.forEach { print($0) }
      } catch let error {
        print(error)
      }
      
      exp.fulfill()
    }
    
    searcher.search()
    
    waitForExpectations(timeout: 5, handler: .none)
    
  }
  
  func testLocalizedResponse() {
    
    let searcher = PlacesSearcher(appID: appID, apiKey: apiKey)
    
    searcher.placesQuery.query = "lon"
    searcher.placesQuery.language = "en"
    
    let exp = self.expectation(description: "Response expectation")
    searcher.onResults.subscribe(with: self) { (_, result) in
      do {
        let places: [Place] = try result.deserializeHits()
        let placesFormatter = PlaceFormatter()
        places.map(placesFormatter.string(for:)).forEach { print($0) }
      } catch let error {
        print(error)
      }
      
      exp.fulfill()
    }
    
    searcher.search()
    
    waitForExpectations(timeout: 5, handler: .none)

    
  }
  
  func getBestHighlightedForm<I: Codable>(from highlightResults: [Hit<I>.HighlightResult]) -> HighlightedString? {
    
    guard let firstResult = highlightResults.first else { return nil }
    
    let defaultValue = firstResult.value.taggedString.input
    
    let bestAttributes = highlightResults
      .filter { $0.matchLevel != .none }
      .enumerated()
      .sorted { lhs, rhs in
        guard lhs.element.matchedWords.count != rhs.element.matchedWords.count else {
          return lhs.offset < rhs.offset
        }
        return lhs.element.matchedWords.count > rhs.element.matchedWords.count
      }
    
    guard let theBestAttribute = bestAttributes.first else { return HighlightedString(string: defaultValue) }
    
    let first: String
    let second: String
    
    if theBestAttribute.offset == 0 {
      first = defaultValue
      second = highlightResults[bestAttributes[1].offset].value.taggedString.input
    } else {
      first = highlightResults[theBestAttribute.offset].value.taggedString.input
      second = defaultValue
    }
    
    return HighlightedString(string: [first, second].filter { !$0.isEmpty }.joined(separator: " "))
    
  }
  
}
