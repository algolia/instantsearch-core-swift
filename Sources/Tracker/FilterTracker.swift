//
//  FilterTracker.swift
//  InstantSearchCore
//
//  Created by Vladislav Fitc on 18/12/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation
import InstantSearchClient
import InstantSearchInsights

public class FilterTracker {
  
  public var eventName: String
  public var searcher: SingleIndexSearcher
  public var insights: Insights?
  
  private var indexName: String {
    return searcher.indexQueryState.index.name
  }

  public init(eventName: String,
              searcher: SingleIndexSearcher,
              insights: Insights? = .shared) {
    self.eventName = eventName
    self.searcher = searcher
    self.insights = insights
  }
    
}

// MARK: - Filter tracking methods

public extension FilterTracker {
  
  func trackClick<F: FilterType>(for filter: F,
                                 eventName customEventName: String? = nil) {
    guard let sqlForm = (filter as? SQLSyntaxConvertible)?.sqlForm else { return }
    insights?.clicked(eventName: customEventName ?? eventName, indexName: indexName, filters: [sqlForm])
  }
  
  func trackView<F: FilterType>(for filter: F,
                                eventName customEventName: String? = nil) {
    guard let sqlForm = (filter as? SQLSyntaxConvertible)?.sqlForm else { return }
    insights?.viewed(eventName: customEventName ?? eventName, indexName: indexName, filters: [sqlForm])
  }
  
  func trackConversion<F: FilterType>(for filter: F,
                                      eventName customEventName: String? = nil) {
    guard let sqlForm = (filter as? SQLSyntaxConvertible)?.sqlForm else { return }
    insights?.converted(eventName: customEventName ?? eventName, indexName: indexName, filters: [sqlForm])
  }
  
}

// MARK: - Facet tracking methods

public extension FilterTracker {
  
  private func filter(for facet: Facet, with attribute: Attribute) -> Filter.Facet {
    return Filter.Facet(attribute: attribute, stringValue: facet.value)
  }
  
  func trackClick(for facet: Facet,
                  attribute: Attribute,
                  eventName customEventName: String? = nil) {
    trackClick(for: filter(for: facet, with: attribute), eventName: customEventName ?? eventName)
  }
  
  func trackView(for facet: Facet,
                 attribute: Attribute,
                 eventName customEventName: String? = nil) {
    trackClick(for: filter(for: facet, with: attribute), eventName: customEventName ?? eventName)
  }
  
  func trackConversion(for facet: Facet,
                       attribute: Attribute,
                       eventName customEventName: String? = nil) {
    trackClick(for: filter(for: facet, with: attribute), eventName: customEventName ?? eventName)
  }
  
}
