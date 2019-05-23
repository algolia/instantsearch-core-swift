//
//  LabelStatsController.swift
//  InstantSearchCore
//
//  Created by Guy Daher on 23/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import UIKit

public class LabelStatsController: StatsController {

  let label: UILabel

  public init (label: UILabel) {
    self.label = label
  }

  public func renderWith(query: String?, totalHitsCount: Int, page: Int, pagesCount: Int, processingTimeMS: Int, areFacetsCountExhaustive: Bool?) {
    if let areFacetsCountExhaustive = areFacetsCountExhaustive {
      label.text = "\(areFacetsCountExhaustive ? "" : "~")hits: \(totalHitsCount)"
    }
  }

}
