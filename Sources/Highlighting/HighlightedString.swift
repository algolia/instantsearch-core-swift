//
//  HighlightedString.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 14/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

public struct HighlightedString: Codable, Hashable {
  
  static let preTag = "<em>"
  static let postTag = "</em>"
  
  public let taggedString: TaggedString
  
  public init(string: String) {
    let input = string.cString(using: .utf8).flatMap { .init(cString: $0)  } ?? string
    self.taggedString = TaggedString(string: input, preTag: HighlightedString.preTag, postTag: HighlightedString.postTag, options: [.caseInsensitive])
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let decodedString = try container.decode(String.self)
    self.init(string: decodedString)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(taggedString.input)
  }
  
}
