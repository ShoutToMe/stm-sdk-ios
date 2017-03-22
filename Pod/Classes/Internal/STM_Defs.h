//
//  STM_Defs.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 4/6/15.
//  Copyright 2015 Ditty Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

#define STM_TOS_URL                                             @"http://app-help.shoutto.me/tos.html"
#define STM_HELP_URL                                            @"http://app-help.shoutto.me/"
#define STM_BLANK_SHOUT_PAGE_URL                                @"http://app-help.shoutto.me/scanner-webview/empty.html"

#define STM_NOTIFICATION_SHOUT_FEED_CHANGE                      @"STM_Notification_Shout_Feed_Change"
#define STM_NOTIFICATION_SHOUT_PLAYER_STARTED                   @"STM_Notification_Shout_Player_Started"
#define STM_NOTIFICATION_SHOUT_PLAYER_ENDED                     @"STM_Notification_Shout_Player_Ended"
#define STM_NOTIFICATION_SHOUT_PLAYER_AUDIO_LOADED              @"STM_Notification_Shout_Player_Audio_Loaded"
#define STM_NOTIFICATION_LOCATION_UPDATED                       @"STM_Notification_Location_Updated"
#define STM_NOTIFICATION_LOCATION_DENIED                        @"STM_Notification_Location_Denied"
#define STM_NOTIFICATION_LOCATION_AUTHORIZATION_CHANGED         @"STM_Notification_Location_Authorization_Changed"
#define STM_NOTIFICATION_CONVERSATION_IGNORE_STATUS_CHANGED     @"STM_Notification_Conversation_Ignore_Status_Changed"
#define STM_NOTIFICATION_AUDIO_SYSTEM_STARTED_PLAYING           @"STM_Notification_Audio_System_Started_Playing"
#define STM_NOTIFICATION_AUDIO_SYSTEM_STOPPED_PLAYING           @"STM_Notification_Audio_System_Stopped_Playing"
#define STM_NOTIFICATION_MARKET_UPDATED                         @"STM_Notification_Market_Updated"
#define STM_NOTIFICATION_AUDIO_POWER_CHANGED                    @"STM_Notification_Recorder_Audio_Power_Changed"
#define STM_NOTIFICATION_SETTINGS_CHANNEL_CHANGED               @"STM_Notification_Settings_Channel_Changed"
#define STM_NOTIFICATION_KEY_SHOUT_PLAYER_SHOUT                 @"Shout"
#define STM_NOTIFICATION_KEY_SHOUT_PLAYER_LOAD_SUCCESS          @"LoadSuccess"

#define STM_NOTIFICATION_KEY_SHOUT_FEED_CHANGE_SHOUTS           @"Shouts"
#define STM_NOTIFICATION_KEY_SHOUT_FEED_CHANGE_CONVERSATIONS    @"Conversations"
#define STM_NOTIFICATION_KEY_SHOUT_FEED_CHANGE_LOOK_AHEAD       @"LookAhead"
#define STM_NOTIFICATION_KEY_SHOUT_FEED_CHANGE_AMOUNT           @"Amount"
#define STM_NOTIFICATION_KEY_SHOUT_FEED_CHANGE_UNIT             @"Unit"

#define STM_NOTIFICATION_KEY_LOCATION_UPDATED_LOCATION          @"Location"
#define STM_NOTIFICATION_KEY_LOCATION_AUTHORIZATION_STATUS      @"AuthorizationStatus"

#define STM_NOTIFICATION_KEY_CHANNEL_UPDATED_CHANNEL            @"Channel"

#define STM_NOTIFICATION_KEY_CONVERSATION_ID                    @"ConversationID"
#define STM_NOTIFICATION_KEY_CONVERSATION_IGNORED               @"ConversationIgnored"

#define STM_NOTIFICATION_KEY_MARKET_UPDATED_NAME                @"MarketName"

#define STM_LOCATION_INVALID_COURSE                             -1.0

#define STM_MAX_GEOFENCES                                       20


typedef enum eSTMInternalURLType
{
    STMInternalURLType_None,
    STMInternalURLType_Exit,
    STMInternalURLType_PlayShout,
    STMInternalURLType_AutoPlayShouts,
    STMInternalURLType_Muted,
    STMInternalURLType_Unmuted,
    STMInternalURLType_VerifyAccount,
    STMInternalURLType_SignOut,
    STMInternalURLType_DeleteAccount,
    STMInternalURLType_StatsDay,
    STMInternalURLType_StatsWeek,
    STMInternalURLType_StatsMonth,
    STMInternalURLType_StatsYear,
} tSTMInternalURLType;
