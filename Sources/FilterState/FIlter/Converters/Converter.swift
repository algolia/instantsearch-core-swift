//
//  Converter.swift
//  AlgoliaSearch
//
//  Created by Vladislav Fitc on 05/04/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

protocol FilterConverter {
  
  associatedtype Output
  
  func convert(_ filter: Filter) -> Output
}
