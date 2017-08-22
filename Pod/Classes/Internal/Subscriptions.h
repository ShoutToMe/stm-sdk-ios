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

- (void)requestForSubscriptionForChannel:(NSString *)channelId withDelegate:(id<SubscriptionsDelegate>)delegate __deprecated;
- (void)requestForSubscriptionForChannel:(NSString *)channelId completionHandler:(void (^)(STMSubscription *subscription, NSError *error))completionHandler __deprecated;
- (void)requestForSubscriptionsWithcompletionHandler:(void (^)(NSArray<STMSubscription *> *subscriptions, NSError *error))completionHandler __deprecated_msg("See STMUser.channelSubscriptions");
- (void)requestForSubscribe:(NSString *)channelId completionHandler:(void (^)(STMSubscription *subscription, NSError *error))completionHandler __deprecated_msg("Use User.subscribeTo");
- (void)requestForUnSubscribe:(NSString *)channelId completionHandler:(void (^)(Boolean *successful, NSError *error))completionHandler __deprecated_msg("Use User.unsubscribeFrom");
@end
