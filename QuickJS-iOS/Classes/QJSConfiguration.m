//
//  QJSConfiguration.m
//  QuickJS-iOS
//
//  Created by Sam Chang on 7/18/19.
//

#import "QJSConfiguration.h"

#import "QJSContext.h"
#import "quickjs-libc.h"

@interface QJSFetch : NSObject

@property (nonatomic, strong) NSURLSessionTask *task;
@property (nonatomic, strong) QJSValue *resolve;
@property (nonatomic, strong) QJSValue *reject;

@end

@implementation QJSFetch

@end

@interface QJSConfiguration ()

@property (nonatomic, strong) dispatch_queue_t queue;

@end

@interface QJSContext (Private)

@property (nonatomic, strong) dispatch_source_t timer;

@end

@implementation QJSConfiguration

JSValue qjs_new_promise_capability(JSContext *ctx, JSValue *resolving_funcs, JSValueConst ctor);

static int eval_buf(JSContext *ctx, const void *buf, int buf_len, const char *filename, int eval_flags) {
    JSValue val;
    int ret;

    val = JS_Eval(ctx, buf, buf_len, filename, eval_flags);
    if (JS_IsException(val)) {
        js_std_dump_error(ctx);
        ret = -1;
    } else {
        ret = 0;
    }
    JS_FreeValue(ctx, val);
    return ret;
}

static JSValue js_print(JSContext *ctx, JSValueConst this_val, int argc, JSValueConst *argv) {
    NSMutableString *buf = [NSMutableString string];

    for (int i = 0; i < argc; i++) {
        if (i > 0) {
            [buf appendString:@"\t"];
        }

        const char *str = JS_ToCString(ctx, argv[i]);
        if (!str)
            return JS_EXCEPTION;
        [buf appendFormat:@"%s", str];
        JS_FreeCString(ctx, str);
    }
    NSLog(@"[LOG] %@", buf);
    return JS_UNDEFINED;
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.queue = dispatch_queue_create("runtime queue", NULL);
    }
    return self;
}

- (void)setupContext:(QJSContext *)context2 {
    __weak QJSContext *context = context2;

    JSContext *ctx = context.ctx;

    js_std_add_helpers(ctx, 0, NULL);
    js_init_module_std(ctx, "std");
    js_init_module_os(ctx, "os");

    const char *str = "import * as std from 'std';\n"
                      "import * as os from 'os';\n"
                      "std.global.std = std;\n"
                      "std.global.os = os;\n";
    eval_buf(ctx, str, strlen(str), "<input>", JS_EVAL_TYPE_MODULE);

    QJSValue *globalValue = [context getGlobalValue];

    QJSValue *consoleValue = [globalValue objectForKey:@"console"];
    JSValue logFunc = JS_NewCFunction(ctx, js_print, "log", 1);
    [consoleValue setObject:[[QJSValue alloc] initWithJSValue:logFunc context:context] forKey:@"log"];

    dispatch_block_t_2 fetch = ^id(NSString *url, NSDictionary *dic) {
        QJSFetch *fetchObject = [QJSFetch new];
        JSValue resolving_funcs[2] = {0};
        JSValue promise = qjs_new_promise_capability(ctx, resolving_funcs, JS_UNDEFINED);
        fetchObject.resolve = [[QJSValue alloc] initWithJSValue:resolving_funcs[0] context:context];
        fetchObject.reject = [[QJSValue alloc] initWithJSValue:resolving_funcs[1] context:context];

        NSMutableURLRequest *req = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:url]];

        fetchObject.task = [[NSURLSession sharedSession] dataTaskWithRequest: req completionHandler:^(NSData * data, NSURLResponse *response, NSError *error) {
            if (!error) {
                NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse *)response;
                NSDictionary *dic =
                    @{@"ok": httpResponse.statusCode <= 299 && httpResponse.statusCode >= 200 ? @(YES) : @(NO),
                      @"headers": httpResponse.allHeaderFields,
                      @"status": @(httpResponse.statusCode),
                      @"url": httpResponse.URL.absoluteString,
                      @"json": ^id(){
                          return [NSJSONSerialization JSONObjectWithData:data
                                                                 options:NSJSONReadingMutableLeaves
                                                                   error:nil];
            }
            , @"text" : ^id() {
                NSStringEncoding encoding;
                if (httpResponse.textEncodingName) {
                    CFStringRef cfEncoding = (__bridge CFStringRef)httpResponse.textEncodingName;
                    encoding =
                        CFStringConvertEncodingToNSStringEncoding(CFStringConvertIANACharSetNameToEncoding(cfEncoding));

                } else {
                    encoding = NSUTF8StringEncoding;
                }

                return [[NSString alloc] initWithData:data encoding:encoding];
            }
                                             };
                [fetchObject.resolve invoke: dic, nil];
    } else {
        [fetchObject.reject invoke:error.localizedDescription, nil];
    }

    fetchObject.task = nil;
    fetchObject.reject = nil;
    fetchObject.resolve = nil;
}];
[fetchObject.task resume];
return [[QJSValue alloc] initWithJSValue:promise context:context];
}
;
[globalValue setObject:fetch forKey:@"fetch"];

context.timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_main_queue());
dispatch_source_set_timer(context.timer, DISPATCH_TIME_NOW, 0.01 * NSEC_PER_SEC, 0 * NSEC_PER_SEC);
__weak QJSContext *weakContext = context;
dispatch_source_set_event_handler(context.timer, ^{
    js_std_loop(weakContext.ctx);
});
dispatch_resume(context.timer);
}

- (void)setupRuntime:(QJSRuntime *)runtime {
    JS_SetModuleLoaderFunc(runtime.rt, NULL, js_module_loader, NULL);
}

@end
