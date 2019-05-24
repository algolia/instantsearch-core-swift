//
//  Stats.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 24/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public struct StatsMetadata {
  public let query: String?
  public let totalHitsCount: Int
  public let page: Int
  public let pagesCount: Int
  public let processingTimeMS: Int
  public let areFacetsCountExhaustive: Bool?
}
