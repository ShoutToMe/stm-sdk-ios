//
//  User.m
//  ShoutToMeDev
//
//  Description:
//      This object represents a user
//
//  Created by Adam Harris on 3/02/14.
//  Copyright 2015 Ditty Labs. All rights reserved.
//

#import "STMUser.h"
#import "Server.h"
#import "Utils.h"

#define USER_DATA_VERSION   7  // what version is this object (increased any time new items are added or existing items are changed)

#define KEY_USER_DATA_VERSION           @"UserDataVer"
#define KEY_USER_VERIFIED               @"UserVerified"
#define KEY_USER_AUTH_CODE              @"UserAuthCode"
#define KEY_USER_EMAIL                  @"UserEmail"
#define KEY_USER_PHONE_NUMBER           @"UserPhoneNumber"
#define KEY_USER_USER_ID                @"UserUserId"
#define KEY_USER_HANDLE                 @"UserHandle"
#define KEY_PLATFORM_ENDPOINT_ARN       @"UserPlatformEndpointARN"
#define KEY_USER_CHANNEL_SUBSCRIPTIONS  @"UserChannelSubscriptions"
#define KEY_USER_TOPIC_PREFERENCES      @"UserTopicPreferences"
#define KEY_USER_META_INFO              @"UserMetaInfo"

@interface STMUser ()
{

}

@end

@implementation STMUser

#pragma mark - Object Methods

- (id)init
{
    self = [super init];
    if (self) 
	{
        self.bVerified = NO;
        self.strAuthCode = @"";
        self.strEmail = @"";
        self.strPhoneNumber = @"";
        self.strUserID = @"";
        self.strHandle = @"";
        self.strPlatformEndpointArn = @"";
        self.channelSubscriptions = [NSArray new];
        self.topicPreferences = [NSArray new];
        self.metaInfo = [NSDictionary new];
    }
    return self;
}

- (void)dealloc
{

}

// overriding the description - used in debugging
- (NSString *)description
{
    return([NSString stringWithFormat:@"UserID: %@, Handle: %@, Email: %@, PhoneNumber: %@, AuthCode: %@, Verified: %@, PlatformEndpointARN: %@, MetaInfo: %@",
            self.strUserID,
            self.strHandle,
            self.strEmail,
            self.strPhoneNumber,
            self.strAuthCode,
            self.bVerified ? @"YES" : @"NO",
            self.strPlatformEndpointArn,
            self.metaInfo
            ]);
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (nil != (self = [self init]))
    {
        int version = [aDecoder decodeIntForKey:KEY_USER_DATA_VERSION];
        if (version >= USER_DATA_VERSION)
        {
            self.bVerified = [aDecoder decodeBoolForKey:KEY_USER_VERIFIED];

            NSString *strVal = nil;
            strVal = [aDecoder decodeObjectForKey:KEY_USER_AUTH_CODE];
            if (strVal)
            {
                self.strAuthCode = strVal;
            }
            else
            {
                self.strAuthCode = @"";
            }
            strVal = [aDecoder decodeObjectForKey:KEY_USER_EMAIL];
            if (strVal) {
                self.strEmail = strVal;
            } else {
                self.strEmail = @"";
            }
            strVal = [aDecoder decodeObjectForKey:KEY_USER_PHONE_NUMBER];
            if (strVal)
            {
                self.strPhoneNumber = strVal;
            }
            else
            {
                self.strPhoneNumber = @"";
            }
            strVal = [aDecoder decodeObjectForKey:KEY_USER_USER_ID];
            if (strVal)
            {
                self.strUserID = strVal;
            }
            else
            {
                self.strUserID = @"";
            }
            strVal = [aDecoder decodeObjectForKey:KEY_USER_HANDLE];
            if (strVal)
            {
                self.strHandle = strVal;
            }
            else
            {
                self.strHandle = @"";
            }

            strVal = [aDecoder decodeObjectForKey:KEY_PLATFORM_ENDPOINT_ARN];
            if (strVal)
            {
                self.strPlatformEndpointArn = strVal;
            }
            else
            {
                self.strPlatformEndpointArn = @"";
            }
            
            NSArray *channelSubscriptions = [aDecoder decodeObjectForKey:KEY_USER_CHANNEL_SUBSCRIPTIONS];
            if (channelSubscriptions)
            {
                self.channelSubscriptions = channelSubscriptions;
            }
            else
            {
                self.channelSubscriptions = [NSArray new];
            }
            
            NSArray *topicPreferences = [aDecoder decodeObjectForKey:KEY_USER_TOPIC_PREFERENCES];
            if (topicPreferences)
            {
                self.topicPreferences = topicPreferences;
            }
            else
            {
                self.topicPreferences = [NSArray new];
            }
            
            NSDictionary *metaInfo = [aDecoder decodeObjectForKey:KEY_USER_META_INFO];
            if (metaInfo)
            {
                self.metaInfo = metaInfo;
            }
            else
            {
                self.metaInfo = [NSDictionary new];
            }
        }
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:USER_DATA_VERSION forKey:KEY_USER_DATA_VERSION];
    [aCoder encodeBool:self.bVerified forKey:KEY_USER_VERIFIED];
    [aCoder encodeObject:self.strAuthCode forKey:KEY_USER_AUTH_CODE];
    [aCoder encodeObject:self.strEmail forKey:KEY_USER_EMAIL];
    [aCoder encodeObject:self.strPhoneNumber forKey:KEY_USER_PHONE_NUMBER];
    [aCoder encodeObject:self.strUserID forKey:KEY_USER_USER_ID];
    [aCoder encodeObject:self.strHandle forKey:KEY_USER_HANDLE];
    [aCoder encodeObject:self.strPlatformEndpointArn forKey:KEY_PLATFORM_ENDPOINT_ARN];
    [aCoder encodeObject:self.channelSubscriptions forKey:KEY_USER_CHANNEL_SUBSCRIPTIONS];
    [aCoder encodeObject:self.topicPreferences forKey:KEY_USER_TOPIC_PREFERENCES];
    [aCoder encodeObject:self.metaInfo forKey:KEY_USER_META_INFO];
}

#pragma mark - Misc Methods

- (void)setDataFromDictionary:(NSDictionary *)dict
{
    if (dict)
    {
        self.strUserID = [Utils stringFromKey:SERVER_RESULTS_USER_ID_KEY inDictionary:dict];
        self.strAuthCode = [Utils stringFromKey:SERVER_RESULTS_AUTH_TOKEN_KEY inDictionary:dict];
        self.strHandle = [Utils stringFromKey:SERVER_RESULTS_HANDLE_ID_KEY inDictionary:dict];
        self.strEmail = [Utils stringFromKey:SERVER_RESULTS_USER_EMAIL_KEY inDictionary:dict];
        self.strPhoneNumber = [Utils stringFromKey:SERVER_PHONE_NUMBER_KEY inDictionary:dict];
        self.bVerified = [Utils boolFromKey:SERVER_RESULTS_VERIFIED_KEY inDictionary:dict];
        if ([dict objectForKey:SERVER_RESULTS_PLATFORM_ENDPOINT_ARN_KEY] != nil) {
            self.strPlatformEndpointArn = [Utils stringFromKey:SERVER_RESULTS_PLATFORM_ENDPOINT_ARN_KEY inDictionary:dict];
        }
        
        NSArray *channelSubscriptions = [dict objectForKey:SERVER_RESULTS_CHANNEL_SUBSCRIPTIONS];
        if (channelSubscriptions) {
            self.channelSubscriptions = channelSubscriptions;
        }
        
        NSArray *topicPreferences = [dict objectForKey:SERVER_RESULTS_TOPIC_PREFERENCES];
        if (topicPreferences) {
            self.topicPreferences = topicPreferences;
        }
        
        NSDictionary *metaInfo = [dict objectForKey:SERVER_META_INFO];
        if (metaInfo) {
            self.metaInfo = metaInfo;
        }
    }
}

#pragma mark - Public Methods

- (id)initWithDictionary:(NSDictionary *)dict
{
    self = [super init];
    if (self)
    {
        [self setDataFromDictionary:dict];
    }
    return self;
}


@end
