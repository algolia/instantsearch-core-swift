//
//  FacetResults.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 05/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

/// A value of a given facet, together with its number of occurrences.
/// This struct is mainly useful when an ordered list of facet values has to be presented to the user.
///
struct FacetValue: Codable {
    let value: String
    let count: Int
    let highlighted: String
}

/// Search for facet value results.
struct FacetResults: Codable {
    
    enum CodingKeys: String, CodingKey {
        case facetHits
        case processingTimeMS
        case areFacetsCountExhaustive = "exhaustiveFacetsCount"
    }
    
    let facetHits: [FacetValue]
    let processingTimeMS: Int
    let areFacetsCountExhaustive: Bool
    
}
