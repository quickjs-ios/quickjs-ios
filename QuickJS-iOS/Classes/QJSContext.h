//
//  QJSContext.h
//  QuickJS-iOS
//
//  Created by Sam Chang on 7/18/19.
//

#import "QJSRuntime.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN
typedef struct JSContext JSContext;

@interface QJSContext : NSObject

@property (nonatomic, assign) JSContext *ctx;

- (instancetype) init NS_UNAVAILABLE;
- (instancetype) new NS_UNAVAILABLE;

- (id) eval: (NSString *) script;
- (id) eval: (NSString *) script filename: (NSString *) filename;
- (id) eval: (NSString *) script filename: (NSString *) filename flags: (int) flags;
@end

NS_ASSUME_NONNULL_END
