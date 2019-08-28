//
//  PlacesSearcher.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 28/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import CoreLocation

struct Geolocation: Codable {
  
  let latitude: Double
  let longitude: Double
  
  enum CodingKeys: String, CodingKey {
    case latitude = "lat"
    case longitude = "lng"
  }
  
}

extension Geolocation: CustomDebugStringConvertible {
  
  var debugDescription: String {
    return "{ lat: \(latitude), lon: \(longitude) }"
  }
  
}

extension Geolocation {
  
  init(_ coordinate: CLLocationCoordinate2D) {
    self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
  }
  
}

extension CLLocationCoordinate2D {
  
  init(_ geolocation: Geolocation) {
    self.init(latitude: geolocation.latitude, longitude: geolocation.longitude)
  }
  
}

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

public struct PlacesResults: Codable {
  
  let hits: [PlaceHit]
  
}

public class PlacesSearcher: Searcher, SequencerDelegate, SearchResultObservable {
  
  public typealias SearchResult = PlacesResults
  
  public var query: String? {
    
    get {
      return placesQuery.query
    }
    
    set {
      let oldValue = placesQuery.query
      guard oldValue != newValue else { return }
      placesQuery.query = newValue
      onQueryChanged.fire(newValue)
      
    }

  }
  
  public var placesQuery: PlacesQuery
  
  public var onQueryChanged: Observer<String?>
  
  public let isLoading: Observer<Bool>

  public let onResults: Observer<SearchResult>

  /// Triggered when an error occured during search query execution
  /// - Parameter: a tuple of query text and error
  public let onError: Observer<(String, Error)>
  
  /// Sequencer which orders and debounce redundant search operations
  internal let sequencer: Sequencer

  internal let placesClient: PlacesClient
  
  public convenience init(appID: String,
                          apiKey: String,
                          query: PlacesQuery = .init()) {
    let client = PlacesClient(appID: appID, apiKey: apiKey)
    self.init(client: client, query: query)
  }
  
  public init(client: PlacesClient, query: PlacesQuery = .init()) {
    self.placesClient = client
    self.placesQuery = query
    self.isLoading = .init()
    self.onQueryChanged = .init()
    self.onResults = .init()
    self.onError = .init()
    self.sequencer = .init()
    sequencer.delegate = self
    onResults.retainLastData = true
    isLoading.retainLastData = true
  }
  
  public func search() {
    
    let query = self.query ?? ""
    
    let operation = placesClient.search(PlacesQuery(query: query)) { [weak self] (content, error) in
      guard let searcher = self else { return }
      let result: Result<PlacesResults, Error> = searcher.transform(content: content, error: error)
      
      switch result {
      case .success(let results):
        searcher.onResults.fire(results)
        
      case .failure(let error):
        searcher.onError.fire((query, error))
      }
    }
    
    sequencer.orderOperation {
      return operation
    }
    
  }
  
  public func cancel() {
    sequencer.cancelPendingOperations()
  }
  
}
