//
//  STMMessage.m
//  Pods
//
//  Created by Tyler Clemens on 6/2/16.
//
//

#import "STMMessage.h"
#import "Utils.h"
#import "Server.h"

#define CHANNEL_DATA_VERSION   1  // what version is this object (increased any time new items are added or existing items are changed)

#define KEY_CHANNEL_DATA_VERSION                    @"ChannelDataVer"
#define KEY_CHANNEL_ID                              @"ChannelId"
#define KEY_CHANNEL_TYPE                            @"ChannelType"
#define KEY_CHANNEL_NAME                            @"ChannelName"
#define KEY_CHANNEL_DESCRIPTION                     @"ChannelDescription"
#define KEY_CHANNEL_GEOFENCED                       @"ChannelGeofended"
#define KEY_CHANNEL_MIX_PANEL_TOKEN                 @"ChannelMixPanelToken"
#define KEY_CHANNEL_WIT_ACCESS_TOKEN                @"ChannelWitAccessToken"
#define KEY_CHANNEL_IMAGE                           @"ChannelImage"
#define KEY_CHANNEL_IMAGE_LIST                      @"ChannelImageList"
#define KEY_CHANNEL_DEFAULT_MAX_LISTENING_SECONDS   @"ChannelDefaultMaxListeningSeconds"

@interface STMMessage ()

@end

@implementation STMMessage


- (id)init
{
    self = [super init];
    if (self)
    {
        self.strID = @"";
        self.strChannelId = @"";
        self.strSenderId = @"";
        self.strRecipientId = @"";
        self.strMessage = @"";
        self.strShoutId = @"";
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictMessage
{
    self = [super init];
    if (self)
    {
        [self setDataFromDictionary:dictMessage];
    }
    return self;
}

- (NSString *)description
{
    NSString *strDesc = [NSString stringWithFormat:@"Message - id: %@, channel_id: %@, sender_id: %@, recipient_id: %@, message: %@, shout_id: %@",
                         self.strID,
                         self.strChannelId,
                         self.strSenderId,
                         self.strRecipientId,
                         self.strMessage,
                         self.strShoutId
                         ];
    
    return strDesc;
}

#pragma mark - Misc Methods

- (void)setDataFromDictionary:(NSDictionary *)dictMessage
{
    if (dictMessage)
    {
        self.strID = [Utils stringFromKey:@"id" inDictionary:dictMessage];
        self.strChannelId = [Utils stringFromKey:@"channel_id" inDictionary:dictMessage];
        self.strSenderId = [Utils stringFromKey:@"sender_id" inDictionary:dictMessage];
        self.strRecipientId = [Utils stringFromKey:@"recipient_id" inDictionary:dictMessage];
        self.strMessage = [Utils stringFromKey:@"message" inDictionary:dictMessage];
        self.strShoutId = [Utils stringFromKey:@"shout_id" inDictionary:dictMessage];
        self.dateCreated = [Utils dateFromString:[Utils stringFromKey:@"created_date" inDictionary:dictMessage]];
    }
}

@end
