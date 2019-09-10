//
//  PlaceHit+Geolocation+CoreLocation.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 28/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

import CoreLocation

public extension Place.Geolocation {
  
  init(_ coordinate: CLLocationCoordinate2D) {
    self.init(latitude: coordinate.latitude, longitude: coordinate.longitude)
  }
  
}

public extension CLLocationCoordinate2D {
  
  init(_ geolocation: Place.Geolocation) {
    self.init(latitude: geolocation.latitude, longitude: geolocation.longitude)
  }
  
}

public extension CLLocation {
  
  convenience init(_ geolocation: Place.Geolocation) {
    self.init(latitude: geolocation.latitude, longitude: geolocation.longitude)
  }
  
}
