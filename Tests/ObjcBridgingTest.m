//
//  ObjcBridgingTest.m
//  AlgoliaSearchHelper
//
//  Created by Clément Le Provost on 12/09/16.
//  Copyright © 2016 Algolia. All rights reserved.
//

#import <XCTest/XCTest.h>

@import AlgoliaSearch;
@import AlgoliaSearchHelper;


/// Check Objective-C bridging.
///
/// + Note: This tests mostly **compilation** and **naming**. Behavior is already tested in Swift.
///
@interface ObjcBridgingTest : XCTestCase <SearchProgressDelegate>

@end


@implementation ObjcBridgingTest

- (void)setUp {
    [super setUp];
}

- (void)tearDown {
    [super tearDown];
}

- (void)testDebouncer {
    Debouncer* debouncer = [[Debouncer alloc] initWithDelay:0.1];
    [debouncer call:^{
        // Nothing to do.
    }];
}

- (void)testHighlightRenderer {
    HighlightRenderer* renderer = [[HighlightRenderer alloc] initWithHighlightAttrs:@{ @"foo": @"bar" }];
    renderer.preTag = @"<mark>";
    renderer.postTag = @"</mark>";
    renderer.caseSensitive = false;
    NSAttributedString* attributedString = [renderer renderText:@"Snoopy is <MARK>Woodstock</MARK>'s friend"];
    NSLog(@"%@", attributedString);
}

- (void)testSearcher {
    Client* client = [[Client alloc] initWithAppID:@"APPID" apiKey:@"APIKEY"];
    Index* index = [client indexWithName:@"INDEX_NAME"];
    Searcher* searcher = [[Searcher alloc] initWithIndex:index];
    [searcher addResultHandler:^(SearchResults* results, NSError* error) {
        // Nothing to do.
    }];
    searcher.disjunctiveFacets = @[ @"foo", @"bar" ];
    [searcher setFacetWithName:@"bar" disjunctive:YES];
    [searcher addFacetRefinementWithName:@"foo" value:@"xyz"];
    XCTAssertTrue([searcher hasFacetRefinementWithName:@"foo" value:@"xyz"]);
    [searcher removeFacetRefinementWithName:@"foo" value:@"xyz"];
    XCTAssertFalse([searcher hasFacetRefinementWithName:@"foo" value:@"xyz"]);
    [searcher toggleFacetRefinementWithName:@"foo" value:@"xyz"];
    [searcher clearFacetRefinementsWithName:@"foo"];
    [searcher clearFacetRefinements];
    searcher.query = [[Query alloc] initWithQuery:@"text"];
    [searcher search];
    XCTAssertTrue(searcher.hasPendingRequests);
    [searcher loadMore];
    [searcher cancelRequestWithSeqNo:1];
    [searcher cancelPendingRequests];
}

- (void)testSearchProgressController {
    Client* client = [[Client alloc] initWithAppID:@"APPID" apiKey:@"APIKEY"];
    Index* index = [client indexWithName:@"INDEX_NAME"];
    Searcher* searcher = [[Searcher alloc] initWithIndex:index];
    SearchProgressController* spc = [[SearchProgressController alloc] initWithSearcher:searcher];
    spc.delegate = self;
}

- (void)searchDidStart:(SearchProgressController*)spc {
    // Nothing to do.
}

- (void)searchDidStop:(SearchProgressController*)spc {
    // Nothing to do.
}

- (void)testSearchResults {
    NSDictionary<NSString*, id>* const JSON = @{
        @"hits": @[
            @{ @"foo": @"bar" }
        ],
        @"nbHits": @66,
        @"page": @1,
        @"hitsPerPage": @6,
        @"nbPages": @11,
        @"query": @"",
        @"params": @""
    };
    
    NSError* error = nil;
    SearchResults* results = [[SearchResults alloc] initWithContent:JSON disjunctiveFacets:@[] error:&error];
    XCTAssertNil(error);
    XCTAssertNotNil(results);
    XCTAssertEqual(66, results.nbHits);
    XCTAssertEqual(1, results.page);
    XCTAssertEqual(6, results.hitsPerPage);
    XCTAssertEqual(11, results.nbPages);
    XCTAssertEqual(0, results.processingTimeMS);
    XCTAssertEqualObjects(@"", results.query);
    XCTAssertEqualObjects([Query new], results.params);
    XCTAssertEqual(false, results.exhaustiveFacetsCount);
    XCTAssertNil(results.message);
    XCTAssertNil(results.queryAfterRemoval);
    XCTAssertNil(results.aroundLatLng);
    XCTAssertEqual(0, results.automaticRadius);
    XCTAssertNil(results.serverUsed);
    XCTAssertNil(results.parsedQuery);
    XCTAssertEqual(false, results.timeoutCounts);
    XCTAssertEqual(false, results.timeoutHits);
    XCTAssertNil([results facetsWithName:@"foo"]);
    XCTAssertNil([results facetStatsWithName:@"foo"]);
    XCTAssertNil([results highlightResultAt:0 path:@"foo"]);
    XCTAssertNil([results snippetResultAt:0 path:@"foo"]);
    XCTAssertNil([results rankingInfoAt:0]);
    XCTAssertNil([SearchResults highlightResultWithHit:JSON[@"hits"][0] path:@"foo"]);
    XCTAssertNil([SearchResults snippetResultWithHit:JSON[@"hits"][0] path:@"foo"]);
}

@end
