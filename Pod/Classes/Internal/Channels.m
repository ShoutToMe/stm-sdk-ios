//
//  Channels.m
//  ShoutToMeDev
//
//  Description:
//      This module provides the functionality associated with channels
//
//  Created by Adam Harris on 2/18/15.
//  Copyright 2015 Ditty Labs. All rights reserved.
//

#import "STM.h"
#import "Utils.h"
#import "Settings.h"
#import "Channels.h"
#import "DL_URLServer.h"
#import "Server.h"

static BOOL bInitialized = NO;

__strong static Channels *singleton = nil; // this will be the one and only object this static singleton class has

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface ChannelsRequest : NSObject
{
}

@property (nonatomic, weak)     id<ChannelsDelegate>    delegate;
@property (nonatomic, copy)     NSString                *strURL;

@end

@implementation ChannelsRequest

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface Channels () <DL_URLRequestDelegate>
{
}

@end

@implementation Channels

#pragma mark - Static methods

+ (void)initAll
{
	if (NO == bInitialized)
	{
        [DL_URLServer initAll];

        singleton = [[Channels alloc] init];

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
+ (Channels *)controller
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

#pragma mark - Misc Methods

// process the results returned from the server
- (NSArray *)processChannelsResults:(NSObject *)results
{
    NSMutableArray *arrayChannels = [[NSMutableArray alloc] init];

    if ([results isKindOfClass:[NSDictionary class]])
    {
        STMChannel *channel = [[STMChannel alloc] initWithDictionary:(NSDictionary *)results];
        [arrayChannels addObject:channel];
    }
    else if ([results isKindOfClass:[NSArray class]])
    {
        NSArray *arrayChannelDictionaries = (NSArray *)results;
        for (NSDictionary *dictChannel in arrayChannelDictionaries)
        {
            STMChannel *channel = [[STMChannel alloc] initWithDictionary:dictChannel];
            [arrayChannels addObject:channel];
        }
    }

    return arrayChannels;
}

#pragma mark - Public Methods

// request channel list from server
- (void)requestForChannelsWithDelegate:(id<ChannelsDelegate>)delegate
{
    ChannelsRequest *request = [[ChannelsRequest alloc] init];
    request.delegate = delegate;
    request.strURL = [NSString stringWithFormat:@"%@/%@", [Settings controller].strServerURL, SERVER_CMD_GET_CHANNELS];
    
    //NSLog(@"Channels: URL = %@", strURL);
    
    // create the request
    [[DL_URLServer controller] issueRequestURL:request.strURL
                                    methodType:DL_URLRequestMethod_Get
                                    withParams:nil
                                    withObject:request
                                  withDelegate:self
                            acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                   cacheResult:NO
                                   contentType:CONTENT_TYPE
                                headerRequests:[[UserData controller] dictStandardRequestHeaders]];
}

- (void)requestForChannel:(NSString *)channelID completionHandler:(void (^)(STMChannel *channel,
                                                                            NSError *error))completionHandler {
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@",
                     [Settings controller].strServerURL,
                     SERVER_CMD_GET_CHANNELS,
                     channelID];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];

    [config setHTTPAdditionalHeaders:[[UserData controller] dictStandardRequestHeaders]];


    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];

    [[session dataTaskWithURL:[NSURL URLWithString:url]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {

                NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];

                //NSLog(@"Channels: Results download returned: %@", jsonString );

                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
                NSDictionary *dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                NSString *strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];
                NSDictionary *dictData = [dictResults objectForKey:SERVER_RESULTS_DATA_KEY];


                STMChannel *channel;

                if ([strStatus isEqualToString:SERVER_RESULTS_STATUS_SUCCESS]) {

                    if (dictData)
                    {
                        channel = [[STMChannel alloc] initWithDictionary:[dictData objectForKey:@"channel"]];
                    }
                } else {
                    //STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Network error.", @"Channel request failed.", url, nil, jsonString);
                    if (dictData ) {
                        NSString *failureReason = [dictData objectForKey:@"reason"];
                        NSMutableDictionary* details = [NSMutableDictionary dictionary];
                        [details setValue:dictData forKey:NSLocalizedDescriptionKey];
                        error = [NSError errorWithDomain:failureReason code:400 userInfo:details];
                    }

                }

                completionHandler(channel, error);

            }] resume];

}

- (void)cancelAllRequests
{
    [[DL_URLServer controller] cancelAllRequestsForDelegate:self];
}

#pragma mark - DL_URLServer Callbacks

// this is the results callback from DLURLServer
- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
    ChannelsRequest *request = (ChannelsRequest *)object;
    
    NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    
    //NSLog(@"Channels: Results download returned: %@", jsonString );
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
    NSDictionary *dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    NSString *strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];
    
    //NSLog(@"decode: %@", dictResults);
    
    NSArray *arrayChannels = nil;
    
    if (status == DL_URLRequestStatus_Success)
    {
        if ([strStatus isEqualToString:SERVER_RESULTS_STATUS_SUCCESS])
        {
            NSDictionary *dictData = [dictResults objectForKey:SERVER_RESULTS_DATA_KEY];
            if (dictData)
            {
                arrayChannels = [self processChannelsResults:[dictData objectForKey:@"channels"]];
            }
        }
        else
        {
            STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Status check failed.", @"Channel request failed.", request.strURL, nil, jsonString);
        }
    }
    else
    {
        STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Network error.", @"Channel request failed.", request.strURL, nil, jsonString);
    }
    
    if (request.delegate)
    {
        if ([request.delegate respondsToSelector:@selector(ChannelsResults:)])
        {
            [request.delegate ChannelsResults:arrayChannels];
        }
    }
}

@end
