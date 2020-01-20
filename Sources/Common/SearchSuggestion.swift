//
//  SearchSuggestion.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 20/01/2020.
//  Copyright © 2020 Algolia. All rights reserved.
//

import Foundation

public struct SearchSuggestion: Codable {
  
  public let query: String
  public let popularity: Int
  
}
