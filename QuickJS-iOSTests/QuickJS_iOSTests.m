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

@interface TestObject : NSObject

@end

@implementation TestObject

- (void)dealloc {
    NSLog(@"TestObject dealloc");
}

- (NSArray *)test:(NSNumber *)a:(NSString *)b:(NSNumber *)c {
    NSLog(@"%@ %@ %@", a, b, c);
    return @[@"a", @NO, @(123)];
}

@end

@protocol TestProtocol<NSObject>

- (id)javascriptAddFunc:(id)arg1:(id)arg2:(id)arg3;

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

- (void)testMultiContexts {
    QJSRuntime *runtime = [[QJSRuntime alloc] init];
    QJSContext *context1 = [runtime newContext];
    context1 = nil;
    QJSContext *context2 = [runtime newContext];
    XCTAssert([runtime numberOfContexts] == 1);

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

    QJSValue *globalValue = [context getGlobalValue];
    [globalValue setObject:@(1.1) forKey:@"testval"];

    NSDictionary *ret =
        [context eval:@"console.log(typeof testval); var x = {a:1, b:2};console.log(JSON.stringify(x));x;"].objValue;
    NSLog(@"%@", ret);
    //    XCTAssert([ret isEqualToString: @"hello"]);
}

- (void)testContext_methodInvoke {
    QJSRuntime *runtime = [[QJSRuntime alloc] init];
    QJSContext *context = [runtime newContext];

    TestObject *obj = [TestObject new];
    __weak TestObject *weakObj = obj;

    @autoreleasepool {
        QJSValue *globalValue = [context getGlobalValue];
        [globalValue setObject:obj forKey:@"testval"];
        TestObject *obj2 = [globalValue objectForKey:@"testval"].objValue;
        XCTAssert(obj == obj2);
        obj2 = nil;
        obj = nil;

        NSDictionary *ret = [context eval:@"testval(123);testval.invoke('test', 1, 'a', false);"].objValue;
        NSLog(@"%@", ret);

        // TODO: add this support in native.
        [context
            eval:@"testval = Proxy.revocable(testval, {get: function(target, name){return function(...args){return "
                 @"target.invoke(name, ...args)}}}).proxy;"];

        ret = [context eval:@"testval.test('a', 3, true);"].objValue;
        NSLog(@"%@", ret);
    }

    context = nil;
    XCTAssert(weakObj == nil);
}

- (void)testContext_ObjectMapping {
    @autoreleasepool {
        QJSRuntime *runtime = [[QJSRuntime alloc] init];
        QJSContext *context = [runtime newContext];
        QJSValue *globalValue = [context getGlobalValue];

        [globalValue setObject:@YES forKey:@"boolVal"];
        NSString *typeOfBool = [context eval:@"typeof boolVal;"].objValue;
        XCTAssert([typeOfBool isEqualToString:@"boolean"]);
        XCTAssert([[globalValue objectForKey:@"boolVal"].objValue isEqual:@YES]);
        XCTAssert([[context eval:@"boolVal;"].objValue isEqual:@YES]);

        [globalValue setObject:@(1) forKey:@"intVal"];
        NSString *typeOfInt = [context eval:@"typeof intVal;"].objValue;
        XCTAssert([typeOfInt isEqualToString:@"number"]);
        XCTAssert([[globalValue objectForKey:@"intVal"].objValue isEqual:@(1)]);
        XCTAssert([[context eval:@"intVal;"].objValue isEqual:@(1)]);

        [globalValue setObject:@(1.1) forKey:@"doubleVal"];
        NSString *typeOfDouble = [context eval:@"typeof doubleVal;"].objValue;
        XCTAssert([typeOfDouble isEqualToString:@"number"]);
        XCTAssert([[globalValue objectForKey:@"doubleVal"].objValue isEqual:@(1.1)]);
        XCTAssert([[context eval:@"doubleVal;"].objValue isEqual:@(1.1)]);

        [globalValue setObject:@"test" forKey:@"stringVal"];
        NSString *typeOfString = [context eval:@"typeof stringVal;"].objValue;
        XCTAssert([typeOfString isEqualToString:@"string"]);
        XCTAssert([[globalValue objectForKey:@"stringVal"].objValue isEqual:@"test"]);
        XCTAssert([[context eval:@"stringVal;"].objValue isEqual:@"test"]);

        NSArray *array = @[@1, @(1.1), @"test", @YES];
        [globalValue setObject:array forKey:@"arrayVal"];
        NSString *typeOfArray = [context eval:@"typeof arrayVal;"].objValue;
        XCTAssert([typeOfArray isEqualToString:@"object"]);
        XCTAssert([[globalValue objectForKey:@"arrayVal"].objValue isEqual:array]);
        XCTAssert([[context eval:@"arrayVal;"].objValue isEqual:array]);

        NSDictionary *dic = @{@"k1": @(1), @"k2": @"test", @"100": @YES};
        [globalValue setObject:dic forKey:@"dicVal"];
        NSString *typeOfDic = [context eval:@"typeof dicVal;"].objValue;
        XCTAssert([typeOfDic isEqualToString:@"object"]);
        XCTAssert([[globalValue objectForKey:@"dicVal"].objValue isEqual:dic]);
        XCTAssert([[context eval:@"dicVal;"].objValue isEqual:dic]);
    }

    XCTAssert([QJSRuntime numberOfRuntimes] == 0);
}

- (void)testQJSValue {
    @autoreleasepool {
        QJSRuntime *runtime = [[QJSRuntime alloc] init];
        QJSContext *context = [runtime newContext];
        QJSValue *globalValue = [context getGlobalValue];

        QJSValue *funcValue = [context eval:@"a = function(...args){console.log(...args);return args;};a;"];
        if ([funcValue isFunction]) {
            QJSValue *ret = [funcValue invoke:@"1", @2, @YES, @"end", nil];
            NSArray *array = @[@"1", @2, @YES, @"end"];
            XCTAssert([ret.objValue isEqual:array]);
        }
        funcValue = [context eval:@"a = function(a, b){return a * 10 + b;}; a;"];
        if ([funcValue isFunction]) {
            QJSValue *ret = [funcValue invoke:@(2), @(3), nil];
            XCTAssert([ret.objValue isEqual:@(2 * 10 + 3)]);
        }

        QJSValue *newValue = [context newObjectValue];

        [newValue setObject:@"abc" forKey:@"test"];
        XCTAssert([[newValue.objValue valueForKey:@"test"] isEqual:@"abc"]);

        [newValue setObject:@"abc" forKey:@"test2"];
        XCTAssert([[newValue.objValue valueForKey:@"test2"] isEqual:@"abc"]);
        [newValue removeObjectForKey:@"test2"];
        XCTAssert([newValue.objValue valueForKey:@"test2"] == nil);

        QJSValue *v = [newValue objectForKey:@"test2"];
        XCTAssert([v isUndefined]);

        [globalValue setObject:newValue forKey:@"newValue"];
        [globalValue setObject:[newValue objectForKey:@"test"] forKey:@"test"];
        XCTAssert([[globalValue.objValue valueForKey:@"test"] isEqual:@"abc"]);

        [globalValue setObject:newValue forKey:@"test2"];
        XCTAssert([[context eval:@"newValue.test = 'def';test2.test;"].objValue isEqual:@"def"]);
    }
    XCTAssert([QJSRuntime numberOfRuntimes] == 0);
}

- (void)testQJSValueInterface {
    @autoreleasepool {
        QJSRuntime *runtime = [[QJSRuntime alloc] init];
        QJSContext *context = [runtime newContext];
        QJSValue *destObject =
            [context eval:@"var a = {javascriptAddFunc: function(a, b, c){console.log(c);return a * 10 + b;}}; a;"];
        id<TestProtocol> obj = [destObject asProtocol:@protocol(TestProtocol)];
        id retValue = [obj javascriptAddFunc:@(1):@(2):nil];
        XCTAssert([retValue isEqual:@(12)]);
    }
    XCTAssert([QJSRuntime numberOfRuntimes] == 0);
}

- (void)testQJSContext_Block {
    dispatch_block_t_2 blk = ^id(NSNumber *a, NSNumber *b) {
        return @(a.integerValue * 10 + b.integerValue);
    };

    @autoreleasepool {
        QJSRuntime *runtime = [[QJSRuntime alloc] init];
        QJSContext *context = [runtime newContext];
        QJSValue *globalValue = [context getGlobalValue];
        [globalValue setObject:blk forKey:@"objcAdd"];

        QJSValue *objcAdd = [globalValue objectForKey:@"objcAdd"];
        XCTAssert(objcAdd.objValue == blk);

        QJSValue *retValue = [context eval:@"var a=objcAdd(2,3);console.log(a);a;"];
        XCTAssert([retValue.objValue isEqual:@(23)]);
    }
    XCTAssert([QJSRuntime numberOfRuntimes] == 0);
}

//- (void)testPerformanceExample {
//    // This is an example of a performance test case.
//    [self measureBlock:^{
//        // Put the code you want to measure the time of here.
//    }];
//}

@end
