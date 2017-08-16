//
//  Shout.m
//  ShoutToMeDev
//
//  Description:
//      This object represents shout information
//
//  Created by Adam Harris on 12/10/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import "STMShout.h"
#import "Utils.h"

@implementation STMShout

- (id)init
{
    self = [super init];
    if (self)
    {
        self.bHasBeenPlayed = NO;
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictShout
{
    self = [super init];
    if (self)
    {
        self.bHasBeenPlayed = NO;
        [self setDataFromDictionary:dictShout];
    }
    return self;
}

- (NSString *)description
{
    NSString *strDesc = [NSString stringWithFormat:@"Shout - id: %@, conversation_id: %@, spoken_text: %@",
                         self.str_id,
                         self.str_conversation_id,
                         self.str_spoken_text
                         ];

    return strDesc;
}

- (NSUInteger)hash
{
    return [self.str_id hash];
}

- (BOOL)isEqual:(id)other
{
    BOOL bEqual = NO;

    if ([other isKindOfClass:[STMShout class]])
    {
        STMShout *otherShout = (STMShout *)other;
        bEqual = [otherShout.str_id isEqualToString:self.str_id];
    }

    return bEqual;
}

#pragma mark - Public Methods

- (NSUInteger)ageInMinutes
{
    return ([[NSDate date] timeIntervalSinceDate:self.dateCreated] / 60.0) + 0.5;
}

#pragma mark - Misc Methods

// initialize data for a show using the dictionary returned from the server
- (void)setDataFromDictionary:(NSDictionary *)dictShout
{
    self.str_affiliate_id = [Utils stringFromKey:@"affiliate_id" inDictionary:dictShout];
    self.str_id = [Utils stringFromKey:@"id" inDictionary:dictShout];
    self.str_reply_to_id = [Utils stringFromKey:@"reply_to_id" inDictionary:dictShout];
    self.str_conversation_id = [Utils stringFromKey:@"conversation_id" inDictionary:dictShout];
    self.str_created_date = [Utils stringFromKey:@"created_date" inDictionary:dictShout];
    self.str_modified_date = [Utils stringFromKey:@"modified_date" inDictionary:dictShout];
    self.str_state = [Utils stringFromKey:@"state" inDictionary:dictShout];
    self.str_media_file_url = [Utils stringFromKey:@"media_file_url" inDictionary:dictShout];
    self.str_mime_type = [Utils stringFromKey:@"mime_type" inDictionary:dictShout];
    self.str_channel = [Utils stringFromKey:@"channel" inDictionary:dictShout];
    self.str_spoken_text = [Utils stringFromKey:@"spoken_text" inDictionary:dictShout];
    self.str_description = [Utils stringFromKey:@"description" inDictionary:dictShout];
    self.str_icon_url = [Utils stringFromKey:@"icon_url" inDictionary:dictShout];
    self.my_vote = [Utils doubleFromKey:@"my_vote" inDictionary:dictShout];
    self.trafficInfo = [self trafficInfoFromKey:@"traffic_info" inDictionary:dictShout];
    self.stats = [self statsFromKey:@"stats" inDictionary:dictShout];
    self.user = [self userFromKey:@"user" inDictionary:dictShout];

    if (self.str_created_date)
    {
        self.dateCreated = [Utils dateFromString:self.str_created_date];
    }

    if (self.str_modified_date)
    {
        self.dateModified = [Utils dateFromString:self.str_modified_date];
    }
}

// process the traffic info object from the server
- (STMShoutTrafficInfo *)trafficInfoFromKey:(NSString *)strKey inDictionary:(NSDictionary *)dict
{
    STMShoutTrafficInfo *trafficInfo = [[STMShoutTrafficInfo alloc] init];

    if (dict)
    {
        NSDictionary *dictTraffic = [dict objectForKey:strKey];

        trafficInfo.str_expiration_date = [Utils stringFromKey:@"expiration_date" inDictionary:dictTraffic];
        trafficInfo.heading = [Utils doubleFromKey:@"heading" inDictionary:dictTraffic];
        trafficInfo.speed_mph = [Utils doubleFromKey:@"speed_mph" inDictionary:dictTraffic];
        trafficInfo.str_category = [Utils stringFromKey:@"category" inDictionary:dictTraffic];
        trafficInfo.str_severity = [Utils stringFromKey:@"severity" inDictionary:dictTraffic];
    }

    return trafficInfo;
}

// process the stats info object from the server
- (STMShoutStats *)statsFromKey:(NSString *)strKey inDictionary:(NSDictionary *)dict
{
    STMShoutStats *stats = [[STMShoutStats alloc] init];

    if (dict)
    {
        NSDictionary *dictStats = [dict objectForKey:strKey];

        if (dictStats)
        {
            stats.view_count = [Utils doubleFromKey:@"view_count" inDictionary:dictStats];
            stats.broadcast_count = [Utils doubleFromKey:@"broadcast_count" inDictionary:dictStats];
            stats.approvals = [Utils doubleFromKey:@"approvals" inDictionary:dictStats];
            stats.disapprovals = [Utils doubleFromKey:@"disapprovals" inDictionary:dictStats];
            stats.score = [Utils doubleFromKey:@"score" inDictionary:dictStats];
        }
    }

    return stats;
}

// process the user info from the server
- (STMShoutUser *)userFromKey:(NSString *)strKey inDictionary:(NSDictionary *)dict
{
    STMShoutUser *user = [[STMShoutUser alloc] init];

    if (dict)
    {
        NSDictionary *dictUser = [dict objectForKey:strKey];

        if (dictUser)
        {
            user.str_user_name = [Utils stringFromKey:@"handle" inDictionary:dictUser];
            user.str_affiliate_id = [Utils stringFromKey:@"handle" inDictionary:dictUser];
            user.b_is_admin = [Utils boolFromKey:@"is_admin" inDictionary:dictUser];
            user.reputation_score = [Utils doubleFromKey:@"reputation_score" inDictionary:dictUser];
        }
    }
    
    return user;
}

@end

@implementation STMShoutTrafficInfo

@end

@implementation STMShoutStats

@end

@implementation STMShoutUser

@end
