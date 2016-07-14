//
//  Subscriptions.h
//  Pods
//
//  Created by Tyler Clemens on 7/6/16.
//
//

#import <Foundation/Foundation.h>
#import "STMSubscription.h"

@protocol SubscriptionsDelegate <NSObject>

@optional

- (void)requestForSubscriptionForChannelResult:(STMSubscription *)subscription;

@end

@interface Subscriptions : NSObject

+ (void)initAll;
+ (void)freeAll;

+ (Subscriptions *)controller;

- (void)requestForSubscriptionForChannel:(NSString *)channelId withDelegate:(id<SubscriptionsDelegate>)delegate;
- (void)requestForSubscriptionForChannel:(NSString *)channelId completionHandler:(void (^)(STMSubscription *subscription, NSError *error))completionHandler;
- (void)requestForSubscribe:(NSString *)channelId completionHandler:(void (^)(STMSubscription *subscription, NSError *error))completionHandler;
- (void)requestForUnSubscribe:(NSString *)channelId completionHandler:(void (^)(Boolean *successful, NSError *error))completionHandler;
@end
