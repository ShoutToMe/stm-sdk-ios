//
//  SendShout.m
//  ShoutToMeDev
//
//  Description:
//      This module provides the functionality to send a shout to the server
//
//  Created by Adam Harris on 12/08/14.
//  Copyright 2014 Ditty Labs. All rights reserved.
//

#import "STM.h"
#import "Utils.h"
#import "Settings.h"
#import "SendShout.h"
#import "DL_URLServer.h"
#import "Server.h"
#import "STMLocation.h"
#import "Error.h"

typedef enum eRequestType
{
    RequestType_None = 0,
    RequestType_SendShout,
    RequestType_Undo
} tRequestType;

static BOOL bInitialized = NO;

__strong static SendShout *singleton = nil; // this will be the one and only object this static singleton class has

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface SendShoutRequest : NSObject

@property (nonatomic, assign)   tRequestType            type;
@property (nonatomic, assign)   tSendShoutStatus        status;
@property (nonatomic, copy)     NSString                *strShoutFilename;
@property (nonatomic, strong)   NSData                  *dataAudio;
@property (nonatomic, copy)     NSString                *strText;
@property (nonatomic, copy)     NSString                *strReplyToId;
@property (nonatomic, weak)     id<SendShoutDelegate>   delegate;
@property (nonatomic, copy)     NSString                *strURL;
@property (nonatomic, strong)   NSMutableDictionary     *dictRequestData;

@end

@implementation SendShoutRequest

#pragma mark - NSObject overrides

- (id)init
{
    self = [super init];
    if (self)
    {
        self.type = RequestType_None;
        self.status = SendShoutStatus_NotStarted;
        self.dataAudio = nil;
        self.delegate = nil;
        self.dictRequestData = nil;
        self.strText = @"";
        self.strURL = @"";
    }
    return self;
}

- (void)dealloc
{

}

// overriding the description - used in debugging
- (NSString *)description
{
    return([NSString stringWithFormat:@"SendShoutRequest: ShoutFilename=%@", self.strShoutFilename]);
}

@end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface SendShout () <DL_URLRequestDelegate>
{

}

@property (nonatomic, strong)   NSDate              *dateLastSend; // when was the last shout sent
@property (nonatomic, strong)   STMShout               *shoutLastSent;

@end

@implementation SendShout

#pragma mark - Static methods

+ (void)initAll
{
	if (NO == bInitialized)
	{
        [Settings initAll];
        [DL_URLServer initAll];

        singleton = [[SendShout alloc] init];

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
+ (SendShout *)controller
{
    return (singleton);
}

#pragma mark - Object Methods

- (id)init
{
    self = [super init];
    if (self) 
	{

    }
    return self;
}

- (void)dealloc
{
    [[DL_URLServer controller] cancelAllRequestsForDelegate:self];
}

// overriding the description - used in debugging
- (NSString *)description
{
    return(@"SendShout Request");
}

#pragma mark - Misc Methods

// process the results of a sent shout
- (void)processResults:(SendShoutRequest *)request
{
    if (request)
    {
        if (request.type == RequestType_SendShout)
        {
            // if they have set the delegate function
            if ([request.delegate respondsToSelector:@selector(onSendShoutCompleteWithStatus:)])
            {
                // give the delegate the results
                [request.delegate onSendShoutCompleteWithStatus:request.status];
            }
            
            if ([request.delegate respondsToSelector:@selector(onSendShoutCompleteWithShout:WithStatus:)])
            {
                // give the delegate the results
                [request.delegate onSendShoutCompleteWithShout:self.shoutLastSent WithStatus:request.status];
            }
        }
    }
}

// sends the shout in the given request to the server
- (void)postShout:(SendShoutRequest *)request
{
    if (request)
    {
        // set the json data
        request.dictRequestData = [[NSMutableDictionary alloc] init];
        [request.dictRequestData setObject:[Settings controller].channel.strID forKey:SERVER_CHANNEL_ID_KEY];
        [request.dictRequestData setObject:[Settings controller].strDeviceID forKey:SERVER_DEVICE_ID_KEY];
        [request.dictRequestData setObject:[request.dataAudio base64EncodedStringWithOptions:0] forKey:SERVER_AUDIO_KEY];
        [request.dictRequestData setObject:[NSNumber numberWithDouble:[STMLocation controller].curLocation.coordinate.latitude] forKey:SERVER_LAT_KEY];
        [request.dictRequestData setObject:[NSNumber numberWithDouble:[STMLocation controller].curLocation.coordinate.longitude] forKey:SERVER_LON_KEY];
        [request.dictRequestData setObject:[NSNumber numberWithDouble:[STMLocation controller].course] forKey:SERVER_COURSE_KEY];
        [request.dictRequestData setObject:[NSNumber numberWithDouble:[STMLocation controller].speed] forKey:SERVER_SPEED_KEY];
        [request.dictRequestData setObject:request.strText forKey:SERVER_SPOKEN_TEXT_KEY];
        if ([Utils stringIsSet:request.strReplyToId])
        {
            [request.dictRequestData setObject:request.strReplyToId forKey:SERVER_REPLY_TO_ID_KEY];
        }
        //NSLog(@"audio: %@", [request.dictRequestData objectForKey:SERVER_AUDIO_KEY]);

        NSError *error = nil;
        NSData *dataJSON = [NSJSONSerialization dataWithJSONObject:request.dictRequestData options:NSJSONWritingPrettyPrinted error:&error];
        NSString *strJSON = [[NSString alloc] initWithData:dataJSON encoding:NSUTF8StringEncoding];
        //NSLog(@"Shout Send: data = %@", strJSON);

        request.strURL = [NSString stringWithFormat:@"%@/%@",
                          [Settings controller].strServerURL,
                          SERVER_CMD_POST_SHOUT];

        //NSLog(@"Shout Send: URL = %@", request.strURL);
        [[DL_URLServer controller] issueRequestURL:request.strURL
                                        methodType:DL_URLRequestMethod_Post
                                        withParams:strJSON
                                        withObject:request
                                      withDelegate:self
                                acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                       cacheResult:NO
                                       contentType:CONTENT_TYPE
                                    headerRequests:[[UserData controller] dictStandardRequestHeaders]];
    }
}

#pragma mark - Public Methods

// sends the shout to the server
- (void)sendData:(NSData *)dataShout text:(NSString *)strText replyToId:(NSString *)strReplyToId withDelegate:(id<SendShoutDelegate>)delegate
{
    //[[Analytics controller] increment:@"shouts recorded" by:1];

    SendShoutRequest *request = [[SendShoutRequest alloc] init];

    self.dateLastSend = nil;

    request = [[SendShoutRequest alloc] init];
    request.type = RequestType_SendShout;
    request.delegate = delegate;
    request.dataAudio = dataShout;
    request.strText = strText;
    if (strReplyToId)
    {
        request.strReplyToId = strReplyToId;
    }

    [self postShout:request];
}

// takes back the last sent shout
- (void)undoLastSend
{
    if (self.shoutLastSent)
    {
        //[[Analytics controller] increment:@"shouts taken back" by:1];

        SendShoutRequest *request = [[SendShoutRequest alloc] init];

        request = [[SendShoutRequest alloc] init];
        request.type = RequestType_Undo;
        request.delegate = nil;

        request.strURL = [NSString stringWithFormat:@"%@/%@/%@",
                          [Settings controller].strServerURL,
                          SERVER_CMD_UNDO_SHOUT,
                          self.shoutLastSent.str_id];

        //NSLog(@"Undo Shout: URL = %@", request.strURL);

        [[DL_URLServer controller] issueRequestURL:request.strURL
                                        methodType:DL_URLRequestMethod_Delete
                                        withParams:nil
                                        withObject:request
                                      withDelegate:self
                                acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                       cacheResult:NO
                                       contentType:CONTENT_TYPE
                                    headerRequests:[[UserData controller] dictStandardRequestHeaders]];

        self.dateLastSend = nil;
        self.shoutLastSent = nil;
    }
}

- (NSDate *)dateOfLastSend
{
    return self.dateLastSend;
}

- (STMShout *)lastSentShout
{
    return self.shoutLastSent;
}

#pragma mark - DLURLServer Callbacks

// this is the results callback from DLURLServer
- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
    SendShoutRequest *request = (SendShoutRequest *)object;

    // remove the audio from the request data so it isn't reported if there is an error
    if (request)
    {
        if (request.dictRequestData)
        {
            [request.dictRequestData removeObjectForKey:SERVER_AUDIO_KEY];
        }
    }

    NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];

    //NSLog(@"Results download returned: %@", jsonString c);

    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
    NSDictionary *dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    NSString *strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];

    //NSLog(@"decode: %@", dictResults);

    if (status == DL_URLRequestStatus_Success)
    {
        request.status = SendShoutStatus_Failure;
        if ([strStatus isEqualToString:SERVER_RESULTS_STATUS_SUCCESS])
        {
            request.status = SendShoutStatus_Success;

            // if this was a send shout, we need to get some info so we can undo it if necessary
            if (request.type == RequestType_SendShout)
            {
                self.dateLastSend = [NSDate date];
                self.shoutLastSent = nil;
                NSDictionary *dictData = [dictResults objectForKey:SERVER_RESULTS_DATA_KEY];
                if (dictData)
                {
                    NSDictionary *dictShout = [dictData objectForKey:SERVER_RESULTS_SHOUT_KEY];
                    if (dictShout)
                    {
                        self.shoutLastSent = [[STMShout alloc] initWithDictionary:dictShout];
                        //NSLog(@"shout: %@", self.shoutLastSent);
                        if (![Utils stringIsSet:self.shoutLastSent.str_id])
                        {
                            self.shoutLastSent = nil;
                        }
                    }
                }

                if (!self.shoutLastSent)
                {
                    self.dateLastSend = nil;
                    STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"No shout data.", @"Shout post failed.", request.strURL, request.dictRequestData, jsonString);
                }
            }
            else if (request.type == RequestType_Undo)
            {
                self.shoutLastSent = nil;
                self.dateLastSend = nil;
            }
        }
        else
        {
            self.shoutLastSent = nil;
            self.dateLastSend = nil;
            STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Status check failed.", (request.type == RequestType_SendShout ? @"Shout post failed." : @"Shout undo failed"), request.strURL, request.dictRequestData, jsonString);
            request.status = SendShoutStatus_Failure;
        }
    }
    else
    {
        self.shoutLastSent = nil;
        self.dateLastSend = nil;
        STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Network error.", (request.type == RequestType_SendShout ? @"Shout post failed." : @"Shout undo failed"), request.strURL, request.dictRequestData, jsonString);
        request.status = SendShoutStatus_Failure;
    }

    // if this was a post shout request
    if (request.type == RequestType_SendShout)
    {
        [self performSelector:@selector(processResults:) withObject:request afterDelay:0.0];
    }
}

@end
