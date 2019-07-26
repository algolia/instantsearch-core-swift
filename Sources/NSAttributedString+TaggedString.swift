//
//  NSAttributedString+TaggedString.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 14/06/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation

extension NSAttributedString {
  
  public convenience init(taggedString: TaggedString,
                          inverted: Bool = false,
                          attributes: [NSAttributedString.Key: Any]) {
    let attributedString = NSMutableAttributedString(string: taggedString.output)
    let ranges = inverted ? taggedString.untaggedRanges : taggedString.taggedRanges
    ranges.forEach { range in
      attributedString.addAttributes(attributes, range: NSRange(range, in: taggedString.output))
    }
    self.init(attributedString: attributedString)
  }
  
  public convenience init(highlightedString: HighlightedString,
                          inverted: Bool = false,
                          attributes: [NSAttributedString.Key: Any]) {
    self.init(taggedString: highlightedString.taggedString, inverted: inverted, attributes: attributes)
  }
  
  public convenience init<T>(highlightResult: Hit<T>.HighlightResult,
                             inverted: Bool = false,
                             attributes: [NSAttributedString.Key: Any]) {
    self.init(taggedString: highlightResult.value.taggedString, inverted: inverted, attributes: attributes)
  }
  
  public convenience init(taggedStrings: [TaggedString],
                          inverted: Bool = false,
                          separator: NSAttributedString,
                          attributes: [NSAttributedString.Key: Any]) {
    
    let resultString = NSMutableAttributedString()
    
    for (idx, taggedString) in taggedStrings.enumerated() {
      
      let substring = NSAttributedString(taggedString: taggedString, inverted: inverted, attributes: attributes)
      resultString.append(substring)
      
      // No need to add separator if joined last substring
      if idx != taggedStrings.endIndex - 1 {
        resultString.append(separator)
      }
    }
    
    self.init(attributedString: resultString)
    
  }
  
  public convenience init<T>(highlightedResults: [Hit<T>.HighlightResult],
                             inverted: Bool = false,
                             separator: NSAttributedString,
                             attributes: [NSAttributedString.Key: Any]) {
    let taggedStrings = highlightedResults.map { $0.value.taggedString }
    self.init(taggedStrings: taggedStrings,
              inverted: inverted,
              separator: separator,
              attributes: attributes)
  }
  
}
