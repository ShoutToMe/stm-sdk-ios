//
//  User.h
//
//  Created by Tracy Rojas on 7/31/17.
//  Copyright (c) Shout to Me 2017. All rights reserved.
//
//

#import <Foundation/Foundation.h>
#import "DL_URLServer.h"
#import "STMNetworking.h"

@interface SetUserPropertiesInput : NSObject

@property (nonatomic, nullable) NSString *email;
@property (nonatomic, nullable) NSString *handle;
@property (nonatomic, nullable) NSString *phoneNumber;

-(nonnull NSDictionary *)getPropertyDictionary;

@end

@interface User : NSObject <DL_URLRequestDelegate>

+ (void)initAll;
+ (void)freeAll;

+ (nonnull User *)controller;

/**
 <p>Updates the logged in user's properties.</p>
 @param setUserPropertiesInput The object containing the updated user properties
 @param completionHandler A block that returns void and contains a signature of (NSError *, id). The id will be a pointer to an STMUser object.
 */
- (void)setProperties:(SetUserPropertiesInput *_Nonnull)setUserPropertiesInput withCompletionHandler:(void (^_Nullable)(NSError *_Nullable, id _Nullable))completionHandler;

- (void)enableNotifications;
- (void)subscribeTo:(NSString *_Nonnull)channelId withCompletionHandler:(void (^_Nullable)(NSError *_Nullable, id _Nullable))completionHandler;
- (void)unsubscribeFrom:(NSString *_Nonnull)channelId withCompletionHandler:(void (^_Nullable)(NSError *_Nullable, id _Nullable))completionHandler;
- (void)setChannelSubscriptions:(NSArray<NSString *>*_Nonnull)channelIds withCompletionHandler:(void (^_Nullable)(NSError *_Nullable, id _Nullable))completionHandler;
- (BOOL)isSubscribedToChannel:(NSString *_Nonnull)channelId;
- (void)addTopicPreference:(NSString *_Nonnull)topic withCompletionHandler:(void (^_Nullable)(NSError *_Nullable, id _Nullable))completionHandler;
- (void)removeTopicPreference:(NSString *_Nonnull)topic withCompletionHandler:(void (^_Nullable)(NSError *_Nullable, id _Nullable))completionHandler;
- (void)setTopicPreferences:(NSArray<NSString *>*_Nonnull)topics withCompletionHandler:(void (^_Nullable)(NSError *_Nullable, id _Nullable))completionHandler;
- (BOOL)isFollowingTopic:(NSString *_Nonnull)topic;

@end

@interface UserLocation : NSObject <STMHTTPResponseHandlerDelegate>

@property NSDate * _Nonnull timestamp;
@property double lat;
@property double lon;
@property NSNumber * _Nullable metersSinceLastUpdate;

- (void)update;

@end
