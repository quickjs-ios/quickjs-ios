//
//  QJSContext.m
//  QuickJS-iOS
//
//  Created by Sam Chang on 7/18/19.
//

#import "QJSContext.h"

#import "quickjs-libc.h"

#import <objc/message.h>
#import <objc/runtime.h>

@interface QJSRuntime (Private)

- (void)internalRemoveContext:(QJSContext *)context;

@end

@interface QJSContext ()

@property (nonatomic, strong) QJSRuntime *runtime;

- (id)getObject:(JSValue)target key:(id)key;
+ (id)getObject:(JSValue)target key:(id)key context:(JSContext *)ctx;

- (void)setObject:(JSValue)target key:(id)key value:(id)value;
+ (void)setObject:(JSValue)target key:(id)key value:(id)value context:(JSContext *)ctx;
+ (void)removeObject:(JSValue)target key:(id)key context:(JSContext *)ctx;

- (id)objectFromValue:(JSValue)value;
+ (id)objectFromValue:(JSValue)value context:(JSContext *)ctx;

- (JSValue)valueFromObject:(id)object;
+ (JSValue)valueFromObject:(id)object context:(JSContext *)ctx;

+ (QJSValue *)getValue:(QJSValue *)target key:(id)key context:(QJSContext *)context;
+ (void)setValue:(QJSValue *)target key:(id)key value:(id)value context:(QJSContext *)context;
+ (void)removeValue:(QJSValue *)target key:(id)key context:(QJSContext *)context;

@end

@interface QJSProxyObject : NSObject

@property (nonatomic, strong) QJSValue *value;
@property (nonatomic, strong) Protocol *protocol;

- (instancetype)initWithProtocol:(Protocol *)protocol value:(QJSValue *)value;

@end

@interface QJSValue ()

@property (nonatomic, assign) JSValue value;
@property (nonatomic, strong) QJSContext *context;

- (instancetype)initWithJSValue:(JSValue)value context:(QJSContext *)context;
- (JSValue)dupValue;

@end

@implementation QJSValue

- (instancetype)initWithJSValue:(JSValue)value context:(QJSContext *)context {
    self = [super init];
    if (self) {
        self.value = value;
        self.context = context;
    }
    return self;
}

- (void)dealloc {
    JS_FreeValue(_context.ctx, _value);
}

- (JSValue)dupValue {
    return JS_DupValue(_context.ctx, _value);
}

- (id)objValue {
    return [QJSContext objectFromValue:_value context:_context.ctx];
}

- (QJSValue *)objectForKey:(id)key {
    if (JS_IsObject(_value)) {
        return [QJSContext getValue:self key:key context:_context];
    } else {
        return nil;
    }
}

- (void)setObject:(id)value forKey:(id)key {
    if (JS_IsObject(_value)) {
        [QJSContext setValue:self key:key value:value context:_context];
    }
}

- (void)removeObjectForKey:(id)key {
    if (JS_IsObject(_value)) {
        [QJSContext removeValue:self key:key context:_context];
    }
}

- (BOOL)isUndefined {
    return JS_IsUndefined(_value);
}

- (BOOL)isFunction {
    return JS_IsFunction(_context.ctx, _value);
}

- (BOOL)isException {
    return JS_IsException(_value);
}

- (QJSValue *)invoke:(NSObject *)arg, ... {
    if (![self isFunction]) {
        return nil;
    }

    NSMutableArray *args = [[NSMutableArray alloc] init];
    [args addObject:arg];

    va_list cols;
    va_start(cols, arg);
    while ((arg = va_arg(cols, NSObject *)) != nil) {
        [args addObject:arg];
    }
    va_end(cols);

    JSContext *ctx = _context.ctx;
    JSValue *valueArgs = js_malloc(ctx, args.count * sizeof(JSValue));
    for (int i = 0; i < args.count; i++) {
        valueArgs[i] = [QJSContext valueFromObject:[args objectAtIndex:i] context:ctx];
    }

    JSValue func = JS_DupValue(ctx, _value);
    JSValue ret = JS_Call(ctx, func, JS_UNDEFINED, (int)args.count, valueArgs);
    JS_FreeValue(ctx, func);
    js_free(ctx, valueArgs);

    return [[QJSValue alloc] initWithJSValue:ret context:_context];
}

- (id)asProtocol:(Protocol *)protocol {
    if (!JS_IsObject(_value)) {
        @throw [NSException exceptionWithName:@"QJSError"
                                       reason:[NSString stringWithFormat:@"not object!"]
                                     userInfo:nil];
    }
    return [[QJSProxyObject alloc] initWithProtocol:protocol value:self];
}

@end

@implementation QJSProxyObject

- (instancetype)initWithProtocol:(Protocol *)protocol value:(QJSValue *)value {
    self = [super init];
    if (self) {
        self.protocol = protocol;
        self.value = value;
    }
    return self;
}

- (NSMethodSignature *)methodSignatureForSelector:(SEL)sel {
    struct objc_method_description md = protocol_getMethodDescription(_protocol, sel, YES, YES);
    if (md.types != NULL) {
        return [NSMethodSignature signatureWithObjCTypes:md.types];
    }
    return nil;
}

- (void)forwardInvocation:(NSInvocation *)invocation {
    SEL sel = [invocation selector];
    if (sel != nil) {
        NSString *selStr = NSStringFromSelector(sel);
        while ([selStr length] > 0 && [selStr characterAtIndex:[selStr length] - 1] == ':') {
            selStr = [selStr substringToIndex:[selStr length] - 1];
        }
        // selector is convert from func:arg1:arg2::: to func_arg1_arg2 in javascript.
        selStr = [selStr stringByReplacingOccurrencesOfString:@":" withString:@"_"];

        QJSValue *funcValue = [_value objectForKey:selStr];
        if (!funcValue) {
            @throw [NSException exceptionWithName:@"QJSError"
                                           reason:[NSString stringWithFormat:@"method (%@) not found!", selStr]
                                         userInfo:nil];
        }

        NSMethodSignature *ms = [invocation methodSignature];
        JSContext *ctx = _value.context.ctx;
        JSValue *valueArgs = js_malloc(ctx, ([ms numberOfArguments] - 2) * sizeof(JSValue));
        for (int i = 2; i < [ms numberOfArguments]; i++) {
            void *argValue = nil;
            [invocation getArgument:&argValue atIndex:i];
            if (argValue) {
                valueArgs[i - 2] = [QJSContext valueFromObject:(__bridge id)argValue context:ctx];
            } else {
                valueArgs[i - 2] = JS_NULL;
            }
        }
        JSValue ret = JS_Call(ctx, funcValue.value, JS_UNDEFINED, (int)[ms numberOfArguments] - 2, valueArgs);

        if (*[ms methodReturnType] == '@') {
            void *retValue = (__bridge void *)[QJSContext objectFromValue:ret context:ctx];
            [invocation setReturnValue:&retValue];
        }

        js_free(ctx, valueArgs);
    }
}

@end

@implementation QJSContext

static JSClassID js_objc_class_id;

static Class boolClass;
static Class blockClass;

JSValue JS_GetIterator(JSContext *ctx, JSValueConst obj, BOOL is_async);
JSValue JS_IteratorNext(JSContext *ctx, JSValueConst enum_obj, JSValueConst method, int argc, JSValueConst *argv,
                        BOOL *pdone);
int JS_IteratorClose(JSContext *ctx, JSValueConst enum_obj, BOOL is_exception_pending);

int JS_GetOwnPropertyNames(JSContext *ctx, JSPropertyEnum **ptab, uint32_t *plen, JSObject *p, int flags);

enum {
    JS_ATOM_NULL,
#define DEF(name, str) JS_ATOM_##name,
#include "quickjs-atom.h"
#undef DEF
    JS_ATOM_END,
};

#define JS_GPN_SYMBOL_MASK (1 << 0)
#define JS_GPN_STRING_MASK (1 << 1)
/* only include the enumerable properties */
#define JS_GPN_ENUM_ONLY (1 << 2)
/* set theJSPropertyEnum.is_enumerable field */
#define JS_GPN_SET_ENUM (1 << 3)

extern int JS_CLASS_MAP_export;

typedef struct {
    id value;
} id_wrap;

static void js_objc_finalizer(JSRuntime *rt, JSValue val) {
    NSObject *object = (__bridge_transfer NSObject *)JS_GetOpaque(val, js_objc_class_id);
#ifdef DEBUG
    NSLog(@"js_objc_finalizer %@", object);
    // object released after return.
#endif
}

static void js_objc_mark(JSRuntime *rt, JSValueConst val, JS_MarkFunc *mark_func) {
    NSObject *object = (__bridge NSObject *)JS_GetOpaque(val, js_objc_class_id);
#ifdef DEBUG
    NSLog(@"js_objc_mark %@", object);
#endif
}

static JSValue js_objc_call(JSContext *ctx, JSValueConst func_obj, JSValueConst this_val, int argc,
                            JSValueConst *argv) {
    NSObject *object = (__bridge NSObject *)JS_GetOpaque(func_obj, js_objc_class_id);
    if ([object isKindOfClass:blockClass]) {
        id retObject = nil;
        switch (argc) {
            case 0:
                retObject = ((dispatch_block_t_0)object)();
                break;
            case 1:
                retObject = ((dispatch_block_t_1)object)([QJSContext objectFromValue:argv[0] context:ctx]);
                break;
            case 2:
                retObject = ((dispatch_block_t_2)object)([QJSContext objectFromValue:argv[0] context:ctx],
                                                         [QJSContext objectFromValue:argv[1] context:ctx]);
                break;
            case 3:
                retObject = ((dispatch_block_t_3)object)([QJSContext objectFromValue:argv[0] context:ctx],
                                                         [QJSContext objectFromValue:argv[1] context:ctx],
                                                         [QJSContext objectFromValue:argv[2] context:ctx]);
                break;
            case 4:
                retObject = ((dispatch_block_t_4)object)(
                    [QJSContext objectFromValue:argv[0] context:ctx], [QJSContext objectFromValue:argv[1] context:ctx],
                    [QJSContext objectFromValue:argv[2] context:ctx], [QJSContext objectFromValue:argv[3] context:ctx]);
                break;
            default:
                break;
        }

        if (retObject) {
            return [QJSContext valueFromObject:retObject context:ctx];
        }
    }
    return JS_UNDEFINED;
}

static JSClassDef js_objc_class = {
    "ObjcBridge",
    .finalizer = js_objc_finalizer,
    .gc_mark = js_objc_mark,
    .call = js_objc_call,
};

+ (void)initialize {
    if (self == [QJSContext class]) {
        JS_NewClassID(&js_objc_class_id);
        boolClass = @YES.class;
        blockClass = NSClassFromString(@"NSBlock");
    }
}

static JSValue js_objc_invoke(JSContext *ctx, JSValueConst val, int argc, JSValueConst *argv) {
    NSObject *object = (__bridge NSObject *)JS_GetOpaque(val, js_objc_class_id);
    if (!object)
        return JS_EXCEPTION;

    NSString *method = [QJSContext objectFromValue:argv[0] context:ctx];

    NSInteger toFillCount = argc - 1;
    while (toFillCount-- > 0) {
        method = [method stringByAppendingString:@":"];
    }

    SEL selector = NSSelectorFromString(method);
    NSMethodSignature *signature = [object methodSignatureForSelector:selector];
    if (!signature) {
        JS_ThrowTypeError(ctx, "method (%s) not found!", method.UTF8String);
        return JS_EXCEPTION;
    }

    NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:signature];
    [invocation setSelector:selector];
    [invocation setTarget:object];

    for (int i = 1; i < argc; i++) {
        NSObject *arg = [QJSContext objectFromValue:argv[i] context:ctx];
        [invocation setArgument:&arg atIndex:2 + i - 1];
    }

    [invocation invoke];

    // support return object only.
    if (*[signature methodReturnType] == '@') {
        void *retValue = nil;
        [invocation getReturnValue:&retValue];
        if (retValue) {
            return [QJSContext valueFromObject:(__bridge id)retValue context:ctx];
        }
    }

    return JS_UNDEFINED;
}

static const JSCFunctionListEntry js_objc_proto_funcs[] = {JS_CFUNC_DEF("invoke", 0, js_objc_invoke)};

#define countof(x) (sizeof(x) / sizeof((x)[0]))

- (instancetype)initWithRuntime:(QJSRuntime *)runtime {
    self = [super init];
    if (self) {
        self.runtime = runtime;
        self.ctx = JS_NewContext(runtime.rt);

        JS_NewClass(runtime.rt, js_objc_class_id, &js_objc_class);

        JSContext *ctx = self.ctx;
        JSValue proto = JS_NewObject(ctx);
        JS_SetPropertyFunctionList(ctx, proto, js_objc_proto_funcs, countof(js_objc_proto_funcs));
        JS_SetClassProto(ctx, js_objc_class_id, proto);
    }
    return self;
}

- (void)dealloc {
    [self.runtime internalRemoveContext:self];
    JS_FreeContext(self.ctx);
}

+ (id)objectFromValue:(JSValue)value context:(JSContext *)ctx {
    id returnObject = nil;
    int tag = JS_VALUE_GET_TAG(value);
    switch (tag) {
        case JS_TAG_STRING: {
            const char *str = JS_ToCString(ctx, value);
            returnObject = [NSString stringWithCString:str encoding:NSUTF8StringEncoding];
            JS_FreeCString(ctx, str);
        } break;
        case JS_TAG_BOOL:
            returnObject = JS_ToBool(ctx, value) ? @YES : @NO;
            break;
        case JS_TAG_INT: {
            int64_t val = 0;
            if (JS_ToInt64(ctx, &val, value) == 0) {
                returnObject = @(val);
            }
        } break;
        case JS_TAG_FLOAT64: {
            double val = 0;
            if (JS_ToFloat64(ctx, &val, value) == 0) {
                returnObject = @(val);
            }
        } break;
        case JS_TAG_OBJECT: {
            if (JS_IsArray(ctx, value)) {
                NSMutableArray *array = @[].mutableCopy;
                JSValue sp[2] = {0};
                sp[0] = JS_GetIterator(ctx, value, 0);
                if (JS_IsException(sp[0])) {
                    js_std_dump_error(ctx);
                    JS_FreeValue(ctx, sp[0]);
                    return nil;
                }

                sp[1] = JS_GetProperty(ctx, sp[0], JS_ATOM_next);

                if (JS_IsException(sp[1])) {
                    js_std_dump_error(ctx);
                    JS_FreeValue(ctx, sp[0]);
                    return nil;
                }

                for (;;) {
                    BOOL done;
                    JSValue value = JS_IteratorNext(ctx, sp[0], sp[1], 0, NULL, &done);
                    if (JS_IsException(value))
                        goto exception;
                    if (done) {
                        JS_FreeValue(ctx, value);
                        break;
                    }
                    [array addObject:[QJSContext objectFromValue:value context:ctx]];
                    JS_FreeValue(ctx, value);
                }

            exception:
                if (JS_IsObject(sp[0])) {
                    JS_IteratorClose(ctx, sp[0], TRUE);
                }

                JS_FreeValue(ctx, sp[1]);
                JS_FreeValue(ctx, sp[0]);

                returnObject = array;
            } else if (JS_IsObject(value)) {
                returnObject = (__bridge NSObject *)JS_GetOpaque(value, js_objc_class_id);
                if (returnObject) {
                    break;
                }
                NSMutableDictionary *dic = @{}.mutableCopy;
                JSMapState *s = JS_GetOpaque2(ctx, value, JS_CLASS_MAP_export);
                if (!s) {
                    JSPropertyEnum *tab_atom;
                    uint32_t tab_atom_count;
                    JSObject *p = JS_VALUE_GET_OBJ(value);

                    if (JS_GetOwnPropertyNames(ctx, &tab_atom, &tab_atom_count, p,
                                               JS_GPN_STRING_MASK | JS_GPN_SYMBOL_MASK | JS_GPN_ENUM_ONLY))
                        break;

                    for (int i = 0; i < tab_atom_count; i++) {
                        JSAtom atom = tab_atom[i].atom;
                        JSValue val = JS_GetProperty(ctx, value, atom);
                        if (JS_IsException(val))
                            break;
                        JSValue key = JS_AtomToValue(ctx, atom);
                        dic[[QJSContext objectFromValue:key context:ctx]] = [QJSContext objectFromValue:val
                                                                                                context:ctx];
                        JS_FreeValue(ctx, key);
                        JS_FreeValue(ctx, val);
                    }

                    for (int i = 0; i < tab_atom_count; i++)
                        JS_FreeAtom(ctx, tab_atom[i].atom);
                    js_free(ctx, tab_atom);
                }

                returnObject = dic;
            }
        } break;
        default:
            break;
    }

    return returnObject;
}

- (id)objectFromValue:(JSValue)value {
    return [QJSContext objectFromValue:value context:self.ctx];
}

+ (JSValue)valueFromObject:(id)object context:(JSContext *)ctx {
    JSValue objectVal = JS_NULL;
    if ([object isKindOfClass:[QJSValue class]]) {
        objectVal = ((QJSValue *)object).dupValue;
    } else if ([object isKindOfClass:[NSString class]]) {
        objectVal = JS_NewString(ctx, ((NSString *)object).UTF8String);
    } else if ([object isKindOfClass:[NSNumber class]]) {
        NSNumber *numberObject = (NSNumber *)object;
        if (numberObject.class == boolClass) {
            objectVal = JS_NewBool(ctx, numberObject.boolValue);
        } else {
            CFNumberType numberType = CFNumberGetType((CFNumberRef)numberObject);
            switch (numberType) {
                case kCFNumberFloatType:
                case kCFNumberFloat64Type:
                case kCFNumberCGFloatType:
                case kCFNumberDoubleType:
                    objectVal = JS_NewFloat64(ctx, numberObject.doubleValue);
                    break;
                case kCFNumberSInt8Type:
                case kCFNumberSInt16Type:
                case kCFNumberSInt32Type:
                    objectVal = JS_NewInt32(ctx, numberObject.intValue);
                    break;
                default:
                    objectVal = JS_NewInt64(ctx, numberObject.longLongValue);
                    break;
            }
        }
    } else if ([object isKindOfClass:[NSArray class]]) {
        NSArray *list = (NSArray *)object;
        objectVal = JS_NewArray(ctx);
        for (int i = 0; i < [list count]; i++) {
            JSValue valueVal = [QJSContext valueFromObject:list[i] context:ctx];
            JS_SetPropertyInt64(ctx, objectVal, i, valueVal);
        }
    } else if ([object isKindOfClass:[NSDictionary class]]) {
        NSDictionary *dic = (NSDictionary *)object;

        objectVal = JS_NewObject(ctx);
        [dic enumerateKeysAndObjectsUsingBlock:^(id _Nonnull key, id _Nonnull obj, BOOL *_Nonnull stop) {
            [QJSContext setObject:objectVal key:key value:obj context:ctx];
        }];
    } else {
        // raw object
        objectVal = JS_NewObjectClass(ctx, js_objc_class_id);
        if (JS_IsException(objectVal))
            return objectVal;

        JS_SetOpaque(objectVal, (__bridge_retained void *)object);
    }

    return objectVal;
}

- (JSValue)valueFromObject:(id)object {
    return [QJSContext valueFromObject:object context:self.ctx];
}

- (QJSValue *)eval:(NSString *)script filename:(NSString *)filename flags:(int)flags {
    JSContext *ctx = self.ctx;
    JSValue ret = JS_Eval(ctx, script.UTF8String, strlen(script.UTF8String), filename.UTF8String, flags);
    if (JS_IsException(ret)) {
        js_std_dump_error(ctx);
    }

    return [[QJSValue alloc] initWithJSValue:ret context:self];
}

- (QJSValue *)eval:(NSString *)script filename:(NSString *)filename {
    return [self eval:script filename:filename flags:0];
}

- (QJSValue *)eval:(NSString *)script {
    return [self eval:script filename:@""];
}

+ (void)setObject:(JSValue)target key:(id)key value:(id)value context:(JSContext *)ctx {
    JSValue valueVal = [QJSContext valueFromObject:value context:ctx];

    if ([key isKindOfClass:[NSString class]]) {
        JS_SetPropertyStr(ctx, target, ((NSString *)key).UTF8String, valueVal);
    } else if ([key isKindOfClass:[NSNumber class]]) {
        JS_SetPropertyInt64(ctx, target, ((NSNumber *)key).longLongValue, valueVal);
    }
}

+ (void)removeObject:(JSValue)target key:(id)key context:(JSContext *)ctx {
    if ([key isKindOfClass:[NSString class]]) {
        JS_SetPropertyStr(ctx, target, ((NSString *)key).UTF8String, JS_UNDEFINED);
    } else if ([key isKindOfClass:[NSNumber class]]) {
        JS_SetPropertyInt64(ctx, target, ((NSNumber *)key).longLongValue, JS_UNDEFINED);
    }
}

- (void)setObject:(JSValue)target key:(id)key value:(id)value {
    [QJSContext setObject:target key:key value:value context:self.ctx];
}

+ (QJSValue *)getValue:(QJSValue *)target key:(id)key context:(QJSContext *)context {
    if ([key isKindOfClass:[NSString class]]) {
        JSValue value = JS_GetPropertyStr(context.ctx, target.value, ((NSString *)key).UTF8String);
        return [[QJSValue alloc] initWithJSValue:value context:context];
    }

    return nil;
}

- (QJSValue *)getGlobalValue {
    return [[QJSValue alloc] initWithJSValue:JS_GetGlobalObject(_ctx) context:self];
}

+ (id)getObject:(JSValue)target key:(id)key context:(JSContext *)ctx {
    id returnObject = nil;

    if ([key isKindOfClass:[NSString class]]) {
        JSValue value = JS_GetPropertyStr(ctx, target, ((NSString *)key).UTF8String);
        returnObject = [QJSContext objectFromValue:value context:ctx];
        JS_FreeValue(ctx, value);
    }

    return returnObject;
}

+ (void)setValue:(QJSValue *)target key:(id)key value:(id)value context:(QJSContext *)context {
    [QJSContext setObject:target.value key:key value:value context:context.ctx];
}

+ (void)removeValue:(QJSValue *)target key:(id)key context:(QJSContext *)context {
    [QJSContext removeObject:target.value key:key context:context.ctx];
}

- (id)getObject:(JSValue)target key:(id)key {
    return [QJSContext getObject:target key:key context:self.ctx];
}

- (QJSValue *)newObjectValue {
    return [[QJSValue alloc] initWithJSValue:JS_NewObject(_ctx) context:self];
}

@end
