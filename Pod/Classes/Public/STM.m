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
#import "SignIn.h"
#import "Utils.h"
#import "STMLocation.h"
#import "Shout.h"
#import "Channels.h"
#import "UserData.h"
#import "AudioSystem.h"
#import "RecordingSystem.h"
#import "Messages.h"
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

static NSString *const MESSAGE_CATEGORY = @"SHOUTTOME_MESSAGE";

__strong static STM *singleton = nil; // this will be the one and only object this static singleton class has

@interface STM ()

+ (STMUser *)currentUser;
+ (Settings *)settings;
+ (User *)user;
+ (UserData *)userData;
+ (STMError *)error;
+ (SignIn *)signIn;
+ (STMLocation *)location;
+ (Shout *)shout;
+ (Channels *)channels;
+ (AudioSystem *)audioSystem;
+ (RecordingSystem *)recordingSystem;
+ (Messages *)messages;
+ (Conversations *)conversations;
+ (MonitoredConversations *)monitoredConversations;

@end

@implementation STM

#pragma mark - Static methods

+ (void)initWithAccessToken:(NSString *)token andApplication:(UIApplication *)application andDelegate:(id)delegate {
    [self initAllWithDelegate:delegate andToken:token];
    //[self setupNotificationsWithApplication:application];
    [self setupLifeCycleEvents];
    [self initializeAWSServices];
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
        [User initAll];
        [UserData initAll];
        [STMError initAll];
        [SignIn initAll];
        [Shout initAll];
        [Channels initAll];
        [RecordingSystem initAll];
        [Messages initAll];
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
        [STMError freeAll];
        [User freeAll];
        [UserData freeAll];
        [AudioSystem freeAll];
        [Settings freeAll];
        [DL_URLServer freeAll];
        [STMLocation freeAll];
        [RecordingSystem freeAll];
        [Messages freeAll];
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
+ (User *)user {
    return ([User controller]);
}
+ (UserData *)userData {
    return ([UserData controller]);
}
+ (STMError *)error {
    return ([STMError controller]);
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
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        appIsStarting = NO;
        [STM saveAll];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        appIsStarting = YES;
        [[STM location] processGeofenceUpdate];
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
+ (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(nonnull NSString *)identifier completionHandler:(nonnull void (^)(void))completionHandler
{
    [STMNetworking handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
    
    [AWSS3TransferUtility interceptApplication:application
           handleEventsForBackgroundURLSession:identifier
                             completionHandler:completionHandler];
}

#pragma mark - Notification Misc
+ (void)setupNotificationsWithApplication:(UIApplication *)application {
//    application.applicationIconBadgeNumber = 0;
#if !(TARGET_IPHONE_SIMULATOR)
    UIMutableUserNotificationCategory *messageCategory = [[UIMutableUserNotificationCategory alloc] init];
    messageCategory.identifier = MESSAGE_CATEGORY;
    
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

    if (!userInfo) {
        return completionHandler(UIBackgroundFetchResultNoData);
    }
    
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
    
    NSDictionary *data = [userInfo objectForKey:STM_APS_ROOT_KEY];
    if (!data) {
        return completionHandler(UIBackgroundFetchResultNoData);
    }
    
    NSString *notificationCategory = [Utils stringFromKey:STM_APS_CATEGORY_KEY inDictionary:data];
    if ([MESSAGE_CATEGORY isEqual:notificationCategory]) {
        if ([STM_NOTIFICATION_FOREGROUND isEqual:notificationState] || [STM_NOTIFICATION_USER_TAP isEqual:notificationState]) {
            NSLog(@"STM- Message received while app active. About to notify client");
            [STM broadcastSTMNotifications:[NSSet setWithObject:data]];
            completionHandler(UIBackgroundFetchResultNewData);
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
    
    if (singleton.task) {
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

}

+ (void)broadcastSTMNotifications:(NSSet *)notifications {
    if ([singleton.delegate respondsToSelector:@selector(STMNotificationsReceived:)]) {
        [singleton.delegate STMNotificationsReceived:notifications];
    }
}

#pragma mark - AWS Calls

+ (void)initializeAWSServices
{
    AWSCognitoCredentialsProvider *credentialsProvider = [[AWSCognitoCredentialsProvider alloc] initWithRegionType:AWSRegionUSEast1
                                                                                                    identityPoolId:SERVER_AWS_COGNITO_POOL_ID];
    AWSServiceConfiguration *configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest1
                                                                         credentialsProvider:credentialsProvider];
    [AWSServiceManager defaultServiceManager].defaultServiceConfiguration = configuration;
    
    
    AWSServiceConfiguration *s3Configuration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest2
                                                                           credentialsProvider:credentialsProvider];
    [AWSS3TransferUtility registerS3TransferUtilityWithConfiguration:s3Configuration forKey:SERVER_AWS_S3_CONFIGURATION_KEY];
    
    AWSServiceConfiguration *snsConfiguration = [[AWSServiceConfiguration alloc] initWithRegion:AWSRegionUSWest2 credentialsProvider:credentialsProvider];
    [AWSSNS registerSNSWithConfiguration:snsConfiguration forKey:SERVER_AWS_SNS_CONFIGURATION_KEY];
}

+ (AWSTask *)updateEndpointAttributesWithEndpointArn:(NSString *) endpointArn AndToken:(NSString *)token {

    AWSSNS *sns = [AWSSNS SNSForKey:SERVER_AWS_SNS_CONFIGURATION_KEY];
    if (sns) {
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
                [[self user] enableNotifications];
                return nil;
            }
        }];
    } else {
        NSLog(@"Could not get Shout to Me SNS object");
        return nil;
    }
}

+ (NSString *)buildSNSEndpointUserDataString {
    NSString *userHandle = [[[STM currentUser].strHandle stringByReplacingOccurrencesOfString:@"\"" withString:@"_"] stringByReplacingOccurrencesOfString:@"\\" withString:@"_"];
    NSString *userDataString = [NSString stringWithFormat:@"{ \"user_handle\": \"%@\", \"user_id\": \"%@\" }", userHandle, [STM currentUser].strUserID];
    return userDataString;
}

+ (AWSTask *)getEndpointAttributes {
    AWSSNS *sns = [AWSSNS SNSForKey:SERVER_AWS_SNS_CONFIGURATION_KEY];
    if (sns) {
        AWSSNSGetEndpointAttributesInput *request = [AWSSNSGetEndpointAttributesInput new];
        request.endpointArn = [[STM currentUser] strPlatformEndpointArn];
        return [sns getEndpointAttributes:request];
    } else {
        NSLog(@"Could not get Shout to Me SNS object");
        return nil;
    }
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
    
    AWSSNS *sns = [AWSSNS SNSForKey:SERVER_AWS_SNS_CONFIGURATION_KEY];
    if (sns) {
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
    } else {
        NSLog(@"Could not get Shout to Me SNS object");
        return nil;
    }
}

@end
