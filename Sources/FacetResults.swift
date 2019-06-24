//
//  FacetResults.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 05/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@_exported import InstantSearchClient

/// A value of a given facet, together with its number of occurrences.
/// This struct is mainly useful when an ordered list of facet values has to be presented to the user.
///
public struct Facet: Codable, Equatable, Hashable {
    public let value: String
    public let count: Int
    public let highlighted: String?
}

public extension Facet {
  
  var isEmpty: Bool {
    return count < 1
  }
  
}

extension Facet: CustomStringConvertible {
  
  public var description: String {
    return "\(value) (\(count))"
  }
  
}

extension Dictionary where Key == String, Value == [String: Int] {
  
  init(_ facetsForAttribute: [Attribute: [Facet]]) {
    self = [:]
    for facetForAttribute in facetsForAttribute {
      let rawAttribute = facetForAttribute.key.description
      self[rawAttribute] = [String: Int](facetForAttribute.value)
    }
  }
  
}

extension Dictionary where Key == String, Value == Int {
  
  init(_ facets: [Facet]) {
    self = [:]
    for facet in facets {
      self[facet.value] = facet.count
    }
  }
  
}

/// Search for facet value results.
public struct FacetResults: Codable {
    
    enum CodingKeys: String, CodingKey {
        case facetHits
        case processingTimeMS
        case areFacetsCountExhaustive = "exhaustiveFacetsCount"
    }
    
    public let facetHits: [Facet]
    public let processingTimeMS: Int
    public let areFacetsCountExhaustive: Bool
    
}
