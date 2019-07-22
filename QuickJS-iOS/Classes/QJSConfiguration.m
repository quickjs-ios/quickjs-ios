//
//  QJSConfiguration.m
//  QuickJS-iOS
//
//  Created by Sam Chang on 7/18/19.
//

#import "QJSConfiguration.h"

#import "QJSContext.h"
#import "quickjs-libc.h"

@implementation QJSConfiguration

- (void)setupContext:(QJSContext *)context {
    JSContext *ctx = context.ctx;

    js_std_add_helpers(ctx, 0, NULL);
}

- (void)setupRuntime:(QJSRuntime *)runtime {
}

@end
