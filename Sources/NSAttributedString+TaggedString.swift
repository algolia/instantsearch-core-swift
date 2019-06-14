//
//  NSAttributedString+TaggedString.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 14/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension NSAttributedString {
  
  public convenience init(taggedString: TaggedString, inverted: Bool = false, attributes: [NSAttributedString.Key: Any]) {
    let attributedString = NSMutableAttributedString(string: taggedString.output)
    let ranges = inverted ? taggedString.untaggedRanges : taggedString.taggedRanges
    ranges.forEach { range in
      attributedString.addAttributes(attributes, range: NSRange(range, in: taggedString.output))
    }
    self.init(attributedString: attributedString)
  }
  
}
