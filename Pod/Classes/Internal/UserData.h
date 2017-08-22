//
//  UserData.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 3/02/14.
//  Copyright 2015 Ditty Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STMUser.h"

// this is singleton object class
// this means it has static methods that create on instance of itself for use by all

@interface UserData : NSObject

@property (nonatomic, strong)   STMUser          *user;

+ (void)initAll;
+ (void)freeAll;

+ (void)loadAll;
+ (void)saveAll;

+ (UserData *)controller;

- (BOOL)isSignedIn;
- (void)signOut;
- (BOOL)isAnonymous;
- (BOOL)isVerified;
- (NSDictionary *)dictBasicRequestHeaders;
- (NSDictionary *)dictStandardRequestHeaders;
- (void)setHandle:(NSString *)strHandle;
- (void)setEmail:(NSString *)strEmail;
- (void)setPhone:(NSString *)strPhone;
- (void)setLastReadMessages:(NSDate *)date;
- (void)setPlatformEndpointArn:(NSString *)platformEndpointArn;
- (void)setChannelSubscriptions:(NSArray<NSString*>*)channelIds;
- (void)setTopicPreferences:(NSArray<NSString*>*)topics;
- (void)save;
- (void)signIn;

@end

