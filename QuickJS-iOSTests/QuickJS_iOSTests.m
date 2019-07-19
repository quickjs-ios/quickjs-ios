//
//  QuickJS_iOSTests.m
//  QuickJS-iOSTests
//
//  Created by Sam Chang on 7/18/19.
//  Copyright © 2019 Sam Chang. All rights reserved.
//

#import <QuickJS-iOS/QuickJS_iOS.h>

#import <XCTest/XCTest.h>

@interface QuickJS_iOSTests : XCTestCase

@end

@implementation QuickJS_iOSTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testInitRuntime {
    QJSRuntime *runtime = [[QJSRuntime alloc] init];
    XCTAssert(runtime.rt != NULL);
    XCTAssert([QJSRuntime numberOfRuntimes] == 1);
    runtime = nil;
    XCTAssert([QJSRuntime numberOfRuntimes] == 0);
}

- (void)testInitContext {
    QJSRuntime *runtime = [[QJSRuntime alloc] init];
    QJSContext *context = [runtime newContext];
    XCTAssert([runtime numberOfContexts] == 1);
    context = nil;
    XCTAssert([runtime numberOfContexts] == 0);
}

- (void)xtestMultiContexts {
    QJSRuntime *runtime = [[QJSRuntime alloc] init];
    QJSContext *context1 = [runtime newContext];
    context1 = nil;
    QJSContext *context2 = [runtime newContext];
    XCTAssert([runtime numberOfContexts] == 2);
    
    runtime = nil;
    XCTAssert([QJSRuntime numberOfRuntimes] == 1);

    context1 = nil;
    XCTAssert([QJSRuntime numberOfRuntimes] == 1);
    context2 = nil;
    XCTAssert([QJSRuntime numberOfRuntimes] == 0);
}

- (void)testContextSmokeTest {
    QJSRuntime *runtime = [[QJSRuntime alloc] init];
    QJSContext *context = [runtime newContext];
    NSString *ret = [context eval: @"function foo() {return 'hello';} foo();"];
    XCTAssert([ret isEqualToString: @"hello"]);
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
