//
//  Decodable+InitWithFile.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 03/06/2020.
//  Copyright © 2020 Algolia. All rights reserved.
//

import Foundation
import AlgoliaSearchClientSwift

enum JSONReadingError: Error {
  case wrongPath
  case invalidData
}

extension Decodable {
  
  init(jsonFile: String, bundle: Bundle = .main) throws {
    
    guard let url = bundle.path(forResource: jsonFile, ofType: "json").flatMap(URL.init(fileURLWithPath:)) else {
      throw JSONReadingError.wrongPath
    }
    
    guard let data = try? Data(contentsOf: url, options: .mappedIfSafe) else {
      throw JSONReadingError.invalidData
    }
    
    let decoder = JSONDecoder()
    let item = try decoder.decode(Self.self, from: data)

    self = item
  }
  
  init(json: JSON) throws {
    let data = try JSONEncoder().encode(json)
    self = try JSONDecoder().decode(Self.self, from: data)
  }
  
}
