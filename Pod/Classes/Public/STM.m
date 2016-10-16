//
//  STM.m
//  Pods
//
//  Created by Tyler Clemens on 8/17/15.
//
//

#import "STM.h"

static BOOL bInitialized = NO;

__strong static STM *singleton = nil; // this will be the one and only object this static singleton class has

@interface STM ()
@property (nonatomic, strong) NSString *authKey;

@end

@implementation STM

#pragma mark - Static methods

+ (void)initWithAccessToken:(NSString *)token {
    [self initAllWithDelegate:nil andToken:token];
}

+ (void)initAllWithDelegate:(id<STMSignInDelegate>)delegate andToken:(NSString *)token {
    if (NO == bInitialized)
    {
        singleton = [[STM alloc] initWithToken:token];
        
        [STMLocation initAll];
        [DL_URLServer initAll];
        [Settings initAll];
        [AudioSystem initAll];
        [UserData initAll];
        [Error initAll];
        [SignIn initAll];
        [SendShout initAll];
        [Channels initAll];
        [RecordingSystem initAll];
        [Messages initAll];
        [Subscriptions initAll];
        [Conversations initAll];
        [STMGeofenceLocationManager initAll];
        [MonitoredConversations initAll];
        bInitialized = YES;
    }
}

+ (void)freeAll {
    if (YES == bInitialized) {
        [STM saveAll];
        
        [Channels freeAll];
        [SendShout freeAll];
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
        [STMGeofenceLocationManager freeAll];
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
+ (SendShout *)sendShout {
    return ([SendShout controller]);
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
+ (STMGeofenceLocationManager *)stmGeofenceLocationManager {
    return ([STMGeofenceLocationManager controller]);
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
}

// overriding the description - used in debugging
- (NSString *)description {
    return(@"STM");
}

#pragma mark - Misc Methods

+ (User *)currentUser {
    if (![[STM userData] isSignedIn]) {
        [[STM userData] signIn];
    }
    return [STM userData].user;
    
}

- (NSString *)channelId {
    return [STM settings].channel.strID;
}

@end
