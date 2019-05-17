//
//  Query+Facets.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 17/05/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension Query {
  
  func updateQueryFacets(with attribute: Attribute) {
    let updatedFacets: [String]
    
    if let facets = facets, !facets.contains(attribute.name) {
      updatedFacets = facets + [attribute.name]
    } else {
      updatedFacets = [attribute.name]
    }
    
    facets = updatedFacets
  }
  
}
