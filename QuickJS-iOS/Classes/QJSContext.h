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

typedef id (^dispatch_block_t_0)(void);
typedef id (^dispatch_block_t_1)(id);
typedef id (^dispatch_block_t_2)(id, id);
typedef id (^dispatch_block_t_3)(id, id, id);
typedef id (^dispatch_block_t_4)(id, id, id, id);

@interface QJSValue : NSObject

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

- (id)objValue;

- (QJSValue *)objectForKey:(id)key;
- (void)setObject:(id)value forKey:(id)key;
- (void)removeObjectForKey:(id)key;

- (BOOL)isUndefined;
- (BOOL)isException;
- (BOOL)isFunction;

- (QJSValue *)invoke:(NSObject *)arg, ...;

- (id)asProtocol:(Protocol *)protocol;

@end

@interface QJSContext : NSObject

@property (nonatomic, assign) JSContext *ctx;

- (instancetype)init NS_UNAVAILABLE;
- (instancetype)new NS_UNAVAILABLE;

- (QJSValue *)eval:(NSString *)script;
- (QJSValue *)eval:(NSString *)script filename:(NSString *)filename;
- (QJSValue *)eval:(NSString *)script filename:(NSString *)filename flags:(int)flags;

- (QJSValue *)getGlobalValue;
- (QJSValue *)newObjectValue;

@end

NS_ASSUME_NONNULL_END
