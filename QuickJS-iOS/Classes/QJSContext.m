//
//  QJSContext.m
//  QuickJS-iOS
//
//  Created by Sam Chang on 7/18/19.
//

#import "QJSContext.h"
#import "quickjs-libc.h"

@interface QJSRuntime (Private)

- (void)internalRemoveContext:(QJSContext *)context;

@end

@interface QJSContext ()

@property (nonatomic, strong) QJSRuntime *runtime;

@end

@implementation QJSContext

- (instancetype)initWithRuntime:(QJSRuntime *)runtime {
    self = [super init];
    if (self) {
        self.runtime = runtime;
        self.ctx = JS_NewContext(runtime.rt);
    }
    return self;
}

- (void)dealloc {
    [self.runtime internalRemoveContext:self];
    JS_FreeContext(self.ctx);
}

- (id) eval: (NSString *) script filename: (NSString *) filename flags: (int) flags{
    NSData *scriptData = [script dataUsingEncoding: NSUTF8StringEncoding];
    JSContext *ctx = self.ctx;
    JSValue ret = JS_Eval(ctx, scriptData.bytes, scriptData.length, filename.UTF8String, flags);
    id retObject = nil;
    if (JS_IsException(ret)) {
        js_std_dump_error(ctx);
    } else if (JS_IsString(ret)){
        const char *str = JS_ToCString(ctx, ret);
        retObject = [NSString stringWithCString: str encoding: NSUTF8StringEncoding];
        JS_FreeCString(ctx, str);
    }
    JS_FreeValue(ctx, ret);
    
    return retObject;
}

- (id) eval: (NSString *) script filename: (NSString *) filename{
    return [self eval: script filename: filename flags: 0];
}

- (id) eval: (NSString *) script {
    return [self eval: script filename: @""];
}

@end
