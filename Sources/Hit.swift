//
//  Hit.swift
//  InstantSearchCore-iOS
//
//  Created by Vladislav Fitc on 05/03/2019.
//  Copyright © 2019 Algolia. All rights reserved.
//

import Foundation


/// Wraps a generic hit object with its meta information

struct Hit<T: Codable>: Codable {
    
    let object: T
    let snippetResult: [String: SnippetResult]?
    let highlightResult: [String: EitherSingleOrList<HighlightResult>]?
    let rankingInfo: RankingInfo?
    
    enum CodingKeys: String, CodingKey {
        case snippetResult = "_snippetResult"
        case highlightResult = "_highlightResult"
        case rankingInfo = "_rankingInfo"
    }
    
    init(from decoder: Decoder) throws {
        self.object = try T(from: decoder)
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.snippetResult = try container.decodeIfPresent([String: SnippetResult].self, forKey: .snippetResult)
        self.highlightResult = try container.decodeIfPresent([String: EitherSingleOrList<HighlightResult>].self, forKey: .highlightResult)
        self.rankingInfo = try container.decodeIfPresent(RankingInfo.self, forKey: .rankingInfo)
    }
    
}

extension Hit {
    
    /// Snippet result for an attribute of a hit.
    
    struct SnippetResult: Codable {
        /// Value of this snippet.
        let value: String
        
        /// Match level.
        let matchLevel: MatchLevel
    }
    
    /// Match level of a highlight or snippet result.
    
    enum MatchLevel: String, Codable, CustomStringConvertible {
        
        /// All the query terms were found in the attribute.
        case none
        
        /// Only some of the query terms were found in the attribute.
        case partial
        
        /// None of the query terms were found in the attribute.
        case full
        
        var description: String {
            return self.rawValue
        }
        
    }
    
    /// Highlight result for an attribute of a hit.
    
    struct HighlightResult: Codable {
        /// Value of this highlight.
        let value: String
        
        /// Match level.
        let matchLevel: MatchLevel
        
        /// List of matched words.
        let matchedWords: [String]
    }
    
    /// Ranking info for a hit.
    
    struct RankingInfo: Codable {
        
        /// Number of typos encountered when matching the record.
        /// Corresponds to the `typos` ranking criterion in the ranking formula.
        let typosCount: Int
        
        /// Position of the most important matched attribute in the attributes to index list.
        /// Corresponds to the `attribute` ranking criterion in the ranking formula.
        let firstMatchedWord: Int
        
        /// When the query contains more than one word, the sum of the distances between matched words.
        /// Corresponds to the `proximity` criterion in the ranking formula.
        let proximityDistance: Int
        
        /// Custom ranking for the object, expressed as a single numerical value.
        /// Conceptually, it's what the position of the object would be in the list of all objects sorted by custom ranking.
        /// Corresponds to the `custom` criterion in the ranking formula.
        let userScore: Int
        
        /// Distance between the geo location in the search query and the best matching geo location in the record, divided
        /// by the geo precision.
        let geoDistance: Int
        
        /// Precision used when computed the geo distance, in meters.
        /// All distances will be floored to a multiple of this precision.
        let geoPrecision: Int
        
        /// Number of exactly matched words.
        /// If `alternativeAsExact` is set, it may include plurals and/or synonyms.
        let exactWordsCount: Int
        
        /// Number of matched words, including prefixes and typos.
        let words: Int
        
        /// Score from filters.
        /// + Warning: *This field is reserved for advanced usage.* It will be zero in most cases.
        let filters: Int
        
        enum CodingKeys: String, CodingKey {
            case typosCount = "nbTypos"
            case firstMatchedWord
            case proximityDistance
            case userScore
            case geoDistance
            case geoPrecision
            case exactWordsCount = "nbExactWords"
            case words
            case filters
        }
        
    }
    
}
