//
//  QJSConfiguration.h
//  QuickJS-iOS
//
//  Created by Sam Chang on 7/18/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class QJSContext, QJSRuntime;

@interface QJSConfiguration : NSObject

- (void)setupContext:(QJSContext *)context;
- (void)setupRuntime:(QJSRuntime *)runtime;

@end

NS_ASSUME_NONNULL_END
