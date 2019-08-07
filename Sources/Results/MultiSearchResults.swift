//
//  MultiSearchResults.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 07/08/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public struct MultiSearchResults: Codable {
  
  public let searchResults: [SearchResults]
  
  enum CodingKeys: String, CodingKey {
    case results
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    searchResults = try container.decode([SearchResults].self, forKey: .results)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(searchResults, forKey: .results)
  }
  
}
