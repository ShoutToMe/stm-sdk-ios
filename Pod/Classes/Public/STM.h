//
//  STM.h
//  Pods
//
//  Created by Tyler Clemens on 8/17/15.
//
//

#ifndef Pods_STM_h
#define Pods_STM_h
#import <Foundation/Foundation.h>
#import "STM_Defs.h"
#import "STMShout.h"
#import "Settings.h"
#import "Error.h"
#import "SignIn.h"
//#import "VoiceCmd.h"
#import "Utils.h"
#import "STMLocation.h"
#import "SendShout.h"
//#import "ShoutFeed.h"
#import "ShoutPlayer.h"
//#import "Conversations.h"
//#import "Analytics.h"
//#import "Market.h"
#import "Channels.h"
#import "UserData.h"
#import "AudioSystem.h"
#import "RecordingSystem.h"
#import "Messages.h"

@protocol STMDelegate;

// this is singleton object class
// this means it has static methods that create on instance of itself for use by all

@interface STM : NSObject

//@property (nonatomic, weak)   id<STMDelegate>    delegate;
@property (nonatomic, copy)   NSString          *accessToken;
@property (nonatomic, copy)   NSString          *channelId;

+ (void)initWithAccessToken:(NSString *)token;
+ (void)saveAll;
+ (void)freeAll;
+ (void)setChannelId:(NSString *)channelId;

/**
 Singleton instance accessors.
 */
+ (STM *)sharedInstance;
+ (User *)currentUser;
+ (Settings *)settings;
+ (UserData *)userData;
+ (Error *)error;
+ (SignIn *)signIn;
//+ (VoiceCmd *)voiceCmd;
+ (STMLocation *)location;
+ (SendShout *)sendShout;
//+ (ShoutFeed *)shoutFeed;
+ (ShoutPlayer *)shoutPlayer;
//+ (Conversations *)conversations;
//+ (Analytics *)analytics;
//+ (Market *)market;
+ (Channels *)channels;
+ (AudioSystem *)audioSystem;
+ (RecordingSystem *)recordingSystem;
+ (Messages *)messages;
//+ (tSTMInternalURLType)urlType:(NSString *)strURL;
//+ (BOOL)stringIsSet:(NSString *)strString;

//- (void)setAuthorizationInURLRequest:(NSMutableURLRequest *)request;
//- (void)setBuildNumberInURLRequest:(NSMutableURLRequest *)request;
//- (NSURLRequest *)urlRequestForPage:(NSString *)strPage;
//- (NSURLRequest *)urlRequestForStats;
//- (void)setChannel:(Channel *)channel;


@end

@protocol STMDelegate <NSObject>

@required

@optional

- (NSDictionary *)STMAppUserDataForAnalytics;

@end

#endif
