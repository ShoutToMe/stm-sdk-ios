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

- (void)STMNotificationRecieved:(nullable NSDictionary *)notification;

@end

// this is singleton object class
// this means it has static methods that create on instance of itself for use by all

@interface STM : NSObject

@property (nonatomic, copy, nullable)   NSString          *accessToken;
@property (nonatomic, copy, nullable)   NSString          *channelId;
@property (nonatomic, copy, nullable)   NSString          *applicationArn;
@property (nonatomic, weak, nullable)   id<STMDelegate>   delegate;
@property (nullable) AWSTask *task;

+ (void)initWithAccessToken:(nonnull NSString *)token andApplication:(nonnull UIApplication *)application andDelegate:(nonnull id)delegate;
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(nonnull NSData*)deviceToken;
+ (void)didReceiveRemoteNotification:(nonnull NSDictionary *)userInfo ForApplication:(nonnull UIApplication *)application fetchCompletionHandler:(nonnull void (^)(UIBackgroundFetchResult))completionHandler;
+ (void)saveAll;
+ (void)freeAll;
+ (void)setChannelId:(nonnull NSString *)channelId;
+ (void)setupNotificationsWithApplication:(nonnull UIApplication *)application __deprecated;
+ (void)setupNotificationsWithApplication:(nonnull UIApplication *)application pushNotificationAppId:(nonnull NSString *)pushNotificationAppId;
+ (void)presentRecordingOverlayWithViewController:(nonnull UIViewController *)vc andTags:(nullable NSString *)tags andTopic:(nullable NSString *)topic andMaxListeningSeconds:(nullable NSNumber *)maxListeningSeconds andDelegate:(nonnull id)delegate andError:(NSError * _Nullable * _Null_unspecified)error;

/**
 Singleton instance accessors.
 */
+ (nullable STM *)sharedInstance;
+ (nullable STMUser *)currentUser;
+ (nullable Settings *)settings;
+ (nullable UserData *)userData;
+ (nullable Error *)error;
+ (nullable SignIn *)signIn;
+ (nullable STMLocation *)location;
+ (nullable Shout *)shout;
+ (nullable Channels *)channels;
+ (nullable AudioSystem *)audioSystem;
+ (nullable RecordingSystem *)recordingSystem;
+ (nullable Messages *)messages;
+ (nullable Subscriptions *)subscriptions;
+ (nullable Conversations *)conversations;
+ (nullable MonitoredConversations *)monitoredConversations;

@end

#endif
