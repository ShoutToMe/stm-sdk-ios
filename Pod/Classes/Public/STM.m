//
//  STM.m
//  Pods
//
//  Created by Tyler Clemens on 8/17/15.
//
//

#import "DL_URLServer.h"
#import "STM.h"
#import "Server.h"

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
//#import "Channels.h"
#import "UserData.h"
#import "AudioSystem.h"
#import "RecordingSystem.h"
#import "Messages.h"
#import "Subscriptions.h"

static BOOL bInitialized = NO;

__strong static STM *singleton = nil; // this will be the one and only object this static singleton class has

@interface STM ()
@property (nonatomic, strong) NSString *authKey;

@end

@implementation STM

#pragma mark - Static methods

//+ (void)initAll
//{
//    [STM initAllWithDelegate:nil];
//}

+ (void)initWithAccessToken:(NSString *)token {
    [self initAllWithDelegate:nil andToken:token];
}

+ (void)initAllWithDelegate:(id<STMSignInDelegate>)delegate andToken:(NSString *)token
{
    if (NO == bInitialized)
    {
        singleton = [[STM alloc] initWithToken:token];
//        singleton.delegate = delegate;
        
        [STMLocation initAll];
        
        [DL_URLServer initAll];
        
        [Settings initAll];
        
        [AudioSystem initAll];
        
        [UserData initAll];
        
        //[Market initAll];
        
        //[VoiceCmd initAll];
        
        [Error initAll];
        
        //[Analytics initAll];
        
        [SignIn initAll];
        
        [SendShout initAll];
        
        //[ShoutFeed initAll];
        
        [ShoutPlayer initAll];
        
        //[Conversations initAll];
        
        [Channels initAll];
        
        [RecordingSystem initAll];
        
        [Messages initAll];
        
        [Subscriptions initAll];
        
        bInitialized = YES;
    }
    if (![[STM signIn] isSignedIn]) {
        //[[self signIn] signInAnonymousWithDelegate:delegate];
    }
}

+ (void)freeAll
{
    if (YES == bInitialized)
    {
        [STM saveAll];
        
        [Channels freeAll];
//        [Conversations freeAll];
        [ShoutPlayer freeAll];
//        [ShoutFeed freeAll];
        [SendShout freeAll];
        [SignIn freeAll];
//        [Analytics freeAll];
        [Error freeAll];
//        [VoiceCmd freeAll];
//        [Market freeAll];
        [UserData freeAll];
        [AudioSystem freeAll];
        [Settings freeAll];
        [DL_URLServer freeAll];
        [STMLocation freeAll];
        [RecordingSystem freeAll];
        
        [Messages freeAll];
        [Subscriptions freeAll];
        
        // release our singleton
        singleton = nil;
        
        bInitialized = NO;
    }
}

+ (void)saveAll
{
//    [Settings saveAll];
//    [UserData saveAll];
    [RecordingSystem saveAll];
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
+ (STM *)sharedInstance
{
//    if (singleton == nil)
//    {
//        [self initAll];
//    }
    
    return (singleton);
}

+ (User *)currentUser {
    if (![[STM userData] isSignedIn]) {
        [[STM userData] signIn];
    }
    return [STM userData].user;
    
}

+ (Settings *)settings
{
//    if (NO == bInitialized)
//    {
//        [self initAll];
//    }
    
    return ([Settings controller]);
}

+ (UserData *)userData
{
//    if (NO == bInitialized)
//    {
//        [self initAll];
//    }
    
    return ([UserData controller]);
}

+ (Error *)error
{
//    if (NO == bInitialized)
//    {
//        [self initAll];
//    }
    
    return ([Error controller]);
}

+ (SignIn *)signIn
{
//    if (NO == bInitialized)
//    {
//        [self initAll];
//    }
    
    return ([SignIn controller]);
}

//+ (VoiceCmd *)voiceCmd
//{
//    if (NO == bInitialized)
//    {
//        [self initAll];
//    }
//    
//    return ([VoiceCmd controller]);
//}
//
+ (STMLocation *)location
{
//    if (NO == bInitialized)
//    {
//        [self initAll];
//    }
    
    return ([STMLocation controller]);
}
//
+ (SendShout *)sendShout
{
//    if (NO == bInitialized)
//    {
//        [self initAll];
//    }
    
    return ([SendShout controller]);
}
//
//+ (ShoutFeed *)shoutFeed
//{
//    if (NO == bInitialized)
//    {
//        [self initAll];
//    }
//    
//    return ([ShoutFeed controller]);
//}
//
+ (ShoutPlayer *)shoutPlayer
{
//    if (NO == bInitialized)
//    {
//        [self initAll];
//    }
    
    return ([ShoutPlayer controller]);
}
//
//+ (Conversations *)conversations
//{
//    if (NO == bInitialized)
//    {
//        [self initAll];
//    }
//    
//    return ([Conversations controller]);
//}
//
//+ (Analytics *)analytics
//{
//    if (NO == bInitialized)
//    {
//        [self initAll];
//    }
//    
//    return ([Analytics controller]);
//}
//
//+ (Market *)market
//{
//    if (NO == bInitialized)
//    {
//        [self initAll];
//    }
//    
//    return ([Market controller]);
//}
//
+ (Channels *)channels
{
//    if (NO == bInitialized)
//    {
//        [self initAll];
//    }
    
    return ([Channels controller]);
}

+ (AudioSystem *)audioSystem
{
//    if (NO == bInitialized)
//    {
//        [self initAll];
//    }
    
    return ([AudioSystem controller]);
}

+ (RecordingSystem *)recordingSystem
{
//    if (NO == bInitialized)
//    {
//        [self initAll];
//    }
    
    return ([RecordingSystem controller]);
}

+ (Messages *)messages
{
    return ([Messages controller]);
}

+ (Subscriptions *)subscriptions
{
    return ([Subscriptions controller]);
}

//+ (tSTMInternalURLType)urlType:(NSString *)strURL
//{
//    tSTMInternalURLType type = STMInternalURLType_None;
//    
//    if ([strURL hasPrefix:SERVER_URL_PREFIX_PLAY_SHOUT])
//    {
//        type = STMInternalURLType_PlayShout;
//    }
//    else if ([strURL hasPrefix:SERVER_URL_PREFIX_EXIT])
//    {
//        type = STMInternalURLType_Exit;
//    }
//    else if ([strURL hasPrefix:SERVER_URL_PREFIX_AUTO_PLAY_SHOUTS])
//    {
//        type = STMInternalURLType_AutoPlayShouts;
//    }
//    else if ([strURL hasPrefix:SERVER_URL_PREFIX_CONVERSATION_MUTED])
//    {
//        type = STMInternalURLType_Muted;
//    }
//    else if ([strURL hasPrefix:SERVER_URL_PREFIX_CONVERSATION_UNMUTED])
//    {
//        type = STMInternalURLType_Unmuted;
//    }
//    else if ([strURL hasPrefix:SERVER_URL_PREFIX_VERIFY])
//    {
//        type = STMInternalURLType_VerifyAccount;
//    }
//    else if ([strURL hasPrefix:SERVER_URL_PREFIX_SIGNOUT])
//    {
//        type = STMInternalURLType_SignOut;
//    }
//    else if ([strURL hasPrefix:SERVER_URL_PREFIX_DELETE])
//    {
//        type = STMInternalURLType_DeleteAccount;
//    }
//    else if ([strURL hasPrefix:SERVER_URL_PREFIX_STATS_DAY])
//    {
//        type = STMInternalURLType_StatsDay;
//    }
//    else if ([strURL hasPrefix:SERVER_URL_PREFIX_STATS_WEEK])
//    {
//        type = STMInternalURLType_StatsWeek;
//    }
//    else if ([strURL hasPrefix:SERVER_URL_PREFIX_STATS_MONTH])
//    {
//        type = STMInternalURLType_StatsMonth;
//    }
//    else if ([strURL hasPrefix:SERVER_URL_PREFIX_STATS_YEAR])
//    {
//        type = STMInternalURLType_StatsYear;
//    }
//    
//    return type;
//}

+ (BOOL)stringIsSet:(NSString *)strString
{
    return [Utils stringIsSet:strString];
}

#pragma mark - Object Methods

- (id)initWithToken:(NSString *)token {
    self = [super init];
    if (self) {
        self.accessToken = token;
    }
    return self;
}

- (void)dealloc
{
    
}

// overriding the description - used in debugging
- (NSString *)description
{
    return(@"STM");
}

#pragma mark - Misc Methods

- (void)setBuildNumberInURLRequest:(NSMutableURLRequest *)request
{
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    [request setValue:[NSString stringWithFormat:@"%@", appBuildString] forHTTPHeaderField:BUILD_HEADER_PREFIX];
}


#pragma mark - Public Methods

- (void)setAuthorizationInURLRequest:(NSMutableURLRequest *)request
{
    [request setValue:[NSString stringWithFormat:@"%@ %@", STD_AUTH_PREFIX, [UserData controller].user.strAuthCode] forHTTPHeaderField:AUTH_KEY];
    [self setBuildNumberInURLRequest:request];
    
}

- (NSURLRequest *)urlRequestForPage:(NSString *)strPage
{
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:strPage]];
    [self setAuthorizationInURLRequest:(NSMutableURLRequest *)request];
    
    return request;
}

- (NSString *)channelId {
    return [STM settings].channel.strID;
}

/*
- (NSURLRequest *)urlRequestForStats
{
    NSString *strURL = [NSString stringWithFormat:@"%@/%@", [STM settings].strServerURL, SERVER_PAGE_STATS];
    
    return [self urlRequestForPage:strURL];
}
*/
/*
- (void)setChannel:(Channel *)channel
{
    if (channel)
    {
        //NSLog(@"setting channel with - mixpanel: %@, wit: %@, id: %@, name: %@", channel.strMixPanelToken, channel.strWitAccessToken, channel.strID, channel.strName);
        [[Analytics controller] setMixPanelToken:channel.strMixPanelToken];
        [[VoiceCmd controller] setWitAccessToken:channel.strWitAccessToken];
        [Settings controller].channel = channel;
        [Settings saveAll];
    }
}
*/

@end