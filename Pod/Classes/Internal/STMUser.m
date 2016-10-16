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
#import "Utils.h"

#define USER_DATA_VERSION   4  // what version is this object (increased any time new items are added or existing items are changed)

#define KEY_USER_DATA_VERSION           @"UserDataVer"
#define KEY_USER_VERIFIED               @"UserVerified"
#define KEY_USER_AUTH_CODE              @"UserAuthCode"
#define KEY_USER_PHONE_NUMBER           @"UserPhoneNumber"
#define KEY_USER_USER_ID                @"UserUserId"
#define KEY_USER_HANDLE                 @"UserHandle"
#define KEY_USER_LAST_VIEWED_MESSAGES   @"UserLastViewedMessages"
#define KEY_PLATFORM_ENDPOINT_ARN       @"UserPlatformEndpointARN"

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
        self.strPhoneNumber = @"";
        self.strUserID = @"";
        self.strHandle = @"";
        self.dateLastReadMessages = [NSDate date];
        self.strPlatformEndpointArn = @"";
    }
    return self;
}

- (void)dealloc
{

}

// overriding the description - used in debugging
- (NSString *)description
{
    return([NSString stringWithFormat:@"UserID: %@, Handle: %@, PhoneNumber: %@, AuthCode: %@, Verified: %@, LastViewedMessages: %@, PlatformEndpointARN: %@",
            self.strUserID,
            self.strHandle,
            self.strPhoneNumber,
            self.strAuthCode,
            self.bVerified ? @"YES" : @"NO",
            self.dateLastReadMessages,
            self.strPlatformEndpointArn
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
            
            NSDate  *dateVal = [aDecoder decodeObjectForKey:KEY_USER_LAST_VIEWED_MESSAGES];
            if (dateVal)
            {
                self.dateLastReadMessages = dateVal;
            }
            else
            {
                self.dateLastReadMessages = [NSDate date];
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
        }
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:USER_DATA_VERSION forKey:KEY_USER_DATA_VERSION];
    [aCoder encodeBool:self.bVerified forKey:KEY_USER_VERIFIED];
    [aCoder encodeObject:self.strAuthCode forKey:KEY_USER_AUTH_CODE];
    [aCoder encodeObject:self.strPhoneNumber forKey:KEY_USER_PHONE_NUMBER];
    [aCoder encodeObject:self.strUserID forKey:KEY_USER_USER_ID];
    [aCoder encodeObject:self.strHandle forKey:KEY_USER_HANDLE];
    [aCoder encodeObject:self.dateLastReadMessages forKey:KEY_USER_LAST_VIEWED_MESSAGES];
    [aCoder encodeObject:self.strPlatformEndpointArn forKey:KEY_PLATFORM_ENDPOINT_ARN];
}

#pragma mark - Misc Methods

- (void)setDataFromDictionary:(NSDictionary *)dict
{
    if (dict)
    {
        self.strUserID = [Utils stringFromKey:@"id" inDictionary:dict];
        self.strHandle = [Utils stringFromKey:@"handle" inDictionary:dict];
        self.bVerified = [Utils boolFromKey:@"verified" inDictionary:dict];
        self.dateLastReadMessages = [Utils dateFromString:[Utils stringFromKey:@"last_read_messages_date" inDictionary:dict]];
        if ([dict objectForKey:@"platform_endpoint_arn"] != nil) {
            self.strPlatformEndpointArn = [Utils stringFromKey:@"platform_endpoint_arn" inDictionary:dict];
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
