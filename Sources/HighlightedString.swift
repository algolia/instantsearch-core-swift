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
    self.taggedString = TaggedString(string: string, preTag: HighlightedString.preTag, postTag: HighlightedString.postTag, options: [.caseInsensitive])
  }
  
  public init(from decoder: Decoder) throws {
    let container = try decoder.singleValueContainer()
    let input = try container.decode(String.self)
    self.init(string: input)
  }
  
  public func encode(to encoder: Encoder) throws {
    var container = encoder.singleValueContainer()
    try container.encode(taggedString.input)
  }
  
}
