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
    [context setGlobalKey: @"testval" value: @(1.1)];
    
    NSString *ret = [context eval: @"console.log(typeof testval)"];
//    XCTAssert([ret isEqualToString: @"hello"]);
}

- (void) testContext_ObjectMapping {
    QJSRuntime *runtime = [[QJSRuntime alloc] init];
    QJSContext *context = [runtime newContext];

    [context setGlobalKey: @"boolVal" value: @YES];
    NSString *typeOfBool = [context eval: @"typeof boolVal;"];
    XCTAssert([typeOfBool isEqualToString: @"boolean"]);
    XCTAssert([[context getGlobalKey: @"boolVal"] isEqual: @YES]);
    XCTAssert([[context eval: @"boolVal;"] isEqual: @YES]);

    [context setGlobalKey: @"intVal" value: @(1) ];
    NSString *typeOfInt = [context eval: @"typeof intVal;"];
    XCTAssert([typeOfInt isEqualToString: @"number"]);
    XCTAssert([[context getGlobalKey: @"intVal"] isEqual: @(1)]);
    XCTAssert([[context eval: @"intVal;"] isEqual: @(1)]);

    [context setGlobalKey: @"doubleVal" value: @(1.1)];
    NSString *typeOfDouble = [context eval: @"typeof doubleVal;"];
    XCTAssert([typeOfDouble isEqualToString: @"number"]);
    XCTAssert([[context getGlobalKey: @"doubleVal"] isEqual: @(1.1)]);
    XCTAssert([[context eval: @"doubleVal;"] isEqual: @(1.1)]);

    [context setGlobalKey: @"stringVal" value: @"test"];
    NSString *typeOfString = [context eval: @"typeof stringVal;"];
    XCTAssert([typeOfString isEqualToString: @"string"]);
    XCTAssert([[context getGlobalKey: @"stringVal"] isEqual: @"test"]);
    XCTAssert([[context eval: @"stringVal;"] isEqual: @"test"]);

    NSArray *array = @[@1, @(1.1), @"test", @YES];
    [context setGlobalKey: @"arrayVal" value: array];
    NSString *typeOfArray = [context eval: @"typeof arrayVal;"];
    XCTAssert([typeOfArray isEqualToString: @"object"]);
    XCTAssert([[context getGlobalKey: @"arrayVal"] isEqual: array]);
    XCTAssert([[context eval: @"arrayVal;"] isEqual: array]);
    
}

- (void) testClasses{
    NSLog(@"%@", @YES.class);
    NSLog(@"%@", [NSNumber numberWithInteger: 1].class);
    NSLog(@"%@", @(1.1).class);
    
    CFNumberType numberType = CFNumberGetType((CFNumberRef)@YES);
    NSLog(@"%d", numberType);
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
