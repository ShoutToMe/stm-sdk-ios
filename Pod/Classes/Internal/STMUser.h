//
//  User.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 3/02/14.
//  Copyright 2015 Ditty Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STMUser : NSObject

@property (nonatomic, assign) BOOL                  bVerified;
@property (nonatomic, copy)   NSString              *strAuthCode;
@property (nonatomic, copy)   NSString              *strEmail;
@property (nonatomic, copy)   NSString              *strPhoneNumber;
@property (nonatomic, copy)   NSString              *strUserID;
@property (nonatomic, copy)   NSString              *strHandle;
@property (nonatomic, copy)   NSDate                *dateLastReadMessages;
@property (nonatomic, copy)   NSString              *strPlatformEndpointArn;
@property (nonatomic, copy)   NSArray<NSString*>    *channelSubscriptions;
@property (nonatomic, copy)   NSArray<NSString*>    *topicPreferences;

- (id)initWithDictionary:(NSDictionary *)dictMessage;

@end
