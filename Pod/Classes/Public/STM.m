//
//  STM.m
//  Pods
//
//  Created by Tyler Clemens on 8/17/15.
//
//

#import "STM.h"
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
#import "STMRecordingOverlayViewController.h"
#import "Server.h"

#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)

static BOOL bInitialized = NO;
static BOOL appIsStarting = NO;

static NSString *const STM_NOTIFICATION_BACKGROUND = @"stm_notification_background";
static NSString *const STM_NOTIFICATION_FOREGROUND = @"stm_notification_foreground";
static NSString *const STM_NOTIFICATION_USER_TAP = @"stm_notification_user_tap";

static NSString *const MESSAGE_CATEGORY = @"MESSAGE_CATEGORY";
static NSString *const COMMAND_CATEGORY = @"COMMAND_CATEGORY";

__strong static STM *singleton = nil; // this will be the one and only object this static singleton class has

@interface STM ()

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

@implementation STM

#pragma mark - Static methods

+ (void)initWithAccessToken:(NSString *)token andApplication:(UIApplication *)application andDelegate:(id)delegate {
    [self initAllWithDelegate:delegate andToken:token];
    //[self setupNotificationsWithApplication:application];
    [self setupLifeCycleEvents];
}

+ (void)initAllWithDelegate:(id<STMDelegate>)delegate andToken:(NSString *)token {
    if (NO == bInitialized)
    {
        [AWSDDLog sharedInstance].logLevel = AWSDDLogLevelWarning;
        
        singleton = [[STM alloc] initWithToken:token];
        singleton.delegate = delegate;
        
        [STMLocation initAll];
        [DL_URLServer initAll];
        [Settings initAll];
        [AudioSystem initAll];
        [UserData initAll];
        [Error initAll];
        [SignIn initAll];
        [Shout initAll];
        [Channels initAll];
        [RecordingSystem initAll];
        [Messages initAll];
        [Subscriptions initAll];
        [Conversations initAll];
        [MonitoredConversations initAll];
        
        // This category is appropriate for simultaneous recording and playback, and also for apps that record and play back but not simultaneously.
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord withOptions:AVAudioSessionCategoryOptionDefaultToSpeaker error:nil];
        
        // Activates your app’s audio session.
        [[AVAudioSession sharedInstance] setActive:YES error:nil];
        
        
        bInitialized = YES;
    }
}

+ (void)freeAll {
    if (YES == bInitialized) {
        [STM saveAll];
        
        [Channels freeAll];
        [Shout freeAll];
        [SignIn freeAll];
        [Error freeAll];
        [UserData freeAll];
        [AudioSystem freeAll];
        [Settings freeAll];
        [DL_URLServer freeAll];
        [STMLocation freeAll];
        [RecordingSystem freeAll];
        [Messages freeAll];
        [Subscriptions freeAll];
        [Conversations freeAll];
        [MonitoredConversations freeAll];
        
        // release our singleton
        singleton = nil;
        
        bInitialized = NO;
    }
}

+ (void)saveAll {
//    [Settings saveAll];
//    [UserData saveAll];
    [RecordingSystem saveAll];
    [MonitoredConversations saveAll];
}


+ (void)setChannelId:(NSString *)channelId {
    [[STM channels] requestForChannel:channelId completionHandler:^(STMChannel *channel, NSError *error) {
        if (!error && channel) {
            [STM sharedInstance].channelId = channel.strID;
            [STM settings].channel.strID = channel.strID;
            [[STM settings] setChannel:[channel copy]];
            [[STM settings] save];
        }
    }];
}

// returns the singleton
// (this call is both a container and an object class and the container holds one of itself)
+ (STM *)sharedInstance {
    return (singleton);
}

#pragma mark - Controllers

+ (Settings *)settings {
    return ([Settings controller]);
}
+ (UserData *)userData {
    return ([UserData controller]);
}
+ (Error *)error {
    return ([Error controller]);
}
+ (SignIn *)signIn {
    return ([SignIn controller]);
}
+ (STMLocation *)location {
    return ([STMLocation controller]);
}
+ (Shout *)shout {
    return ([Shout controller]);
}
+ (Channels *)channels {
    return ([Channels controller]);
}
+ (AudioSystem *)audioSystem {
    return ([AudioSystem controller]);
}
+ (RecordingSystem *)recordingSystem {
    return ([RecordingSystem controller]);
}
+ (Messages *)messages {
    return ([Messages controller]);
}
+ (Subscriptions *)subscriptions {
    return ([Subscriptions controller]);
}
+ (Conversations *)conversations {
    return ([Conversations controller]);
}
+ (MonitoredConversations *)monitoredConversations {
    return ([MonitoredConversations controller]);
}

#pragma mark - Object Methods

- (id)initWithToken:(NSString *)token {
    self = [super init];
    if (self) {
        self.accessToken = token;
    }
    return self;
}

- (void)dealloc {
     [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationDidBecomeActiveNotification object:nil];
}

// overriding the description - used in debugging
- (NSString *)description {
    return(@"STM");
}

#pragma mark - Misc Methods

+ (STMUser *)currentUser {
    if (![[STM userData] isSignedIn]) {
        [[STM userData] signIn];
    }
    return [STM userData].user;
    
}

+ (void)presentRecordingOverlayWithViewController:(UIViewController *)vc andTags:(NSString *)tags andTopic:(NSString *)topic andMaxListeningSeconds:(NSNumber *)maxListeningSeconds andDelegate:(id)delegate andError:(NSError *__autoreleasing *)error {
    
    if ([[vc presentedViewController] isKindOfClass:[STMRecordingOverlayViewController class]])
    {
        [(STMRecordingOverlayViewController *)[vc presentedViewController] userRequestsStopListening];
        return;
    }
    
    STMRecordingOverlayViewController *overlay = [[STMRecordingOverlayViewController alloc] init];
    NSDictionary *userInfo = @{@"error description": @"Unable to record shout, mic permission is not granted."};
    switch ([[AVAudioSession sharedInstance] recordPermission]) {
        case AVAudioSessionRecordPermissionGranted:
            if (tags) {
                overlay.tags = tags;
            }
            if (topic) {
                overlay.topic = topic;
            }
            if (maxListeningSeconds) {
                [overlay setMaxListeningSeconds:[maxListeningSeconds doubleValue]];
            }
            overlay.delegate = delegate;
            [vc presentViewController:overlay animated:YES completion:nil];
            break;
        default:
            *error = [NSError errorWithDomain:ShoutToMeErrorDomain
                                         code:MicPermissionNotGranted
                                     userInfo:userInfo];
            NSLog(@"Mic Permissions required to show Shout to Me Recording Overlay");
            break;
    }
}

- (NSString *)channelId {
    return [STM settings].channel.strID;
}

+ (void)setupLifeCycleEvents {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        appIsStarting = NO;
        [[STM location] syncMonitoredRegions];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        appIsStarting = NO;
        [[STM location] stop];
        [STM saveAll];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        appIsStarting = YES;
        NSError *error;
        [[STM location] startWithError:&error];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [STM saveAll];
        [STM freeAll];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillResignActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        appIsStarting = NO;
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidFinishLaunchingNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        if (note && note.userInfo) {
            NSDictionary *notificationData = [note.userInfo objectForKey:UIApplicationLaunchOptionsRemoteNotificationKey];
            if (notificationData) {
                appIsStarting = YES;
            }
        }
    }];
}

#pragma mark - Life Cycle Events
+ (void) applicationDidBecomeActive {
    
}

#pragma mark - Notification Misc
+ (void)setupNotificationsWithApplication:(UIApplication *)application {
//    application.applicationIconBadgeNumber = 0;
#if !(TARGET_IPHONE_SIMULATOR)
    UIMutableUserNotificationCategory *messageCategory = [[UIMutableUserNotificationCategory alloc] init];
    messageCategory.identifier = @"MESSAGE_CATEGORY";
    
    NSSet *categories = [NSSet setWithObject:messageCategory];
    
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:categories];
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
#endif
}

+ (void)setupPushNotificationsWithAppId:(NSString *)pushNotificationAppId {
    
    singleton.applicationArn = [NSString stringWithFormat:@"%@%@", SERVER_SNS_APPLICATION_ARN_PREFIX, pushNotificationAppId];
//    singleton.applicationArn = [NSString stringWithFormat:@"%@%@", SERVER_SNS_TEST_APPLICATION_ARN_PREFIX, pushNotificationAppId];
}

+ (void)didReceiveRemoteNotification:(NSDictionary *)userInfo ForApplication:(UIApplication *)application fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {

    UIApplicationState applicationState = [application applicationState];
    
    NSLog(@"STM- didReceiveRemoteNotification. userInfo=%@", userInfo);

    NSString *notificationState;
    if (applicationState == UIApplicationStateBackground || (applicationState == UIApplicationStateInactive && !appIsStarting)) {
        // In the background. If conversation has location, treat as geofence. If package has alert, ignore background.
        notificationState = STM_NOTIFICATION_BACKGROUND;
    } else if (applicationState == UIApplicationStateInactive && appIsStarting) {
        // User tapped the remote notificication while app was in background. Transition to message
        notificationState = STM_NOTIFICATION_USER_TAP;
    } else {
        // App is active in foreground. Should we show it?
        notificationState = STM_NOTIFICATION_FOREGROUND;
    }
    NSLog(@"STM- notification state = %@", notificationState);
    
    if (userInfo) {
        NSDictionary *data = [userInfo objectForKey:@"aps"];
        if (data) {
            NSString *notificationCategory = [Utils stringFromKey:@"category" inDictionary:data];
            NSString *notificationType = [Utils stringFromKey:@"type" inDictionary:data];
            
            if ([MESSAGE_CATEGORY isEqual:notificationCategory]) {
                if ([STM_NOTIFICATION_FOREGROUND isEqual:notificationState] || [STM_NOTIFICATION_USER_TAP isEqual:notificationState]) {
                    if (notificationType && [notificationType isEqual:@"user message"]) {
                        NSLog(@"STM- User direct message. About to notify client");
                        [STM broadcastSTMNotifications:[NSSet setWithObject:data]];
                        completionHandler(UIBackgroundFetchResultNewData);
                    } else if (notificationType && [notificationType isEqual:@"conversation message"]) {
                        NSString *conversationId = [Utils stringFromKey:@"conversation_id" inDictionary:data];
                        
                        NSLog(@"STM- Processing conversation notification for conversation: %@. About to see if converation has been seen.", conversationId);
                        
                        // check if conversation has been heard before
                        [[STM conversations] requestForSeenConversation:conversationId completionHandler:^(BOOL seen, NSError *error) {
                            NSLog(@"STM- Conversation been seen: %@. If false, show channel wide message.", seen == YES ? @"True" : @"False");
                            if (!seen) {
                                NSLog(@"STM- Channel wide message received. Prepare to show notification to user.");
                                // this is a channel wide notification, create local notification
                                [[STM messages] requestForCreateMessageForChannelId:[Utils stringFromKey:@"channel_id" inDictionary:data] ToRecipientId:[STM currentUser].strUserID WithConversationId:[Utils stringFromKey:@"conversation_id" inDictionary:data] AndMessage:[Utils stringFromKey:@"body" inDictionary:data] completionHandler:^(STMMessage *message, NSError *error) {
                                    
                                    NSLog(@"STM- Created a message at the server. Data: %@", message);
                                    if (error) {
                                        NSLog(@"STM- Error received creating message. Error: %@", error);
                                    }
                                    NSMutableDictionary *messageData = [data mutableCopy];
                                    [messageData setValue:message.strID forKey:@"message_id"];
                                    [STM broadcastSTMNotifications:[NSSet setWithObject:messageData]];
                                    completionHandler(UIBackgroundFetchResultNewData);
                                }];
                            } else {
                                // we have seen this conversation before
                                NSLog(@"STM- Conversation has been seen before");
                                completionHandler(UIBackgroundFetchResultNewData);
                            }
                        }];
                    } else {
                       completionHandler(UIBackgroundFetchResultNoData);
                    }
                } else {
                    completionHandler(UIBackgroundFetchResultNoData);
                }
            } else if ([COMMAND_CATEGORY isEqual:notificationCategory]) {
                NSLog(@"STM- Notification sync command received. About to begin syncing messages and notifications");
                [[STM location] syncMonitoredRegionsWithCompletionHandler:^void (void){
                    NSLog(@"STM- Done syncing messages and geofences");
                    if ([[[STM monitoredConversations] monitoredConversations] count ] > 0) {
                        completionHandler(UIBackgroundFetchResultNewData);
                    } else {
                        completionHandler(UIBackgroundFetchResultNoData);
                    }
                }];
            } else {
                completionHandler(UIBackgroundFetchResultNoData);
            }
        } else {
            completionHandler(UIBackgroundFetchResultNoData);
        }
    } else {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}

+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *deviceTokenString = [[[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    NSLog(@"STM- device token string = %@", deviceTokenString);
    
    if (!singleton.applicationArn) {
        NSLog(@"Warning. You must call setupPushNotificationsWithAppId: before registering for notifications");
    }

    singleton.task = [AWSTask taskWithResult:nil];
    
    // if (the platform endpoint ARN is not stored)
    NSLog(@"%@", [[STM currentUser] strPlatformEndpointArn]);
    if ([[[STM currentUser] strPlatformEndpointArn] length] < 1) {
        NSLog(@"STM- strPlatformEndpointArn is null, going to create one");
        // this is a first-time registration
        // call create platform endpoint
        // store the returned platform endpoint ARN
        singleton.task = [self createPlatformEndpointWithDeviceToken:deviceTokenString];
    }
    
    [singleton.task continueWithBlock:^id(AWSTask *task) {
        [[[self getEndpointAttributes]continueWithSuccessBlock:^id(AWSTask *task) {
            NSLog(@"STM- got endpoint attributes with success %@", task);
            return task;
        }]continueWithBlock:^id _Nullable(AWSTask * task) {
            if ([task.error code] == AWSSNSErrorNotFound) {
                NSLog(@"STM- task error code = AWSSNSErrorNotFound. going to create new platform endpoint arn again");
                return [self createPlatformEndpointWithDeviceToken:deviceTokenString];
            } else {
                AWSSNSGetEndpointAttributesResponse *getEndpointAttributesResponse = task.result;
                NSLog(@"STM- endpoint attributes response = %@", getEndpointAttributesResponse.attributes);
                BOOL enabled = [Utils boolFromKey:@"Enabled" inDictionary:getEndpointAttributesResponse.attributes];
                NSString *token = [getEndpointAttributesResponse.attributes objectForKey:@"Token"];
                
                BOOL userDataIsDirty = YES;
                NSString *userData = [getEndpointAttributesResponse.attributes objectForKey:@"CustomUserData"];
                if (userData) {
                    userDataIsDirty = ![userData isEqualToString:[self buildSNSEndpointUserDataString]];
                }
                
                if (![token isEqualToString:deviceTokenString] || !enabled || userDataIsDirty) {
                    // call set endpoint attributes to set the latest device token and then enable the platform endpoint
                    NSLog(@"STM- Attributes do not match. Update them now");
                    [self updateEndpointAttributesWithEndpointArn:[[STM currentUser] strPlatformEndpointArn] AndToken:deviceTokenString];
                }
            }
            return nil;
        }];
        return nil;
    }];

}

+ (void)broadcastSTMNotifications:(NSSet *)notifications {
    if ([singleton.delegate respondsToSelector:@selector(STMNotificationsReceived:)]) {
        [singleton.delegate STMNotificationsReceived:notifications];
    }
}

#pragma mark - AWS Calls

+ (AWSTask *)updateEndpointAttributesWithEndpointArn:(NSString *) endpointArn AndToken:(NSString *)token {

    AWSSNS *sns = [AWSSNS defaultSNS];
    AWSSNSSetEndpointAttributesInput *request = [AWSSNSSetEndpointAttributesInput new];
    request.endpointArn = endpointArn;
    request.attributes =@{@"Enabled": @"True", @"Token": token, @"CustomUserData": [self buildSNSEndpointUserDataString]};
    
    return [[sns setEndpointAttributes:request] continueWithBlock:^id(AWSTask *task) {
        if (task.error != nil) {
            NSLog(@"STM- setEndpointAttributes Error: %@", [task.error description]);
            STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Failed to update platform endpoint attributes with AWS SNS.", @"SNS setEndpointAttributes failed.", endpointArn, nil, [task.error localizedDescription]);
            return nil;
        } else {
            NSLog(@"STM- Updated PlatformEndpoint Attributes");
            return nil;
        }
    }];
}

+ (NSString *)buildSNSEndpointUserDataString {
    NSString *userHandle = [[[STM currentUser].strHandle stringByReplacingOccurrencesOfString:@"\"" withString:@"_"] stringByReplacingOccurrencesOfString:@"\\" withString:@"_"];
    NSString *userDataString = [NSString stringWithFormat:@"{ \"user_handle\": \"%@\", \"user_id\": \"%@\" }", userHandle, [STM currentUser].strUserID];
    return userDataString;
}

+ (AWSTask *)getEndpointAttributes {
    AWSSNS *sns = [AWSSNS defaultSNS];
    AWSSNSGetEndpointAttributesInput *request = [AWSSNSGetEndpointAttributesInput new];
    request.endpointArn = [[STM currentUser] strPlatformEndpointArn];
    return [sns getEndpointAttributes:request];
}

+ (AWSTask *)setPlatformEndpointArn:(NSString *)platformEndpointArn {
    AWSTaskCompletionSource *task = [AWSTaskCompletionSource taskCompletionSource];
    if ([[STM signIn] respondsToSelector:@selector(setPlatformEndpointArn:withCompletionHandler:)]) {
        [[STM signIn] setPlatformEndpointArn:platformEndpointArn withCompletionHandler:^(NSError *error) {
            if (error) {
                NSLog(@"Error setting platformendpoint: %@", [error description]);
                STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Failed to set platform endpoint on STM User.", @"[STM signIn] setPlatformEndpoint failed.", nil, nil, [error localizedDescription]);
                [task setError:error];
            } else {
                NSLog(@"Updated User's PlatformEndpoint");
                [task setResult:nil];
            }
        }];
    }
    return task.task;
}
+ (AWSTask *)createPlatformEndpointWithDeviceToken:(NSString *)token {
    NSLog(@"STM- Going to create platform endpoint arn with application %@", singleton.applicationArn);
    NSString *userHandle = [[[STM currentUser].strHandle stringByReplacingOccurrencesOfString:@"\"" withString:@"_"] stringByReplacingOccurrencesOfString:@"\\" withString:@"_"];
    AWSSNS *sns = [AWSSNS defaultSNS];
    AWSSNSCreatePlatformEndpointInput *request = [AWSSNSCreatePlatformEndpointInput new];
    request.token = token;
    request.platformApplicationArn = singleton.applicationArn;
    request.customUserData = [NSString stringWithFormat:@"{ \"user_handle\": \"%@\", \"user_id\": \"%@\" }", userHandle, [STM currentUser].strUserID];
    return [[sns createPlatformEndpoint:request] continueWithBlock:^id(AWSTask *task) {
        if (task.error != nil) {
            NSLog(@"Error: %@",task.error);
            STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Failed to create platform endpoint with AWS SNS.", @"SNS createPlatformEndpoint failed.", singleton.applicationArn, request, [task.error localizedDescription]);
            return task;
        } else {
            AWSSNSCreateEndpointResponse *createEndPointResponse = task.result;
            NSLog(@"STM- Successfully registered for platform endpoint arn = %@", createEndPointResponse.endpointArn);
            return [self setPlatformEndpointArn:createEndPointResponse.endpointArn];
        }
        
    }];
}


@end
