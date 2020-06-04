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


///TODO: remove
public class PlacesIntegrationTests: XCTestCase {
  
  let appID = Bundle(for: OnlineTestCase.self).object(forInfoDictionaryKey: "ALGOLIA_PLACES_APPLICATION_ID") as? String ?? ""
  let apiKey = Bundle(for: OnlineTestCase.self).object(forInfoDictionaryKey: "ALGOLIA_PLACES_API_KEY") as? String ?? ""
  
  enum Language: String, Codable {
    case pl, zh, ja, ru, ro, de, nl, ar, es, hu, it, pt, en, fr, `default`
  }
  
  func testGenericResponse() {
    
    let searcher = PlacesSearcher(appID: ApplicationID(rawValue: appID), apiKey: APIKey(rawValue: apiKey))
    
    searcher.placesQuery.query = "lon"
    searcher.placesQuery.language = nil
    
    let exp = self.expectation(description: "Response expectation")
    searcher.onResults.subscribe(with: self) { (_, result) in

      do {
        let _: [GenericPlace] = try result.deserializeHits()
      } catch let error {
        print(error)
      }
      exp.fulfill()

    }
    
    searcher.search()
    
    waitForExpectations(timeout: 5, handler: .none)
    
  }
  
  func testLocalizedResponse() {
    
    let searcher = PlacesSearcher(appID: ApplicationID(rawValue: appID), apiKey: APIKey(rawValue: apiKey))

    searcher.placesQuery.query = "lon"
    searcher.placesQuery.language = "en"
    
    let exp = self.expectation(description: "Response expectation")
    searcher.onResults.subscribe(with: self) { (_, result) in
      do {
        let _: [Hit<Place>] = try result.deserializeHits()
      } catch let error {
        print(error)
      }
      
      exp.fulfill()
    }
    
    searcher.search()
    
    waitForExpectations(timeout: 5, handler: .none)
    
  }
  
}

