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
#import "DL_URLServer.h"
#import "STMShout.h"
#import "Settings.h"
#import "Error.h"
#import "SignIn.h"
#import "Utils.h"
#import "STMLocation.h"
#import "Shout.h"
#import "Channels.h"
#import "UserData.h"
#import "AudioSystem.h"
#import "RecordingSystem.h"
#import "Messages.h"
#import "Subscriptions.h"
#import "Conversations.h"
#import "STMGeofenceLocationManager.h"
#import "MonitoredConversations.h"

@protocol STMDelegate;

// this is singleton object class
// this means it has static methods that create on instance of itself for use by all

@interface STM : NSObject

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
+ (STMLocation *)location;
+ (Shout *)sendShout;
+ (Channels *)channels;
+ (AudioSystem *)audioSystem;
+ (RecordingSystem *)recordingSystem;
+ (Messages *)messages;
+ (Subscriptions *)subscriptions;
+ (Conversations *)conversations;
+ (STMGeofenceLocationManager *)stmGeofenceLocationManager;
+ (MonitoredConversations *)monitoredConversations;

@end

#endif
