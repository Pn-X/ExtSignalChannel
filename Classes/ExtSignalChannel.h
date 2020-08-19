//
//  ExtSignalChannel.h
//  Pods-Example
//
//  Created by hang_pan on 2020/8/19.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@class ExtSignalChannel, ExtSignal;

typedef void(^ExtSignalChannelHandler)(ExtSignal *signal);

@interface ExtSignal : NSObject

@property (nonatomic, strong, readonly) ExtSignalChannel *channel;

@property (nonatomic, copy, readonly) NSString *name;

@property (nonatomic, strong, readonly, nullable) id params;

@end

@interface NSObject (ExtSignalChannel)

@property (nonatomic, strong, readonly) ExtSignalChannel *ext_signalChannel;

@end

@interface ExtSignalChannel : NSObject

@property (nonatomic, strong) NSString *name;

//singleton channel will connect to [NSNotificationCenter defaultCenter] auotmaticly
+ (instancetype)singleton;

- (void)sendSignalName:(NSString *)signalName;

- (void)sendSignalName:(NSString *)signalName params:(nullable id)params;

//selector suport 0 or 1 argument
- (void)addSubscriber:(id)subscriber forSignalName:(NSString *)signalName withSelector:(SEL)selector ;

- (void)addSubscriber:(id)subscriber forSignalName:(NSString *)signalName withHandler:(ExtSignalChannelHandler)handler ;

- (void)removeSubscriber:(id)subscriber forSignalName:(NSString *)signalName;

- (void)removeSubscriber:(id)subscriber;

- (void)removeAllSubscriberForSignalName:(NSString *)signalName;

- (void)removeAllSubscriber;

@end

NS_ASSUME_NONNULL_END
