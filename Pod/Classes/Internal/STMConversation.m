//
//  Conversation.m
//  ShoutToMeDev
//
//  Description:
//      This object represents conversation information
//
//  Created by Adam Harris on 1/5/15.
//  Copyright (c) 2015 Adam Harris. All rights reserved.
//

#import "STMConversation.h"
#import "Utils.h"
#import "Server.h"

@implementation STMConversation

- (id)init
{
    self = [super init];
    if (self)
    {

    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictConversation
{
    self = [super init];
    if (self)
    {
        [self setDataFromDictionary:dictConversation];
        self.dateDownloaded = [NSDate date];
    }
    return self;
}

- (NSString *)description
{
    NSString *strDesc = [NSString stringWithFormat:@"Conversation - id: %@",
                         self.str_id
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

    if ([other isKindOfClass:[STMConversation class]])
    {
        STMConversation *otherConversation = (STMConversation *)other;
        bEqual = [otherConversation.str_id isEqualToString:self.str_id];
    }

    return bEqual;
}

#pragma mark - Public Methods

- (NSUInteger)ageInMinutes
{
    return ([[NSDate date] timeIntervalSinceDate:self.dateCreated] / 60.0) + 0.5;
}

- (NSUInteger)minutesAgoDownloaded
{
    return ([[NSDate date] timeIntervalSinceDate:self.dateDownloaded] / 60.0) + 0.5;
}

- (BOOL)expired {
    NSDate *myDate = self.dateExpiration;
    if ([myDate earlierDate:[NSDate date]] == myDate) {
        //NSLog(@"myDate is EARLIER than today");
        return true;
    } else {
        //NSLog(@"myDate is LATER than today");
        return false;
    }
}

// returns the subtitle for a given conversation
- (NSString *)subTitle
{
    NSString *strSubTitle = NSLocalizedString(@"No longer impacting traffic", nil);

    double expireSecs = ([self.dateExpiration timeIntervalSinceDate:[NSDate date]]);

    if (expireSecs > 0)
    {
        strSubTitle = [NSString stringWithFormat:@"%@ %@", self.str_time_prefix, [Utils timeStringForSeconds:expireSecs]];
    }

    return strSubTitle;
}

// returns YES if this conversation is a new version of the one provided
- (BOOL)isUpdatedVersionOf:(STMConversation *)otherConversation
{
    BOOL bUpdated = NO;

    if (otherConversation)
    {
        if ([self.str_id isEqualToString:otherConversation.str_id])
        {
            if (self.shout_count != otherConversation.shout_count)
            {
                bUpdated = YES;
            }
            else if (self.bVerified != otherConversation.bVerified)
            {
                bUpdated = YES;
            }
            else if (self.severity != otherConversation.severity)
            {
                bUpdated = YES;
            }
            else if (![self.str_expiration_date isEqualToString:otherConversation.str_expiration_date])
            {
                bUpdated = YES;
            }
            else if (![self.str_created_date isEqualToString:otherConversation.str_created_date])
            {
                bUpdated = YES;
            }
            else if (![self.str_modified_date isEqualToString:otherConversation.str_modified_date])
            {
                bUpdated = YES;
            }
            else if (![self.str_start_date isEqualToString:otherConversation.str_start_date])
            {
                bUpdated = YES;
            }
            else if (![self.str_type isEqualToString:otherConversation.str_type])
            {
                bUpdated = YES;
            }
            else if (![self.str_summary isEqualToString:otherConversation.str_summary])
            {
                bUpdated = YES;
            }
            else if (![self.str_time_prefix isEqualToString:otherConversation.str_time_prefix])
            {
                bUpdated = YES;
            }
            else if (![self.str_spoken_meta_information isEqualToString:otherConversation.str_spoken_meta_information])
            {
                bUpdated = YES;
            }
        }
    }
    
    return bUpdated;
}

#pragma mark - Misc Methods

// initialize the dictionary with the information from the server
- (void)setDataFromDictionary:(NSDictionary *)dictConversation
{
    self.str_id = [Utils stringFromKey:@"id" inDictionary:dictConversation];
    self.str_created_date = [Utils stringFromKey:@"created_date" inDictionary:dictConversation];
    self.str_modified_date = [Utils stringFromKey:@"modified_date" inDictionary:dictConversation];
    self.str_expiration_date = [Utils stringFromKey:@"expiration_date" inDictionary:dictConversation];
    self.str_start_date = [Utils stringFromKey:@"start_date" inDictionary:dictConversation];
    self.shout_count = [Utils intFromKey:@"shout_count" inDictionary:dictConversation];
    self.str_severity = [Utils stringFromKey:@"severity" inDictionary:dictConversation];
    self.str_type = [Utils stringFromKey:@"type" inDictionary:dictConversation];
    self.bVerified = [Utils boolFromKey:@"verified" inDictionary:dictConversation];
    self.str_summary = [Utils stringFromKey:@"summary" inDictionary:dictConversation];
    self.str_time_prefix = [Utils stringFromKey:@"time_prefix" inDictionary:dictConversation];
    self.location = [self locationFromKey:@"location" inDictionary:dictConversation];
    self.str_spoken_meta_information = [Utils stringFromKey:@"spoken_meta_information" inDictionary:dictConversation];
    self.str_url = [Utils stringFromKey:@"url" inDictionary:dictConversation];
    
    self.str_channel_id = [Utils stringFromKey:@"channel_id" inDictionary:dictConversation];
    self.str_publishing_message = [Utils stringFromKey:@"publishing_message" inDictionary:dictConversation];
    self.str_topic = [Utils stringFromKey:@"topic" inDictionary:dictConversation];
    self.str_created_by = [Utils stringFromKey:@"created_by" inDictionary:dictConversation];
    self.str_created_by_handle = [Utils stringFromKey:@"created_by_handle" inDictionary:dictConversation];

    self.severity = STM_Conversation_Severity_Moderate;
    if ([self.str_severity isEqualToString:SERVER_CONVERSTATION_SEVERITY_MINOR])
    {
        self.severity = STM_Conversation_Severity_Minor;
    }
    else if ([self.str_severity isEqualToString:SERVER_CONVERSTATION_SEVERITY_MAJOR])
    {
        self.severity = STM_Conversation_Severity_Major;
    }

    self.dateCreated = [Utils dateFromString:self.str_created_date];
    self.dateExpiration = [Utils dateFromString:self.str_expiration_date];
    self.dateModified = [Utils dateFromString:self.str_modified_date];
    self.dateStart = [Utils dateFromString:self.str_start_date];
}

// initialize the location information from data provided from server
- (ConversationLocation *)locationFromKey:(NSString *)strKey inDictionary:(NSDictionary *)dict
{
    ConversationLocation *location = [[ConversationLocation alloc] init];

    if (dict)
    {
        NSDictionary *dictLocation = [dict objectForKey:strKey];

        if (dictLocation)
        {
            location.lat = [Utils doubleFromKey:@"lat" inDictionary:dictLocation];
            location.lon = [Utils doubleFromKey:@"lon" inDictionary:dictLocation];
            location.radius_in_meters = [Utils doubleFromKey:@"radius_in_meters" inDictionary:dictLocation];
            location.str_description = [Utils stringFromKey:@"description" inDictionary:dictLocation];
        }
    }

    return location;
}


@end

@implementation ConversationLocation

@end