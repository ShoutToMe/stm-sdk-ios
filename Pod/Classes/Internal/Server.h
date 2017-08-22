//
//  Server.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 11/4/14.
//  Copyright (c) 2014 DittyLabs. All rights reserved.
//

#ifndef ShoutToMeDev_Server_h
#define ShoutToMeDev_Server_h

#define AUTH_KEY                                @"Authorization"

#define BASIC_AUTH_PREFIX                       @"Basic"

#define STD_AUTH_PREFIX                         @"Bearer"

#define BUILD_HEADER_PREFIX                     @"BuildNumber"

#define CONTENT_TYPE                            @"application/json; charset=utf-8"

#define SERVER_URL                              @"https://app.shoutto.me/api/v1"


#define SERVER_PAGE_STATS                       @"webviews/me#/me"

#define SERVER_CMD_SKIP                         @"users/skip"
#define SERVER_CMD_ANON                         @"users"
#define SERVER_CMD_PERSONALIZE                  @"users"
#define SERVER_CMD_VERIFY                       @"users/verify"
#define SERVER_CMD_SIGNIN                       @"users/signin"
#define SERVER_CMD_SIGNUP                       @"users/signup"
#define SERVER_CMD_POST_SHOUT                   @"shouts"
#define SERVER_CMD_GET_SHOUTS                   @"shouts"
#define SERVER_CMD_POST_PLAYED                  @"shouts"
#define SERVER_CMD_GET_CONVERSATIONS            @"conversations"
#define SERVER_CMD_GET_CHANNELS                 @"channels"
#define SERVER_CMD_POST_ERROR                   @"errors"
#define SERVER_CMD_UNDO_SHOUT                   @"shouts"
#define SERVER_CMD_PUT_MUTE_CONVERSATION        @"mute"
#define SERVER_CMD_PUT_SHOUT                    @"shouts"
#define SERVER_CMD_PUT_DOWNVOTE_SHOUT           @"downvote"
#define SERVER_CMD_GET_CURRENT_MARKET           @"markets/current"
#define SERVER_CMD_GET_MESSAGES                 @"messages"
#define SERVER_CMD_GET_SUBSCRIPTIONS            @"subscriptions"
#define SERVER_CMD_CHANNEL_SUBSCRIPTION         @"channel_subscription"
#define SERVER_CMD_TOPIC_PREFERENCE             @"topic_preference"

#define SERVER_DEVICE_ID_KEY                    @"device_id"
#define SERVER_PHONE_NUMBER_KEY                 @"phone"
#define SERVER_VERIFICATION_CODE_KEY            @"verification_code"
#define SERVER_CHANNEL_ID_KEY                   @"channel_id"
#define SERVER_REPLY_TO_ID_KEY                  @"reply_to_id"
#define SERVER_AUDIO_KEY                        @"audio"
#define SERVER_MEDIA_FILE_URL_KEY               @"media_file_url"
#define SERVER_SPOKEN_TEXT_KEY                  @"spoken_text"
#define SERVER_DESCRIPTION_KEY                  @"description"
#define SERVER_REPLY_TO_ID_KEY                  @"reply_to_id"
#define SERVER_LAT_KEY                          @"lat"
#define SERVER_LON_KEY                          @"lon"
#define SERVER_HANDLE_KEY                       @"handle"
#define SERVER_LAST_READ_MESSAGES_KEY           @"last_read_messages_date"
#define SERVER_COURSE_KEY                       @"course"
#define SERVER_SPEED_KEY                        @"speed"
#define SERVER_DEVICE_ID_KEY                    @"device_id"
#define SERVER_TAGS_KEY                         @"tags"
#define SERVER_TOPIC_KEY                        @"topic"
#define SERVER_PLATFORM_ENDPOINT_ENABLED_KEY    @"platform_endpoint_enabled"
#define SERVER_PLATFORM_ENDPOINT_ARN_KEY        @"platform_endpoint_arn"
#define SERVER_SNS_APPLICATION_ARN_PREFIX       @"arn:aws:sns:us-west-2:810633828709:app/APNS/"
#define SERVER_SNS_TEST_APPLICATION_ARN_PREFIX  @"arn:aws:sns:us-west-2:810633828709:app/APNS_SANDBOX/"

#define SERVER_VERIFY_PHONE_ARG                 @"phone"

#define SERVER_VERIFY_PHONE_KEY                 @"phone"
#define SERVER_VERIFY_CODE_KEY                  @"verification_code"

#define SERVER_STORAGE_REQUEST_AFFILIATE_ID_ARG @"affiliate_id"

#define SERVER_RESULTS_STATUS_KEY               @"status"
#define SERVER_RESULTS_STATUS_SUCCESS           @"success"
#define SERVER_RESULTS_STATUS_FAILURE           @"failure"
#define SERVER_RESULTS_STATUS_FAILURE_CODE_KEY  @"code"
#define SERVER_RESULTS_DATA_KEY                 @"data"
#define SERVER_RESULTS_AUTH_TOKEN_KEY           @"auth_token"
#define SERVER_RESULTS_USER_KEY                 @"user"
#define SERVER_RESULTS_AFFILIATE_KEY            @"affiliate_id"
#define SERVER_RESULTS_AFFILIATE_DATA_KEY       @"affiliate"
#define SERVER_RESULTS_AFFILIATE_ID_KEY         @"id"
#define SERVER_RESULTS_DEFAULT_CHANNEL_KEY      @"default_channel"
#define SERVER_RESULTS_CHANNEL_ID_KEY           @"id"
#define SERVER_RESULTS_CHANNEL_NAME_KEY         @"name"
#define SERVER_RESULTS_CHANNEL_DESCRIPTION_KEY  @"description"
#define SERVER_RESULTS_CHANNEL_IMAGE_KEY        @"channel_image"
#define SERVER_RESULTS_CHANNEL_LIST_IMAGE_KEY   @"channel_list_image"
#define SERVER_RESULTS_CHANNEL_SUBSCRIPTIONS    @"channel_subscriptions"
#define SERVER_RESULTS_MIX_PANEL_KEY            @"mixpanel_keys"
#define SERVER_RESULTS_MIX_PANEL_TOKEN_KEY      @"mobile"
#define SERVER_RESULTS_WIT_KEY                  @"wit_instance_ids"
#define SERVER_RESULTS_WIT_ACCESS_TOKEN_KEY     @"mobile"
#define SERVER_RESULTS_HANDLE_ID_KEY            @"handle"
#define SERVER_RESULTS_USER_ID_KEY              @"id"
#define SERVER_RESULTS_USER_EMAIL_KEY           @"email"
#define SERVER_RESULTS_SHOUT_KEY                @"shout"
#define SERVER_RESULTS_SHOUT_AMOUNT_KEY         @"distance"
#define SERVER_RESULTS_SHOUT_UNIT_KEY           @"unit"
#define SERVER_RESULTS_TOPIC_PREFERENCES        @"topic_preferences"
#define SERVER_RESULTS_VERIFIED_KEY             @"verified"
#define SERVER_RESULTS_MARKET_KEY               @"market"
#define SERVER_RESULTS_MARKET_NAME_KEY          @"name"
#define SERVER_RESULTS_MARKET_SUPPORTED_KEY     @"supported"
#define SERVER_RESULTS_LAST_READ_MESSAGES_KEY       @"last_read_messages_date"
#define SERVER_RESULTS_PLATFORM_ENDPOINT_ARN_KEY    @"platform_endpoint_arn"


#define SERVER_GET_SHOUTS_CHANNEL_ID_ARG        @"channel_id"
#define SERVER_GET_SHOUTS_LAT_ARG               @"lat"
#define SERVER_GET_SHOUTS_LON_ARG               @"lon"
#define SERVER_GET_SHOUTS_COURSE_ARG            @"course"
#define SERVER_GET_SHOUTS_SPEED_ARG             @"speed"
#define SERVER_GET_SHOUTS_TYPE_ARG              @"type"
#define SERVER_GET_SHOUTS_LOOK_AHEAD            @"ahead"
#define SERVER_GET_SHOUTS_AMOUNT_ARG            @"distance"
#define SERVER_GET_SHOUTS_UNIT_ARG              @"unit"

#define SERVER_GET_CONV_CHANNEL_ID_ARG          @"channel_id"
#define SERVER_GET_CONV_NW_LAT_ARG              @"nw_lat"
#define SERVER_GET_CONV_NW_LON_ARG              @"nw_lon"
#define SERVER_GET_CONV_SE_LAT_ARG              @"se_lat"
#define SERVER_GET_CONV_SE_LON_ARG              @"se_lon"

#define SERVER_CONVERSTATION_SEVERITY_MINOR     @"minor"
#define SERVER_CONVERSTATION_SEVERITY_MODERATE  @"moderate"
#define SERVER_CONVERSTATION_SEVERITY_MAJOR     @"major"

#define SERVER_CONVERSATION_WEB_URL             @"webviews/conversations"
#define SERVER_CONVERSATION_AUTO_PLAY_ARG       @"replay"
#define SERVER_CONVERSATION_BUTTON_POSITION_ARG @"floating_button_position"
#define SERVER_CONVERSATION_WEBVIEW_SUFFIX      @"#/conversation"

#define SERVER_CONVERSATION_WEB_ROOT_COMPONENT  @"webviews"


#define SERVER_ERR_USER_NOT_FOUND               1300
#define SERVER_ERR_INVALID_PHONE                1301
#define SERVER_ERR_USER_ALREADY_EXISTS          1302
#define SERVER_ERR_HANDLE_ALREADY_EXISTS        1303
#define SERVER_ERR_INVALID_VERIFICATION_CODE    1401

#define SERVER_URL_PREFIX_PLAY_SHOUT            @"play-shout:"
#define SERVER_URL_PREFIX_EXIT                  @"exit:"
#define SERVER_URL_PREFIX_AUTO_PLAY_SHOUTS      @"play-shouts:"
#define SERVER_URL_PREFIX_CONVERSATION_MUTED    @"conversation-muted:"
#define SERVER_URL_PREFIX_CONVERSATION_UNMUTED  @"conversation-unmuted:"
#define SERVER_URL_PREFIX_VERIFY                @"verify:"
#define SERVER_URL_PREFIX_SIGNOUT               @"signout:"
#define SERVER_URL_PREFIX_DELETE                @"delete:"
#define SERVER_URL_PREFIX_STATS_DAY             @"stats-day:"
#define SERVER_URL_PREFIX_STATS_WEEK            @"stats-week:"
#define SERVER_URL_PREFIX_STATS_MONTH           @"stats-month:"
#define SERVER_URL_PREFIX_STATS_YEAR            @"stats-year:"

#define SERVER_AWS_COGNITO_POOL_ID              @"us-east-1:4ec2b44e-0dde-43e6-a279-6ee1cf241b05"
#define SERVER_AWS_S3_CONFIGURATION_KEY         @"me.shoutto.S3"
#define SERVER_AWS_S3_UPLOAD_BUCKET_NAME        @"s2m-shout-upload-inbox"
#define SERVER_AWS_S3_UPLOAD_URL_PREFIX         @"https://s3-us-west-2.amazonaws.com/"SERVER_AWS_S3_UPLOAD_BUCKET_NAME@"/"
#define SERVER_AWS_SNS_CONFIGURATION_KEY        @"me.shoutto.SNS"

#endif
