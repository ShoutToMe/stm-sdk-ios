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
#import <AWSCore/AWSCore.h>
#import <AWSSNS/AWSSNS.h>
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
#import "MonitoredConversations.h"

@protocol STMDelegate <NSObject>

@required

@optional

- (void)STMNotificationRecieved:(NSDictionary *)notification;

@end

// this is singleton object class
// this means it has static methods that create on instance of itself for use by all

@interface STM : NSObject

@property (nonatomic, copy)   NSString          *accessToken;
@property (nonatomic, copy)   NSString          *channelId;
@property (nonatomic, copy)   NSString          *applicationArn;
@property (nonatomic, weak)   id<STMDelegate>   delegate;
@property AWSTask *task;

+ (void)initWithAccessToken:(NSString *)token andApplication:(UIApplication *)application andDelegate:(id)delegate;
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData*)deviceToken;
+ (void)didReceiveRemoteNotification:(NSDictionary *)userInfo ForApplication:(UIApplication *)application fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler;
+ (void)saveAll;
+ (void)freeAll;
+ (void)setChannelId:(NSString *)channelId;
+ (void)setupNotificationsWithApplication:(UIApplication *)application __deprecated;
+ (void)setupNotificationsWithApplication:(UIApplication *)application pushNotificationAppId:(nonnull NSString *)pushNotificationAppId;
+ (void)presentRecordingOverlayWithViewController:(UIViewController *)vc andTags:(NSString *)tags andTopic:(NSString *)topic andMaxListeningSeconds:(NSNumber *)maxListeningSeconds andDelegate:(id)delegate andError:(NSError **)error;

/**
 Singleton instance accessors.
 */
+ (STM *)sharedInstance;
+ (STMUser *)currentUser;
+ (Settings *)settings;
+ (UserData *)userData;
+ (Error *)error;
+ (SignIn *)signIn;
+ (STMLocation *)location;
+ (Shout *)shout;
+ (Channels *)channels;
+ (AudioSystem *)audioSystem;
+ (RecordingSystem *)recordingSystem;
+ (Messages *)messages;
+ (Subscriptions *)subscriptions;
+ (Conversations *)conversations;
+ (MonitoredConversations *)monitoredConversations;

@end

#endif
