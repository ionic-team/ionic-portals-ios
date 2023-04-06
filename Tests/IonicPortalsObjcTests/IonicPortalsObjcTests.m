//
//  IonicPortalsObjcTests.m
//  IonicPortalsObjcTests
//
//  Created by Steven Sherry on 5/14/22.
//

#import <XCTest/XCTest.h>
@import IonicPortals;

@interface IonicPortalsObjcTests : XCTestCase

@end

@implementation IonicPortalsObjcTests

- (void)testIONPubSub__when_provided_a_simple_json_compatible_value__it_can_be_coerced_correctly {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Callback should have fired"];
    
    id subRef = [IONPortalsPubSub subscribeToTopic:@"test" callback:^(NSDictionary<NSString *,id> * _Nonnull dict) {
        BOOL aBool = dict[@"data"];
        XCTAssertTrue(aBool);
        [expectation fulfill];
    }];
    
    [IONPortalsPubSub publishMessage:@YES toTopic:@"test"];
    
    [self waitForExpectations:@[expectation] timeout:1.0];
}

- (void)testIONPubSub__when_provided_a_non_json_compatible_value__it_cannot_be_coerced_correctly {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Callback should not have fired"];
    [expectation setInverted:YES];
    
    id subRef = [IONPortalsPubSub subscribeToTopic:@"test" callback:^(NSDictionary<NSString *,id> * _Nonnull dict) {
        [expectation fulfill];
    }];
    
    NSError *nonJsonCompatible = [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:1 userInfo:nil];
    [IONPortalsPubSub publishMessage:nonJsonCompatible toTopic:@"test"];
    
    [self waitForExpectations:@[expectation] timeout:1.0];
}

- (void)testIONPubSub__when_provided_a_json_compatible_nsdictionary__it_correctly_coerces_it {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Callback should have fired"];
    
    NSDictionary *aDict = @{
        @"number": @1,
        @"string": @"hello",
        @"array": @[@1, @2, @3],
        @"bool": @YES,
        @"null": [NSNull null],
        @"object": @{
            @"key": @"value"
        }
    };
    
    id subRef = [IONPortalsPubSub subscribeToTopic:@"test" callback:^(NSDictionary<NSString *,id> * _Nonnull dict) {
        NSDictionary *publishedDict = dict[@"data"];
        XCTAssertTrue([publishedDict isEqualToDictionary:aDict]);
        [expectation fulfill];
    }];
    
    [IONPortalsPubSub publishMessage:aDict toTopic:@"test"];
    
    [self waitForExpectations:@[expectation] timeout:1.0];
}

- (void)testIONPubSub__when_provided_an_nsdictionary_with_objects_incompatible_with_json__it_only_coerces_valid_data {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Callback should have fired"];
    
    NSDictionary *aDictToPublish = @{
        @"number": @1,
        @"string": @"hello",
        @"array": @[@1, @2, @3],
        @"bool": @YES,
        @"null": [NSNull null],
        @"incompatibleError": [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:1 userInfo:nil],
        @"object": @{
            @"key": @"value"
        }
    };
    
    id subRef = [IONPortalsPubSub subscribeToTopic:@"test" callback:^(NSDictionary<NSString *,id> * _Nonnull dict) {
        NSDictionary *publishedDict = dict[@"data"];
        NSDictionary *expectedDict = @{
            @"number": @1,
            @"string": @"hello",
            @"array": @[@1, @2, @3],
            @"bool": @YES,
            @"null": [NSNull null],
            @"object": @{
                @"key": @"value"
            }
        };
        
        XCTAssertTrue([publishedDict isEqualToDictionary:expectedDict]);
        [expectation fulfill];
    }];
    
    [IONPortalsPubSub publishMessage:aDictToPublish toTopic:@"test"];
    
    [self waitForExpectations:@[expectation] timeout:1.0];
}

- (void)testIONPubSub__when_provided_a_json_compatible_nsarray__it_correctly_coerces_it {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Callback should have fired"];
    
    NSArray *anArray = @[@"hello", @43, @45.5, [NSNull null]];
    
    id subRef = [IONPortalsPubSub subscribeToTopic:@"test" callback:^(NSDictionary<NSString *,id> * _Nonnull dict) {
        NSArray *publishedArray = dict[@"data"];
        XCTAssertTrue([publishedArray isEqualToArray:anArray]);
        [expectation fulfill];
    }];
    
    [IONPortalsPubSub publishMessage:anArray toTopic:@"test"];
    
    [self waitForExpectations:@[expectation] timeout:1.0];
}

- (void)testIONPubSub__when_provided_an_nsarray_with_incompatible_elements__incompatible_elements_are_ignored {
    XCTestExpectation *expectation = [self expectationWithDescription:@"Callback should have fired"];
    
    NSArray *anArray = @[@"hello", [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:1 userInfo:nil], @43, @45.5, [NSNull null], [[NSPredicate alloc] init]];
    
    id subRef = [IONPortalsPubSub subscribeToTopic:@"test" callback:^(NSDictionary<NSString *,id> * _Nonnull dict) {
        NSArray *publishedArray = dict[@"data"];
        NSArray *expectedArray = @[@"hello", @43, @45.5, [NSNull null]];
        XCTAssertTrue([publishedArray isEqualToArray:expectedArray]);
        [expectation fulfill];
    }];
    
    [IONPortalsPubSub publishMessage:anArray toTopic:@"test"];
    
    [self waitForExpectations:@[expectation] timeout:1.0];
}

- (void)testIONPortal_init__when_provided_a_valid_json_representable_nsdictionary__it_is_correctly_coerced {
    NSDictionary *initialContext = @{
        @"number": @1,
        @"string": @"hello",
        @"array": @[@1, @2, @3],
        @"bool": @YES,
        @"null": [NSNull null],
        @"object": @{
            @"key": @"value"
        }
    };
    
    IONPortal *portal = [[IONPortal alloc] initWithName:@"test" startDir:nil initialContext:initialContext];
    
    XCTAssertTrue([initialContext isEqualToDictionary:portal.initialContext]);
}

- (void)testIONPortal_init__when_provided_an_nsdictionary_with_incompatible_elements__incompatible_elements_are_ignored {
    NSDictionary *initialContext = @{
        @"number": @1,
        @"string": @"hello",
        @"array": @[@1, @2, @3],
        @"bool": @YES,
        @"null": [NSNull null],
        @"incompatibleError": [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:1 userInfo:nil],
        @"object": @{
            @"key": @"value"
        }
    };
    
    IONPortal *portal = [[IONPortal alloc] initWithName:@"test" startDir:nil initialContext:initialContext];
    
    NSDictionary *expectedDict = @{
        @"number": @1,
        @"string": @"hello",
        @"array": @[@1, @2, @3],
        @"bool": @YES,
        @"null": [NSNull null],
        @"object": @{
            @"key": @"value"
        }
    };
    
    XCTAssertTrue([portal.initialContext isEqualToDictionary:expectedDict]);
}

- (void)testIONPortal_init__when_provided_an_nsdictionary_with_entirely_incompatible_elements__the_dictionary_is_completely_ignored {
    NSDictionary *initialContext = @{
        @"incompatibleError": [[NSError alloc] initWithDomain:NSCocoaErrorDomain code:1 userInfo:nil],
    };
    
    IONPortal *portal = [[IONPortal alloc] initWithName:@"test" startDir:nil initialContext:initialContext];
    
    XCTAssertTrue([portal.initialContext isEqualToDictionary:@{}]);
}
@end

