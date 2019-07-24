# QuickJS-iOS

## Project Status
not for production.

## Install XCodeGen

You can ignore this step if `xcodegen` has been installed already.

```
$ brew install xcodegen
```

## Setup Project

```
$ cd project-dir
$ xcodegen
``` 
open the project, select simulator as the target, then press Command+U to run the tests.

## Intergrate your project with cocoapods

1. add pod dependency `pod 'QuickJS-iOS'`
2. add header import `#import <QuickJS-iOS/QuickJS-iOS.h>`

## Samples

Object for inject to javascript

```objective-c
@interface TestObject : NSObject

@end

@implementation TestObject

- (NSArray *)test:(NSNumber *)a :(NSString *)b :(NSNumber *)c {
    NSLog(@"%@ %@ %@", a, b, c);
    return @[@"a", @NO, @(123)];
}

@end
```

Sample for invoke ObjectiveC api from js

```objective-c
// prepare runtime & context
QJSRuntime *runtime = [[QJSRuntime alloc] init];
QJSContext *context = [runtime newContext];

// get global object
QJSValue *globalValue = [context getGlobalValue];
// set global variable
[globalValue setObject:[TestObject new] forKey:@"testval"];
// invoke objc instance api from javascript
[context eval:@"testval.test(1, 'a', false);"]

```

Sample for call javascript function in ObjectiveC

```objective-c
@protocol TestProtocol<NSObject>

- (id)javascriptAddFunc:(id)arg1 :(id)arg2

@end

QJSRuntime *runtime = [[QJSRuntime alloc] init];
QJSContext *context = [runtime newContext];
QJSValue *destObject = [context eval:@"var a = {javascriptAddFunc: function(a, b){return a * 10 + b;}}; a;"];
id<TestProtocol> obj = [destObject asProtocol:@protocol(TestProtocol)];
id retValue = [obj javascriptAddFunc:@(1):@(2)];
```

You can find more samples in file: QuickJS_iOSTest.m