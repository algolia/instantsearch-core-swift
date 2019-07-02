//
//  HierarchicalIntegrationTests.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 02/07/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

class HierarchicalTests: OnlineTestCase {
  
  struct Item: Codable {
    let objectID: String = UUID().uuidString
    let name: String
    let hierarchicalCategories: [String: String]
  }
  
  func testHierachical() {
    
    let items = try! [Item](jsonFile: "hierarchical", bundle: Bundle(for: HierarchicalTests.self))
    let data = try! JSONEncoder().encode(items)
    let objects: [[String: Any]] = try! JSONSerialization.jsonObject(with: data, options: []) as! [[String : Any]]
    
  }
  
}
