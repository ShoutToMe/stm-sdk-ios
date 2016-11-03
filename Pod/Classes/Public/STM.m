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

static BOOL bInitialized = NO;

__strong static STM *singleton = nil; // this will be the one and only object this static singleton class has

//static NSString *const SNSPlatformApplicationArn = @"arn:aws:sns:us-west-2:810633828709:app/APNS_SANDBOX/voigo-test";
static NSString *const SNSPlatformApplicationArn = @"arn:aws:sns:us-west-2:810633828709:app/APNS/voigo";

@interface STM ()
@property (nonatomic, strong) NSString *authKey;

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
        [AWSLogger defaultLogger].logLevel = AWSLogLevelWarn;
        
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
                overlay.maxListeningSeconds = [maxListeningSeconds doubleValue];
            }
            overlay.delegate = delegate;
            [vc presentViewController:overlay animated:YES completion:nil];
            
            break;
        //case AVAudioSessionRecordPermissionDenied:
            
          //  break;
        //case AVAudioSessionRecordPermissionUndetermined:
            // This is the initial state before a user has made any choice
            // You can use this spot to request permission here if you want
          //  break;
        default:
            *error = [NSError errorWithDomain:ShoutToMeErrorDomain
                                         code:MicPermissionNotGranted
                                     userInfo:userInfo];
            NSLog(@"Mic Permissions required to show Shout to Me Recording Overlay");
            break;
    }
    /*
    if ([[AVAudioSession sharedInstance] respondsToSelector:@selector(requestRecordPermission:)]) {
        [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
            if (granted) {
                STMRecordingOverlayViewController *overlay = [[STMRecordingOverlayViewController alloc] init];
                if (tags) {
                    overlay.tags = tags;
                }
                if (topic) {
                    overlay.topic = topic;
                }
                if (maxListeningSeconds) {
                    overlay.maxListeningSeconds = [maxListeningSeconds doubleValue];
                }
                overlay.delegate = delegate;
                [vc presentViewController:overlay animated:YES completion:nil];
            } else {
                NSDictionary *userInfo = @{@"error description": @"Unable to record shout, mic permission is not granted."};
                
                *error = [NSError errorWithDomain:ShoutToMeErrorDomain
                                             code:MicPermissionNotGranted
                                         userInfo:userInfo];
                NSLog(@"Mic Permissions required to show Shout to Me Recording Overlay");
            }
        }];
    }
     */
}

- (NSString *)channelId {
    return [STM settings].channel.strID;
}

+ (void)setupLifeCycleEvents {
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidBecomeActiveNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [[STM location] syncMonitoredRegions];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationDidEnterBackgroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [[STM location] stop];
        [STM saveAll];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillEnterForegroundNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [[STM location] start];
    }];
    
    [[NSNotificationCenter defaultCenter] addObserverForName:UIApplicationWillTerminateNotification object:nil queue:[NSOperationQueue mainQueue] usingBlock:^(NSNotification * _Nonnull note) {
        [STM saveAll];
        [STM freeAll];
    }];
        
}

#pragma mark - Life Cycle Events
+ (void) applicationDidBecomeActive {
    
}

#pragma mark - Notification Misc
+ (void)setupNotificationsWithApplication:(UIApplication *)application {
//    application.applicationIconBadgeNumber = 0;
    
    UIMutableUserNotificationCategory *messageCategory = [[UIMutableUserNotificationCategory alloc] init];
    messageCategory.identifier = @"MESSAGE_CATEGORY";
    
    NSSet *categories = [NSSet setWithObject:messageCategory];
    
    UIUserNotificationType types = UIUserNotificationTypeBadge | UIUserNotificationTypeSound | UIUserNotificationTypeAlert;
    UIUserNotificationSettings *mySettings = [UIUserNotificationSettings settingsForTypes:types categories:categories];
    
    [[UIApplication sharedApplication] registerForRemoteNotifications];
    [[UIApplication sharedApplication] registerUserNotificationSettings:mySettings];
}

+ (void)didReceiveRemoteNotification:(NSDictionary *)userInfo ForApplication:(UIApplication *)application fetchCompletionHandler:(void (^)(UIBackgroundFetchResult))completionHandler {
    if (userInfo) {
        NSDictionary *data = [userInfo objectForKey:@"aps"];
        
        NSString *messageType = [Utils stringFromKey:@"type" inDictionary:data];
        NSLog(@"application.applicationState: %ld", (long)application.applicationState);
        if ([messageType isEqualToString:@"conversation message"]) {
            NSString *conversationId = [Utils stringFromKey:@"conversation_id" inDictionary:data];
            
            // check if conversation has been heard before
            [[STM conversations] requestForSeenConversation:conversationId completionHandler:^(BOOL seen, NSError *error) {
//                NSLog(@"Seen: %@", seen == YES ? @"True" : @"False");
                if (!seen) {
                    // We have not seen this conversation message before, go get the conversation
                    [[STM conversations] requestForConversation:conversationId completionHandler:^(STMConversation *conversation, NSError *error) {
                        if (conversation.location && conversation.location.lat && conversation.location.lon && conversation.location.radius_in_meters) {
                            // it has a location, it's a specific location shout so create a geofence
                            
                            CLLocationCoordinate2D center = CLLocationCoordinate2DMake(conversation.location.lat,
                                                                                       conversation.location.lon);
                            CLCircularRegion *conversation_region = [[CLCircularRegion alloc]initWithCenter:center
                                                                                                     radius:conversation.location.radius_in_meters
                                                                                                 identifier:conversation.str_id];
                            
                            if ([conversation_region containsCoordinate:[STMLocation controller].curLocation.coordinate]) {
                                // we are within the region, skip geo fence and show message
                                [[STM messages] requestForCreateMessageForChannelId:[Utils stringFromKey:@"channel_id" inDictionary:data] ToRecipientId:[STM currentUser].strUserID WithConversationId:[Utils stringFromKey:@"conversation_id" inDictionary:data] AndMessage:[Utils stringFromKey:@"body" inDictionary:data] completionHandler:^(STMMessage *message, NSError *error) {
                                    NSMutableDictionary *messageData = [data mutableCopy];
                                    [messageData setValue:message.strID forKey:@"message_id"];
                                    
                                    if ([singleton.delegate respondsToSelector:@selector(STMNotificationRecieved:)])
                                    {
                                        [singleton.delegate STMNotificationRecieved:messageData];
                                    }
    
                                    completionHandler(UIBackgroundFetchResultNewData);
                                }];
                            } else {
                                // we are not in the same location, create a geo fence
                                [[STM location] startMonitoringForRegion:conversation_region];
                                completionHandler(UIBackgroundFetchResultNewData);
                            }
                        } else {
                            // this is a channel wide notification, create local notification
                            [[STM messages] requestForCreateMessageForChannelId:[Utils stringFromKey:@"channel_id" inDictionary:data] ToRecipientId:[STM currentUser].strUserID WithConversationId:[Utils stringFromKey:@"conversation_id" inDictionary:data] AndMessage:[Utils stringFromKey:@"body" inDictionary:data] completionHandler:^(STMMessage *message, NSError *error) {
                                
                                NSLog(@"Created Message: %@", message);
                                NSMutableDictionary *messageData = [data mutableCopy];
                                [messageData setValue:message.strID forKey:@"message_id"];
                                
                                if ([singleton.delegate respondsToSelector:@selector(STMNotificationRecieved:)])
                                {
                                    [singleton.delegate STMNotificationRecieved:messageData];
                                }
                                completionHandler(UIBackgroundFetchResultNewData);
                            }];
                        }
                    }];
                } else {
                    // we have seen this conversation before, updated?
                    completionHandler(UIBackgroundFetchResultNewData);
                }
                
            }];
        } else if ([messageType isEqualToString:@"user message"]) {
            
            if ([singleton.delegate respondsToSelector:@selector(STMNotificationRecieved:)])
            {
                [singleton.delegate STMNotificationRecieved:data];
            }
            completionHandler(UIBackgroundFetchResultNewData);
        }
    } else {
        completionHandler(UIBackgroundFetchResultNoData);
    }
}
+ (void)didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken {
    NSString *deviceTokenString = [[[deviceToken description] stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"<>"]] stringByReplacingOccurrencesOfString:@" " withString:@""];
    
    singleton.task = [AWSTask taskWithResult:nil];
    
    // if (the platform endpoint ARN is not stored)
    if ([[[STM currentUser] strPlatformEndpointArn] length] < 1) {
        // this is a first-time registration
        // call create platform endpoint
        // store the returned platform endpoint ARN
        singleton.task = [self createPlatformEndpointWithDeviceToken:deviceTokenString];
    }
    
    [singleton.task continueWithBlock:^id(AWSTask *task) {
        [[[self getEndpointAttributes]continueWithSuccessBlock:^id(AWSTask *task) {
            return task;
        }]continueWithBlock:^id _Nullable(AWSTask * task) {
            if ([task.error code] == AWSSNSErrorNotFound) {
                return [self createPlatformEndpointWithDeviceToken:deviceTokenString];
            } else {
                AWSSNSGetEndpointAttributesResponse *getEndpointAttributesResponse = task.result;
                BOOL enabled = [Utils boolFromKey:@"Enabled" inDictionary:getEndpointAttributesResponse.attributes];
                NSString *token = [getEndpointAttributesResponse.attributes objectForKey:@"Token"];
                if (![token isEqualToString:deviceTokenString] || !enabled) {
                    // call set endpoint attributes to set the latest device token and then enable the platform endpoint
                    [self updateEndpointAttributesWithEndpointArn:[[STM currentUser] strPlatformEndpointArn] AndToken:deviceTokenString];
                }
            }
            return nil;
        }];
        return nil;
    }];

}

#pragma mark - AWS Calls

+ (AWSTask *)updateEndpointAttributesWithEndpointArn:(NSString *) endpointArn AndToken:(NSString *)token {
    AWSSNS *sns = [AWSSNS defaultSNS];
    AWSSNSSetEndpointAttributesInput *request = [AWSSNSSetEndpointAttributesInput new];
    request.endpointArn = endpointArn;
    request.attributes =@{@"Enabled": @"True", @"Token": token, @"CustomUserData": [NSString stringWithFormat:@"UserHandle: %@", [STM currentUser].strHandle]};
    
    return [[sns setEndpointAttributes:request] continueWithBlock:^id(AWSTask *task) {
        if (task.error != nil) {
            NSLog(@"setEndpointAttributes Error: %@", [task.error description]);
            return nil;
        } else {
            NSLog(@"Updated PlatformEndpoint Attributes");
            return nil;
        }
    }];
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
    AWSSNS *sns = [AWSSNS defaultSNS];
    AWSSNSCreatePlatformEndpointInput *request = [AWSSNSCreatePlatformEndpointInput new];
    request.token = token;
    request.platformApplicationArn = SNSPlatformApplicationArn;
    request.customUserData = [NSString stringWithFormat:@"UserHandle: %@", [STM currentUser].strHandle];
    return [[sns createPlatformEndpoint:request] continueWithBlock:^id(AWSTask *task) {
        if (task.error != nil) {
            NSLog(@"Error: %@",task.error);
            return task;
        } else {
            AWSSNSCreateEndpointResponse *createEndPointResponse = task.result;
            return [self setPlatformEndpointArn:createEndPointResponse.endpointArn];
        }
        
    }];
}


@end
