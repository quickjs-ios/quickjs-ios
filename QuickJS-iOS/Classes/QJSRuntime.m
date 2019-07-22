//
//  QJSRuntime.m
//  QuickJS-iOS
//
//  Created by Sam Chang on 7/18/19.
//

#import "QJSRuntime.h"

#import "QJSContext.h"
#import "quickjs-libc.h"

@interface QJSContext (Private)

- (instancetype)initWithRuntime:(QJSRuntime *)runtime;

@end

@interface QJSRuntime ()

// weakToWeakObjectsMapTable
@property (nonatomic, strong) NSMapTable<QJSContext *, QJSContext *> *contextMap;
@property (nonatomic, strong) QJSConfiguration *config;

@end

@implementation QJSRuntime

static NSMapTable<QJSRuntime *, QJSRuntime *> *runtimeMap;

+ (void)initialize {
    runtimeMap = [NSMapTable weakToWeakObjectsMapTable];
}

+ (NSUInteger)numberOfRuntimes {
    return [runtimeMap count];
}

+ (instancetype)shared {
    static QJSRuntime *sharedInstance = nil;

    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[QJSRuntime alloc] init];
    });

    return sharedInstance;
}

- (instancetype)init {
    QJSConfiguration *config = [[QJSConfiguration alloc] init];
    return [self initWithConfiguration:config];
}

- (instancetype)initWithConfiguration:(QJSConfiguration *)config {
    self = [super init];
    if (self) {
        self.config = config;
        self.rt = JS_NewRuntime();
        self.contextMap = [NSMapTable weakToWeakObjectsMapTable];
        [runtimeMap setObject:self forKey:self];

        [self.config setupRuntime:self];
    }
    return self;
}

- (void)dealloc {
    [runtimeMap removeObjectForKey:self];
    JS_FreeRuntime(self.rt);
}

- (QJSContext *)newContext {
    QJSContext *context = [[QJSContext alloc] initWithRuntime:self];
    [self.config setupContext:context];
    [self.contextMap setObject:context forKey:context];
    return context;
}

- (NSUInteger)numberOfContexts {
    return [self.contextMap count];
}

- (void)internalRemoveContext:(QJSContext *)context {
    [self.contextMap removeObjectForKey:context];
}

@end
