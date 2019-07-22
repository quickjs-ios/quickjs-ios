//
//  QJSContext.h
//  QuickJS-iOS
//
//  Created by Sam Chang on 7/18/19.
//

#import "QJSRuntime.h"
#import "quickjs.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef struct JSMapState JSMapState;

@interface QJSContext : NSObject

@property (nonatomic, assign) JSContext *ctx;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) new NS_UNAVAILABLE;

- (id) eval: (NSString *) script;
- (id) eval: (NSString *) script filename: (NSString *) filename;
- (id) eval: (NSString *) script filename: (NSString *) filename flags: (int) flags;

- (id) getGlobalKey: (id) key;
- (void) setGlobalKey: (id) key value: (id) value;

- (id) getObject: (JSValue) target key: (id) key;
- (void) setObject: (JSValue) target key: (id) key value: (id) value;

- (id) objectFromValue: (JSValue) value;
- (JSValue) valueFromObject: (id) object;

@end

NS_ASSUME_NONNULL_END
