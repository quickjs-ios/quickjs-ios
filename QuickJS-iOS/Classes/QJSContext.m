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

static JSClassID js_objc_class_id;

static Class boolClass;
static Class blockClass;

+ (void)initialize
{
    if (self == [QJSContext class]) {
        JS_NewClassID(&js_objc_class_id);
        boolClass = @YES.class;
        blockClass = NSClassFromString(@"NSBlock");
    }
}

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

- (id) objectFromValue: (JSValue) value {
    JSContext *ctx = self.ctx;

    id returnObject = nil;

    if (JS_IsString(value)) {
        const char *str = JS_ToCString(ctx, value);
        returnObject = [NSString stringWithCString: str encoding: NSUTF8StringEncoding];
        JS_FreeCString(ctx, str);
    } else if (JS_IsBool(value)) {
        returnObject = JS_ToBool(ctx, value) ? @YES : @NO;
    } else if (JS_IsInteger(value)) {
        int64_t val = 0;
        if(JS_ToInt64(ctx, &val, value) == 0){
            returnObject = @(val);
        }
    } else if (JS_IsNumber(value)) {
        double val = 0;
        if (JS_ToFloat64(ctx, &val, value) == 0) {
            returnObject = @(val);
        }
    } else if (JS_IsArray(ctx, value)) {
        NSMutableArray *array = @[].mutableCopy;
        uint32_t i = 0;
        while (YES) {
            JSValue item = JS_GetPropertyUint32(ctx, value, i++);
            if (!JS_IsUndefined(item)) {
                id object = [self objectFromValue: item];
                [array addObject: object];
            } else {
                break;
            }
        }
        returnObject = array;
    } else if(JS_IsObject(value)) {
        NSMutableDictionary *dic = @{}.mutableCopy;
        //TODO
        returnObject = dic;
    }
    
    return returnObject;
}

- (JSValue) valueFromObject: (id) object {
    JSContext *ctx = self.ctx;

    JSValue objectVal = JS_NULL;
    if ([object isKindOfClass: [NSString class]]) {
        objectVal = JS_NewString(ctx, ((NSString *) object).UTF8String);
    } else if([object isKindOfClass: [NSNumber class]]) {
        NSNumber *numberObject = (NSNumber *) object;
        if (numberObject.class == boolClass) {
            objectVal = JS_NewBool(ctx, numberObject.boolValue);
        } else {
            CFNumberType numberType = CFNumberGetType((CFNumberRef) numberObject);
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
    } else if ([object isKindOfClass: [NSArray class]]) {
        NSArray *list = (NSArray *) object;
        objectVal = JS_NewArray(ctx);
        for(int i = 0; i < [list count]; i++) {
            JSValue valueVal = [self valueFromObject: list[i]];
            JS_SetPropertyInt64(ctx, objectVal, i, valueVal);
        }
    } else if ([object isKindOfClass: [NSDictionary class]]) {
        NSDictionary *dic = (NSDictionary *) object;

        objectVal = JS_NewObject(ctx);
        [dic enumerateKeysAndObjectsUsingBlock:^(id  _Nonnull key, id  _Nonnull obj, BOOL * _Nonnull stop) {
            [self setObject: objectVal key: key value: obj];
        }];
    } else if ([object isKindOfClass: blockClass]) {
        
    } else {
        // raw object
    }

    return objectVal;
}

- (id) eval: (NSString *) script filename: (NSString *) filename flags: (int) flags{
    JSContext *ctx = self.ctx;
    JSValue ret = JS_Eval(ctx, script.UTF8String, strlen(script.UTF8String), filename.UTF8String, flags);
    id retObject = nil;
    if (JS_IsException(ret)) {
        js_std_dump_error(ctx);
    } else {
        retObject = [self objectFromValue: ret];
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

- (void) setObject: (JSValue) target key: (id) key value: (id) value {
    JSContext *ctx = self.ctx;
    
    JSValue valueVal = [self valueFromObject: value];
    
    if ([key isKindOfClass: [NSString class]]) {
        JS_SetPropertyStr(ctx, target, ((NSString *)key).UTF8String, valueVal);
    } else if ([key isKindOfClass: [NSNumber class]]) {
        JS_SetPropertyInt64(ctx, target, ((NSNumber *)key).longLongValue, valueVal);
    }
}

- (id) getObject: (JSValue) target key: (id) key {
    JSContext *ctx = self.ctx;
    
    JSValue globalObject = JS_GetGlobalObject(ctx);
    id returnObject = nil;
    
    if ([key isKindOfClass: [NSString class]]) {
        JSValue value = JS_GetPropertyStr(ctx, globalObject, ((NSString *)key).UTF8String);
        returnObject = [self objectFromValue: value];
        JS_FreeValue(ctx, value);
    }
    
    JS_FreeValue(ctx, globalObject);
    
    return returnObject;

}

- (id) getGlobalKey: (id) key {
    JSContext *ctx = self.ctx;
    
    JSValue globalObject = JS_GetGlobalObject(ctx);
    id returnObject = [self getObject: globalObject key: key];
    JS_FreeValue(ctx, globalObject);
    
    return returnObject;
}

- (void) setGlobalKey: (id) key value: (id) value {
    JSContext *ctx = self.ctx;
    
    JSValue globalObject = JS_GetGlobalObject(ctx);
    [self setObject: globalObject key: key value: value];
    JS_FreeValue(ctx, globalObject);
}


@end
