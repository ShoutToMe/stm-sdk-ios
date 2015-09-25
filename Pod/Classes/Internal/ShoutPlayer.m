//
//  ShoutPlayer.m
//  ShoutToMeDev
//
//  Description:
//      This module provides the functionality for playing shouts
//
//  Created by Adam Harris on 12/12/14.
//  Copyright 2014 Ditty Labs. All rights reserved.
//

#import "STM.h"
#import "Utils.h"
#import "Settings.h"
#import "ShoutPlayer.h"
#import "DL_URLServer.h"
#import "Server.h"
#import "STMLocation.h"
#import "STMShout.h"

//#define DO_NOT_SEND_HAS_BEEN_PLAYED // uncomment this if you don't want the server to know a shout was played - debug only
#ifdef DO_NOT_SEND_HAS_BEEN_PLAYED
#warning debug do no send shout has been played settings has been defined
#endif

static BOOL bInitialized = NO;

__strong static ShoutPlayer *singleton = nil; // this will be the one and only object this static singleton class has

typedef enum eShoutPlayerRequestType
{
    ShoutPlayerRequestType_Play,
    ShoutPlayerRequestType_Cache,
    ShoutPlayerRequestType_MarkAsPlayed,
    ShoutPlayerRequestType_Downvote
} tShoutPlayerRequestType;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface ShoutPlayerRequest : NSObject
{
}

@property (nonatomic, assign)   tShoutPlayerRequestType type;
@property (nonatomic, strong)   STMShout                   *shout;
@property (nonatomic, copy)     NSString                *str_media_file_url;
@property (nonatomic, copy)     NSString                *strRequestURL;
@property (nonatomic, assign)   BOOL                    bAudioLoadSuccess; // for play and cache only
@property (nonatomic, weak)     id<ShoutPlayerDelegate> delegate;

@end

@implementation ShoutPlayerRequest

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface ShoutPlayer () <DL_URLRequestDelegate, AudioSystemDelegate>
{

}

@property (nonatomic, strong)   ShoutPlayerRequest          *curPlayShoutRequest;
@property (nonatomic, strong)   STMShout                       *lastShout;
@property (nonatomic, strong)   NSDate                      *dateLastShoutPlayed;
@property (nonatomic, strong)   NSMutableDictionary         *dictAudioDataCache;

@end

@implementation ShoutPlayer

#pragma mark - Static methods

+ (void)initAll
{
	if (NO == bInitialized)
	{
        [Settings initAll];
        [DL_URLServer initAll];

        singleton = [[ShoutPlayer alloc] init];

		bInitialized = YES;
	}
}

+ (void)freeAll
{
	if (YES == bInitialized)
	{
        // release our singleton
        singleton = nil;
		
		bInitialized = NO;
	}
}

// returns the singleton 
// (this call is both a container and an object class and the container holds one of itself)
+ (ShoutPlayer *)controller
{
    return (singleton);
}

#pragma mark - Object Methods

- (id)init
{
    self = [super init];
    if (self) 
	{
        self.dictAudioDataCache = [[NSMutableDictionary alloc] init];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleMemoryWarning:) name:UIApplicationDidReceiveMemoryWarningNotification object:nil];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[DL_URLServer controller] cancelAllRequestsForDelegate:self];
}

#pragma mark - Misc Methods

// download audio for a shout using the given request
- (void)downloadAudioWithRequest:(ShoutPlayerRequest *)request
{
    request.strRequestURL = request.str_media_file_url;
    [[DL_URLServer controller] issueRequestURL:request.strRequestURL
                                    methodType:DL_URLRequestMethod_Get
                                    withParams:nil
                                    withObject:request
                                  withDelegate:self
                            acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                   cacheResult:NO];
}

// tell the server that a shout has been played by the user
- (void)uploadPlayedForShout:(STMShout *)shout;
{
    if (shout)
    {
        ShoutPlayerRequest *request = [[ShoutPlayerRequest alloc] init];
        request.type = ShoutPlayerRequestType_MarkAsPlayed;
        request.shout = shout;
        request.str_media_file_url = shout.str_media_file_url;

        request.strRequestURL = [NSString stringWithFormat:@"%@/%@/%@/play",
                                 [Settings controller].strServerURL,
                                 SERVER_CMD_POST_PLAYED,
                                 shout.str_id];
        //NSLog(@"url: %@", request.strRequestURL);

#ifndef DO_NOT_SEND_HAS_BEEN_PLAYED
        [[DL_URLServer controller] issueRequestURL:request.strRequestURL
                                        methodType:DL_URLRequestMethod_Post
                                        withParams:@"{}"
                                        withObject:request
                                      withDelegate:self
                                acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                       cacheResult:NO
                                       contentType:DL_URLSERVER_DEFAULT_CONTENT_TYPE
                                         headerRequests:[[UserData controller] dictStandardRequestHeaders]];
#endif
    }
}

// start playing the currently selected shout
- (void)startPlaying
{
    if (self.curPlayShoutRequest)
    {
        NSDictionary *dictNotification = @{ STM_NOTIFICATION_KEY_SHOUT_PLAYER_SHOUT : self.curPlayShoutRequest.shout };
        [[NSNotificationCenter defaultCenter] postNotificationName:STM_NOTIFICATION_SHOUT_PLAYER_STARTED object:self userInfo:dictNotification];

        NSData *dataAudio = [self audioForShout:self.curPlayShoutRequest.shout];
        if (dataAudio)
        {
            [[STM audioSystem] playData:dataAudio withDelegate:self andUserData:nil];
            [self performSelector:@selector(uploadPlayedForShout:) withObject:self.curPlayShoutRequest.shout afterDelay:0.0];
        }
        else
        {
            [self performSelector:@selector(stop) withObject:nil afterDelay:0.0];
        }
    }
}

// clear all of the cached audio for the shouts
- (void)clearCache
{
    [self.dictAudioDataCache removeAllObjects];
}

// send notification that audio has been loaded for the given shout
- (void)performAudioLoadedNotify:(ShoutPlayerRequest *)request
{
    if (request)
    {
        // if there was a delegate
        if (request.delegate)
        {
            if ([request.delegate respondsToSelector:@selector(ShoutAudioLoaded: success:)])
            {
                [request.delegate ShoutAudioLoaded:request.shout success:request.bAudioLoadSuccess];
            }
        }

        // also send out a notification
        NSDictionary *dictNotification = @{ STM_NOTIFICATION_KEY_SHOUT_PLAYER_SHOUT : request.shout,
                                            STM_NOTIFICATION_KEY_SHOUT_PLAYER_LOAD_SUCCESS : [NSNumber numberWithBool:request.bAudioLoadSuccess]
                                            };
        [[NSNotificationCenter defaultCenter] postNotificationName:STM_NOTIFICATION_SHOUT_PLAYER_AUDIO_LOADED object:self userInfo:dictNotification];
    }
}

// create a request to retrieve a shout
- (ShoutPlayerRequest *)createRequestForShout:(STMShout *)shout ofType:(tShoutPlayerRequestType)type withDelegate:(id<ShoutPlayerDelegate>)delegate
{
    ShoutPlayerRequest *request = [[ShoutPlayerRequest alloc] init];
    request.type = type;
    request.shout = shout;
    request.str_media_file_url = shout.str_media_file_url;
    request.delegate = delegate;

    request.bAudioLoadSuccess = [self haveAudioForShout:request.shout];

    return request;
}

// returns the audio for a given shout. If it isn't in the cache, it returns nil
- (NSData *)audioForShout:(STMShout *)shout
{
    NSData *dataAudio = nil;

    if (shout)
    {
        if (shout.str_media_file_url)
        {
            dataAudio = [self.dictAudioDataCache objectForKey:shout.str_media_file_url];
        }
    }

    return dataAudio;
}

#pragma mark - Public Methods

// plays the given shout (if the audio isn't part of the shout, it is retrieved)
- (void)play:(STMShout *)shout withDelegate:(id<ShoutPlayerDelegate>)delegate
{
    [self stop];

    // if we aren't currently playing a shout
    if (!self.curPlayShoutRequest)
    {
        //[[Analytics controller] increment:@"shouts heard" by:1];

        self.curPlayShoutRequest = [self createRequestForShout:shout ofType:ShoutPlayerRequestType_Play withDelegate:delegate];

        self.lastShout = self.curPlayShoutRequest.shout;
        self.dateLastShoutPlayed = [NSDate date];

        // if we have the audio for this shout in our cache
        if ([self haveAudioForShout:shout])
        {
            [self performSelector:@selector(performAudioLoadedNotify:) withObject:self.curPlayShoutRequest afterDelay:0.0];
            [self performSelector:@selector(startPlaying) withObject:nil afterDelay:0.0];
        }
        else
        {
            [self performSelector:@selector(downloadAudioWithRequest:) withObject:self.curPlayShoutRequest afterDelay:0.0];
        }
    }
}

// loads audio for the given shout
- (void)loadAudioForShout:(STMShout *)shout withDelegate:(id<ShoutPlayerDelegate>)delegate
{
    ShoutPlayerRequest *request = [self createRequestForShout:shout ofType:ShoutPlayerRequestType_Cache withDelegate:delegate];

    // if we have the audio for this shout in our cache
    if ([self haveAudioForShout:request.shout])
    {
        [self performSelector:@selector(performAudioLoadedNotify:) withObject:request afterDelay:0.0];
    }
    else
    {
        [self performSelector:@selector(downloadAudioWithRequest:) withObject:request afterDelay:0.0];
    }
}

// replays the last played shout
- (void)replayLastShoutWithDelegate:(id<ShoutPlayerDelegate>)delegate
{
    if (self.lastShout)
    {
        [self stop];
        [self play:self.lastShout withDelegate:delegate];
    }
}

// stops the playing of the given shout
- (void)stop:(STMShout *)shout
{
    if (self.curPlayShoutRequest)
    {
        // if this is the shout we are playing then stop it
        if (shout == self.curPlayShoutRequest.shout)
        {
            [self stop];
        }
    }
}

// stops all audio that is playing
- (void)stopPlayingAudio
{
    [[STM audioSystem] stopAudioAndSpeechFor:self cancelCallback:YES];
}

// stop playing the currently playing shout
- (void)stop
{
    BOOL bPostEnded = (self.curPlayShoutRequest != nil);
    STMShout *shout = nil;

    if (self.curPlayShoutRequest)
    {
        // switch the request to just cache in case we are in the middle of downloading
        self.curPlayShoutRequest.type = ShoutPlayerRequestType_Cache;

        if (self.curPlayShoutRequest.delegate)
        {
            if ([self.curPlayShoutRequest.delegate respondsToSelector:@selector(ShoutPlayerFinished:)])
            {
                [self.curPlayShoutRequest.delegate ShoutPlayerFinished:self.curPlayShoutRequest.shout];
            }

            self.curPlayShoutRequest.delegate = nil;
        }

        shout = self.curPlayShoutRequest.shout;
        self.curPlayShoutRequest = nil;
    }

    [self stopPlayingAudio];

    if (bPostEnded)
    {
        NSDictionary *dictNotification = @{ STM_NOTIFICATION_KEY_SHOUT_PLAYER_SHOUT : shout };
        [[NSNotificationCenter defaultCenter] postNotificationName:STM_NOTIFICATION_SHOUT_PLAYER_ENDED object:self userInfo:dictNotification];
    }
}

// returns whether a shout is playing
- (BOOL)isPlaying
{
    // if we have a current play shout request then we are playing because it will get set to nil when done
    return (self.curPlayShoutRequest != nil);
}

// returns the currently playing shout
- (STMShout *)currentShout
{
    STMShout *curShout = nil;

    if (self.curPlayShoutRequest)
    {
        curShout = self.curPlayShoutRequest.shout;
    }

    return curShout;
}

- (NSDate *)timeLastShoutWasPlayed
{
    return self.dateLastShoutPlayed;
}

// returns SHOUT_PLAYER_NO_SHOUT_PLAYED if no shout has been played
- (NSInteger)secondsSinceLastPlayedShout
{
    NSInteger seconds = SHOUT_PLAYER_NO_SHOUT_PLAYED;

    if (self.dateLastShoutPlayed)
    {
        seconds = (NSInteger) ([[NSDate date] timeIntervalSinceDate:self.dateLastShoutPlayed] + 0.5);
    }

    return seconds;
}

- (STMShout *)lastPlayedShout
{
    return self.lastShout;
}

// send a command to the server to flag a shout as bad
- (void)downvoteShout:(STMShout *)shout
{
    if (shout)
    {
        //[[Analytics controller] increment:@"shouts flagged bad" by:1];

        ShoutPlayerRequest *request = [[ShoutPlayerRequest alloc] init];
        request.type = ShoutPlayerRequestType_Downvote;
        request.shout = shout;
        request.str_media_file_url = shout.str_media_file_url;

        request.strRequestURL = [NSString stringWithFormat:@"%@/%@/%@/%@",
                                 [Settings controller].strServerURL,
                                 SERVER_CMD_PUT_SHOUT,
                                 shout.str_id,
                                 SERVER_CMD_PUT_DOWNVOTE_SHOUT];
        //NSLog(@"url: %@", request.strRequestURL);

        [[DL_URLServer controller] issueRequestURL:request.strRequestURL
                                        methodType:DL_URLRequestMethod_Put
                                        withParams:nil
                                        withObject:request
                                      withDelegate:self
                                acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                       cacheResult:NO
                                       contentType:DL_URLSERVER_DEFAULT_CONTENT_TYPE
                                    headerRequests:[[UserData controller] dictStandardRequestHeaders]];
    }
}

// checks the shout audio cache to see if we have audio for the given shout
- (BOOL)haveAudioForShout:(STMShout *)shout
{
    return ([self audioForShout:shout] != nil);
}

#pragma mark - AudioSystem Delegates

- (void)AudioSystemElementComplete:(AudioElement *)audioElement
{
    //NSLog(@"finished playing audio");
    [self performSelector:@selector(stop) withObject:nil afterDelay:0.0];
}

#pragma mark - DL_URLServer Callbacks

// this is the results callback from DLURLServer
- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
    ShoutPlayerRequest *request = (ShoutPlayerRequest *)object;

    NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];

    //NSLog(@"Results download returned: %@", jsonString );

    if (request)
    {
        if ((request.type == ShoutPlayerRequestType_MarkAsPlayed) || (request.type == ShoutPlayerRequestType_Downvote))
        {
            NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
            NSDictionary *dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
            NSString *strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];

            NSString *strFailString = (request.type == ShoutPlayerRequestType_MarkAsPlayed ? @"Played shout notification failed." : @"Downvote shout  failed.");

            //NSLog(@"decode: %@", dictResults);

            if (status == DL_URLRequestStatus_Success)
            {
                if (![strStatus isEqualToString:SERVER_RESULTS_STATUS_SUCCESS])
                {
                    STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Status check failed.", strFailString, request.strRequestURL, nil, jsonString);
                }
            }
            else
            {
                STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Network error.", strFailString, request.strRequestURL, nil, jsonString);
            }
        }
        else // download (possibly for play)
        {
            //NSLog(@"ShoutPlayer: Audio downloaded for %@ (len: %lu)", request.str_media_file_url, (unsigned long) [data length]);

            request.bAudioLoadSuccess = (status == DL_URLRequestStatus_Success);
            if (request.bAudioLoadSuccess)
            {
                // cache the audio
                [self.dictAudioDataCache setObject:data forKey:request.str_media_file_url];
            }
            else
            {
                STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Network error.", @"Shout audio download failed.", request.strRequestURL, nil, jsonString);
            }

            // process telling the delegate (if needed)
            [self performSelector:@selector(performAudioLoadedNotify:) withObject:request afterDelay:0.0];

            // if this is the shout we are supposed to be playing
            if ((request.type == ShoutPlayerRequestType_Play) && (request == self.curPlayShoutRequest))
            {
                if ([self haveAudioForShout:request.shout])
                {
                    [self performSelector:@selector(startPlaying) withObject:nil afterDelay:0.0];
                }
                else
                {
                    [self performSelector:@selector(stop) withObject:nil afterDelay:0.0];
                    [self performSelector:@selector(uploadPlayedForShout:) withObject:request.shout afterDelay:0.0];
                }
            }
        }
    }
}

#pragma mark - Memory Notification

- (void)handleMemoryWarning:(NSNotification *)notification
{
    NSLog(@"recieved memory warning, clearing cache...");

    [self clearCache];
}

@end
