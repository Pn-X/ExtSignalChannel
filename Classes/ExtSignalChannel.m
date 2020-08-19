//
//  ExtSignalChannel.m
//  Pods-Example
//
//  Created by hang_pan on 2020/8/19.
//

#import "ExtSignalChannel.h"
#import <pthread.h>
#import <objc/runtime.h>

#define Lock() autoreleasepool{}pthread_mutex_lock(&(self->pthread_mutex))
#define Unlock() autoreleasepool{}pthread_mutex_unlock(&(self->pthread_mutex))

@interface ExtSignal ()

@property (nonatomic, strong, readwrite) ExtSignalChannel *channel;

@property (nonatomic, copy, readwrite) NSString *name;

@property (nonatomic, strong, readwrite) id params;

@end

@implementation ExtSignal


@end

@interface ExtSignalChannelContext : NSObject

@property (nonatomic, copy) NSString *signalName;

@property (nonatomic, weak) id object;

@property (nonatomic, strong) id objectKey;

@property (nonatomic, assign) SEL selector;

@property (nonatomic, strong) ExtSignalChannelHandler handler;

@end

@implementation ExtSignalChannelContext

@end

@implementation NSObject (ExtSignalChannel)

- (ExtSignalChannel *)ext_signalChannel {
    ExtSignalChannel *channel = objc_getAssociatedObject(self, "ext_signalChannel");
    if (!channel) {
        channel = [ExtSignalChannel new];
        objc_setAssociatedObject(self, "ext_signalChannel", channel, OBJC_ASSOCIATION_RETAIN);
    }
    return channel;
}

@end

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

@interface ExtSignalChannel () {
    @public pthread_mutex_t pthread_mutex;
}

@property (nonatomic, assign) BOOL isSharedObject;
@property (nonatomic, strong) NSMutableDictionary *keyContextMap;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *>*signalKeysMap;
@property (nonatomic, strong) NSMutableDictionary <NSString *, NSMutableArray *>*objectKeysMap;

@end

@implementation ExtSignalChannel

+ (instancetype)singleton {
    static ExtSignalChannel *channel = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        channel = [ExtSignalChannel new];
        channel.isSharedObject = YES;
        channel.name = @"__singleton__";
        [[NSNotificationCenter defaultCenter] addObserver:channel selector:@selector(handleNotification:) name:nil object:nil];
    });
    return channel;
}

- (void)handleNotification:(NSNotification *)noti {
    [self forwardSignalName:noti.name params:noti.object];
}

- (instancetype)init {
    self = [super init];
    if (self) {
        self.isSharedObject = NO;
        self.signalKeysMap = [NSMutableDictionary dictionary];
        self.keyContextMap = [NSMutableDictionary dictionary];
        self.objectKeysMap = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)sendSignalName:(NSString *)signalName {
    [self sendSignalName:signalName params:nil];
}

- (void)sendSignalName:(NSString *)signalName params:(nullable id)params {
    assert(signalName != nil);
    if (self.isSharedObject) {
        [[NSNotificationCenter defaultCenter] postNotificationName:signalName object:params];
    } else {
        [self forwardSignalName:signalName params:params];
    }
}

- (void)addSubscriber:(id)subscriber forSignalName:(NSString *)signalName withSelector:(SEL)selector {
    assert(signalName != nil);
    NSString *key = [NSString stringWithFormat:@"%@-%p", signalName, subscriber];
    @Lock();
    ExtSignalChannelContext *oldCtx = self.keyContextMap[key];
    if (oldCtx) {
        if (oldCtx.selector == selector) {
            @Unlock();
            return;
        }
    }
    ExtSignalChannelContext *newCtx = [ExtSignalChannelContext new];
    newCtx.object = subscriber;
    newCtx.objectKey = [NSString stringWithFormat:@"%p", newCtx.object];
    newCtx.selector = selector;
    newCtx.signalName = signalName;
    self.keyContextMap[key] = newCtx;
    if (self.signalKeysMap[signalName] == nil) {
        self.signalKeysMap[signalName] = [NSMutableArray array];
    }
    [self.signalKeysMap[signalName] addObject:key];
    if (self.objectKeysMap[newCtx.objectKey] == nil) {
        self.objectKeysMap[newCtx.objectKey] = [NSMutableArray array];
    }
    [self.objectKeysMap[newCtx.objectKey] addObject:key];
    @Unlock();
}

- (void)addSubscriber:(id)subscriber forSignalName:(NSString *)signalName withHandler:(ExtSignalChannelHandler)handler {
    assert(signalName != nil);
    NSString *key = [NSString stringWithFormat:@"%@-%p", signalName, subscriber];
    @Lock();
    ExtSignalChannelContext *oldCtx = self.keyContextMap[key];
    if (oldCtx) {
        if (oldCtx.handler == handler) {
            @Unlock();
            return;
        }
    }
    ExtSignalChannelContext *newCtx = [ExtSignalChannelContext new];
    newCtx.object = subscriber;
    newCtx.objectKey = [NSString stringWithFormat:@"%p", newCtx.object];
    newCtx.handler = handler;
    newCtx.signalName = signalName;
    self.keyContextMap[key] = newCtx;
    if (self.signalKeysMap[signalName] == nil) {
        self.signalKeysMap[signalName] = [NSMutableArray array];
    }
    [self.signalKeysMap[signalName] addObject:key];
    if (self.objectKeysMap[newCtx.objectKey] == nil) {
        self.objectKeysMap[newCtx.objectKey] = [NSMutableArray array];
    }
    [self.objectKeysMap[newCtx.objectKey] addObject:key];
    @Unlock();
}


- (void)removeSubscriber:(id)subscriber forSignalName:(NSString *)signalName {
    assert(signalName != nil);
    NSString *key = [NSString stringWithFormat:@"%@-%p", signalName, subscriber];
    NSString *objectKey = [NSString stringWithFormat:@"%p", subscriber];
    @Lock();
    if (self.keyContextMap[key]) {
        self.keyContextMap[key] = nil;
        [self.signalKeysMap[signalName] removeObject:key];
        [self.objectKeysMap[objectKey] removeObject:key];
    }
    @Unlock();
}

- (void)removeSubscriber:(id)subscriber {
    NSString *objectKey = [NSString stringWithFormat:@"%p", subscriber];
    @Lock();
    NSArray *array = self.objectKeysMap[objectKey];
    for (NSString *key in array) {
        ExtSignalChannelContext *context = self.keyContextMap[key];
        [self.signalKeysMap[context.signalName] removeObject:key];
        self.keyContextMap[key] = nil;
    }
    self.objectKeysMap[objectKey] = nil;
    @Unlock();
}

- (void)removeAllSubscriberForSignalName:(NSString *)signalName {
    assert(signalName != nil);
    @Lock();
    NSArray *array = self.signalKeysMap[signalName];
    for (NSString *key in array) {
        ExtSignalChannelContext *context = self.keyContextMap[key];
        [self.objectKeysMap[context.objectKey] removeObject:key];
        self.keyContextMap[key] = nil;
    }
    self.signalKeysMap[signalName] = nil;
    @Unlock();
}

- (void)removeAllSubscriber {
    @Lock();
    self.signalKeysMap = [NSMutableDictionary dictionary];
    self.keyContextMap = [NSMutableDictionary dictionary];
    self.objectKeysMap = [NSMutableDictionary dictionary];
    @Unlock();
}

- (NSArray *)contextsForSignalName:(NSString *)signalName {
    NSMutableArray *targetArray = [NSMutableArray array];
    NSArray *array = [self.signalKeysMap[signalName] copy];
    for (NSString *key in array) {
        ExtSignalChannelContext *ctx = self.keyContextMap[key];
        if (!ctx) {
            continue;
        }
        if (!ctx.object) {
            self.keyContextMap[key] = nil;
            [self.signalKeysMap[signalName] removeObject:key];
            [self.objectKeysMap[ctx.objectKey] removeObject:key];
            continue;
        }
        [targetArray addObject:ctx];
    }
    return targetArray;
}

- (void)forwardSignalName:(NSString *)signalName params:(nullable id)params {
    @Lock();
    NSArray *array = [self contextsForSignalName:signalName];
    @Unlock();
    ExtSignal *signal = nil;
    if (array.count > 0) {
        signal = [ExtSignal new];
        signal.channel = self;
        signal.name = signalName;
        signal.params = params;
    }
    for (ExtSignalChannelContext *context in array) {
        id object = context.object;
        if (object == nil) {
            continue;
        }
        if (context.handler) {
            context.handler(signal);
        } else {
            if (strstr(sel_getName(context.selector), ":") == NULL) {
                [context.object performSelector:context.selector];
            } else {
                [context.object performSelector:context.selector withObject:signal];
            }
        }
    }
}

@end

#pragma clang diagnostic pop
