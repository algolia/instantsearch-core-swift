//
//  FacetResultsTests.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 05/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
@testable import InstantSearchCore
import XCTest

class FacetResultsTests: XCTestCase {

    func testFacetResultsDecoding() {
        
        guard let searchResultURL = Bundle.init(for: SearchResultsV2Tests.self).path(forResource: "FacetResult", ofType: "json").flatMap(URL.init(fileURLWithPath:)) else {
            XCTFail("Cannot read file")
            return
        }
        
        guard let data = try? Data(contentsOf: searchResultURL, options: .mappedIfSafe) else {
            XCTFail("Cannot parse data")
            return
        }
        
        XCTAssertFalse(data.isEmpty, "Data is empty")
        
        let decoder = JSONDecoder()
        
        do {
            let facetResults = try decoder.decode(V2.FacetResults.self, from: data)
            XCTAssertTrue(facetResults.areFacetsCountExhaustive)
            XCTAssertEqual(facetResults.processingTimeMS, 25)
            XCTAssertEqual(facetResults.facetHits.count, 10)
        } catch let error {
            XCTFail("\(error)")
        }
        
    }

}
