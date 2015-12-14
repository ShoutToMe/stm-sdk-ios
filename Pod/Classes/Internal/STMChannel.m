//
//  Channel.m
//  ShoutToMeDev
//
//  Description:
//      This object represents channel information
//
//  Created by Adam Harris on 2/18/15.
//  Copyright (c) 2015 Adam Harris. All rights reserved.
//

#import "STMChannel.h"
#import "Utils.h"
#import "Server.h"

#define CHANNEL_DATA_VERSION   2  // what version is this object (increased any time new items are added or existing items are changed)

#define KEY_CHANNEL_DATA_VERSION            @"ChannelDataVer"
#define KEY_CHANNEL_ID                      @"ChannelId"
#define KEY_CHANNEL_TYPE                    @"ChannelType"
#define KEY_CHANNEL_NAME                    @"ChannelName"
#define KEY_CHANNEL_DESCRIPTION             @"ChannelDescription"
#define KEY_CHANNEL_GEOFENCED               @"ChannelGeofended"
#define KEY_CHANNEL_MIX_PANEL_TOKEN         @"ChannelMixPanelToken"
#define KEY_CHANNEL_WIT_ACCESS_TOKEN        @"ChannelWitAccessToken"
#define KEY_CHANNEL_IMAGE                   @"ChannelImage"
#define KEY_CHANNEL_IMAGE_LIST              @"ChannelImageList"

@interface STMChannel () <NSCopying>

@end

@implementation STMChannel

- (id)init
{
    self = [super init];
    if (self)
    {
        self.strID = @"";
        self.strType = @"";
        self.strName = @"";
        self.strDescription = @"";
        self.bGeofenced = NO;
        self.strMixPanelToken = @"";
        self.strWitAccessToken = @"";
        self.strChannelImage = @"";
        self.strChannelImageList = @"";
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictChannel
{
    self = [super init];
    if (self)
    {
        [self setDataFromDictionary:dictChannel];
    }
    return self;
}

- (NSString *)description
{
    NSString *strDesc = [NSString stringWithFormat:@"Channel - id: %@, name: %@, description: %@, mix_panel: %@, wit: %@, channel image: %@, channel image list: %@",
                         self.strID,
                         self.strName,
                         self.strDescription,
                         self.strMixPanelToken,
                         self.strWitAccessToken,
                         self.strChannelImage,
                         self.strChannelImageList
                         ];
    
    return strDesc;
}

- (NSUInteger)hash
{
    return [self.strID hash];
}

- (BOOL)isEqual:(id)other
{
    BOOL bEqual = NO;

    if ([other isKindOfClass:[STMChannel class]])
    {
        STMChannel *otherChannel = (STMChannel *)other;
        bEqual = [otherChannel.strID isEqualToString:self.strID];
    }

    return bEqual;
}

- (id)copyWithZone:(NSZone *)zone
{
    STMChannel *newChannel = [[[self class] allocWithZone:zone] init];

    newChannel.strID = [_strID copy];
    newChannel.strType = [_strType copy];
    newChannel.strName = [_strName copy];
    newChannel.strDescription = [_strDescription copy];
    newChannel.strMixPanelToken = [_strMixPanelToken copy];
    newChannel.strWitAccessToken = [_strWitAccessToken copy];
    newChannel.strChannelImage = [_strChannelImage copy];
    newChannel.strChannelImageList = [_strChannelImageList copy];
    newChannel.bGeofenced = _bGeofenced;

    return newChannel;
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (nil != (self = [self init]))
    {
        int version = [aDecoder decodeIntForKey:KEY_CHANNEL_DATA_VERSION];
        if (version >= CHANNEL_DATA_VERSION)
        {
            self.bGeofenced = [aDecoder decodeBoolForKey:KEY_CHANNEL_GEOFENCED];

            NSString *strVal = nil;
            strVal = [aDecoder decodeObjectForKey:KEY_CHANNEL_ID];
            if (strVal)
            {
                self.strID = strVal;
            }
            else
            {
                self.strID = @"";
            }
            strVal = [aDecoder decodeObjectForKey:KEY_CHANNEL_TYPE];
            if (strVal)
            {
                self.strType = strVal;
            }
            else
            {
                self.strType = @"";
            }
            strVal = [aDecoder decodeObjectForKey:KEY_CHANNEL_NAME];
            if (strVal)
            {
                self.strName = strVal;
            }
            else
            {
                self.strName = @"";
            }
            strVal = [aDecoder decodeObjectForKey:KEY_CHANNEL_DESCRIPTION];
            if (strVal)
            {
                self.strDescription = strVal;
            }
            else
            {
                self.strDescription = @"";
            }
            strVal = [aDecoder decodeObjectForKey:KEY_CHANNEL_MIX_PANEL_TOKEN];
            if (strVal)
            {
                self.strMixPanelToken = strVal;
            }
            else
            {
                self.strMixPanelToken = @"";
            }
            strVal = [aDecoder decodeObjectForKey:KEY_CHANNEL_WIT_ACCESS_TOKEN];
            if (strVal)
            {
                self.strWitAccessToken = strVal;
            }
            else
            {
                self.strWitAccessToken = @"";
            }
            strVal = [aDecoder decodeObjectForKey:KEY_CHANNEL_IMAGE];
            if (strVal)
            {
                self.strChannelImage = strVal;
            }
            else
            {
                self.strChannelImage = @"";
            }
            strVal = [aDecoder decodeObjectForKey:KEY_CHANNEL_IMAGE_LIST];
            if (strVal)
            {
                self.strChannelImageList = strVal;
            }
            else
            {
                self.strChannelImageList = @"";
            }
        }
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:CHANNEL_DATA_VERSION forKey:KEY_CHANNEL_DATA_VERSION];

    [aCoder encodeBool:self.bGeofenced forKey:KEY_CHANNEL_GEOFENCED];

    [aCoder encodeObject:self.strID forKey:KEY_CHANNEL_ID];
    [aCoder encodeObject:self.strType forKey:KEY_CHANNEL_TYPE];
    [aCoder encodeObject:self.strName forKey:KEY_CHANNEL_NAME];
    [aCoder encodeObject:self.strDescription forKey:KEY_CHANNEL_DESCRIPTION];
    [aCoder encodeObject:self.strMixPanelToken forKey:KEY_CHANNEL_MIX_PANEL_TOKEN];
    [aCoder encodeObject:self.strWitAccessToken forKey:KEY_CHANNEL_WIT_ACCESS_TOKEN];
    [aCoder encodeObject:self.strChannelImage forKey:KEY_CHANNEL_IMAGE];
    [aCoder encodeObject:self.strChannelImageList forKey:KEY_CHANNEL_IMAGE_LIST];
}

#pragma mark - Public Methods

#pragma mark - Misc Methods

- (void)setDataFromDictionary:(NSDictionary *)dictChannel
{
    if (dictChannel)
    {
        self.strID = [Utils stringFromKey:@"id" inDictionary:dictChannel];
        self.strType = [Utils stringFromKey:@"type" inDictionary:dictChannel];
        self.strName = [Utils stringFromKey:@"name" inDictionary:dictChannel];
        self.strDescription = [Utils stringFromKey:@"description" inDictionary:dictChannel];
        self.bGeofenced = [Utils boolFromKey:@"geofenced" inDictionary:dictChannel];
        self.strChannelImage = [Utils stringFromKey:@"channel_image" inDictionary:dictChannel];
        self.strChannelImageList = [Utils stringFromKey:@"channel_list_image" inDictionary:dictChannel];

        self.strMixPanelToken = [Utils stringFromKey:@"mobile" inDictionary:[dictChannel objectForKey:@"mixpanel_keys"]];

        self.strWitAccessToken = [Utils stringFromKey:@"mobile" inDictionary:[dictChannel objectForKey:@"wit_instance_ids"]];
    }
}

@end