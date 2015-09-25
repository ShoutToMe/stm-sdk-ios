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

#import "User.h"
#import "Utils.h"

#define USER_DATA_VERSION   1  // what version is this object (increased any time new items are added or existing items are changed)

#define KEY_USER_DATA_VERSION           @"UserDataVer"
#define KEY_USER_VERIFIED               @"UserVerified"
#define KEY_USER_AUTH_CODE              @"UserAuthCode"
#define KEY_USER_PHONE_NUMBER           @"UserPhoneNumber"
#define KEY_USER_USER_ID                @"UserUserId"
#define KEY_USER_HANDLE                 @"UserHandle"

@interface User ()
{

}

@end

@implementation User

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
    }
    return self;
}

- (void)dealloc
{

}

// overriding the description - used in debugging
- (NSString *)description
{
    return([NSString stringWithFormat:@"UserID: %@, Handle: %@, PhoneNumber: %@, AuthCode: %@, Verified: %@",
            self.strUserID,
            self.strHandle,
            self.strPhoneNumber,
            self.strAuthCode,
            self.bVerified ? @"YES" : @"NO"
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
}

#pragma mark - Misc Methods

#pragma mark - Public Methods


@end
