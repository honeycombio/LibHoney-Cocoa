//
//  LibHoneyTests-Objc.m
//  LibHoney-Tests
//
//  Created by Chong Han Chua on 11/8/17.
//

#import <XCTest/XCTest.h>
@import LibHoney;

/// These tests just test that the Objective-C version of the APIs are accessible.
/// functionality is test in the swift version of the tests
@interface LibHoneyTests_Objc : XCTestCase

@end

@implementation LibHoneyTests_Objc

- (void)testLibHoney {
    [LibHoney configureWithWriteKey:@"Test" dataset:@"Test"];
    [LibHoney configureWithWriteKey:@"Test" dataset:@"Test" apiHost: @"https://api.honeycomb.io" sampleRate:1 maxBatchSize:10 sendFrequency:0.1];
    
    XCTAssert([LibHoney.shared addKey:@"intVal" intValue:1] == LibHoney.shared);
    XCTAssert([LibHoney.shared addKey:@"boolVal" boolValue:YES] == LibHoney.shared);
    XCTAssert([LibHoney.shared addKey:@"doubleVal" doubleValue: 3.14] == LibHoney.shared);
    XCTAssert([LibHoney.shared addKey:@"stringVal" boolValue:@"Hello, world"] == LibHoney.shared);
}

- (void)testDefaultConfigs {
    XCTAssert([HoneyConfigDefaults.apiHost isEqualToString: @"https://api.honeycomb.io"]);
    XCTAssert(HoneyConfigDefaults.sampleRate == 1);
    XCTAssert(HoneyConfigDefaults.maxBatchSize == 50);
    XCTAssert(HoneyConfigDefaults.sendFrequency == 0.1);
}

- (void)testHoneyEvent {
    [LibHoney configureWithWriteKey:@"Test" dataset:@"Test"];
    HoneyEvent* event = [LibHoney.shared newEvent];
    XCTAssert([event addKey:@"boolVal" boolValue:NO] == event);
    XCTAssert([event addKey:@"intVal" intValue:1] == event);
    XCTAssert([event addKey:@"doubleVal" doubleValue:3.14] == event);
    XCTAssert([event addKey:@"stringVal" stringValue:@"Hello,m world"] == event);
    // [LibHoney.shared send:event];
}


@end
