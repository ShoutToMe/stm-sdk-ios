//
//  Messages.m
//  Pods
//
//  Created by Tyler Clemens on 6/2/16.
//
//
#import "STM.h"
#import "Utils.h"
#import "Settings.h"
#import "Messages.h"
#import "DL_URLServer.h"
#import "Server.h"

static BOOL bInitialized = NO;

__strong static Messages *singleton = nil;

@interface MessagesRequest : NSObject
{
}
@property (nonatomic, weak)     id<MessagesDelegate>    delegate;
@property (nonatomic, copy)     NSString                *strURL;

@end

@implementation MessagesRequest

@end

@interface Messages () <DL_URLRequestDelegate>
{
    BOOL _bPendingRequest;
}

@end

@implementation Messages

#pragma mark - Static methods

+ (void)initAll
{
    if (NO == bInitialized)
    {
        [DL_URLServer initAll];
        
        singleton = [[Messages alloc] init];
        
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
+ (Messages *)controller
{
    return (singleton);
}

#pragma mark - Object Methods

- (id)init
{
    self = [super init];
    if (self)
    {
        _bPendingRequest = NO;
    }
    return self;
}

- (void)dealloc
{
    [[DL_URLServer controller] cancelAllRequestsForDelegate:self];
}

#pragma mark - Misc Methods

// process the results returned from the server
- (NSArray *)processMessagesResults:(NSObject *)results
{
    NSMutableArray *arrayMessages = [[NSMutableArray alloc] init];
    
    if ([results isKindOfClass:[NSDictionary class]])
    {
        STMMessage *message = [[STMMessage alloc] initWithDictionary:(NSDictionary *)results];
        [arrayMessages addObject:message];
    }
    else if ([results isKindOfClass:[NSArray class]])
    {
        NSArray *arrayMessageDictionaries = (NSArray *)results;
        for (NSDictionary *dictMessage in arrayMessageDictionaries)
        {
            STMMessage *message = [[STMMessage alloc] initWithDictionary:dictMessage];
            [arrayMessages addObject:message];
        }
    }
    
    return arrayMessages;
}

#pragma mark - Public Methods

// request message list from server
- (void)requestForMessagesWithChannelId:(NSString *)channelId AndDelegate:(id<MessagesDelegate>)delegate {
    if (!_bPendingRequest)
    {
        MessagesRequest *request = [[MessagesRequest alloc] init];
        request.delegate = delegate;
        request.strURL = [NSString stringWithFormat:@"%@/%@", [Settings controller].strServerURL, SERVER_CMD_GET_MESSAGES];
        request.strURL = [NSString stringWithFormat:@"%@/%@?channel_id=%@",
                                  [Settings controller].strServerURL,
                                  SERVER_CMD_GET_MESSAGES,
                                  channelId];
        
        //NSLog(@"Messages: URL = %@", strURL);
        
        // create the request
        _bPendingRequest = YES;
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
}

- (void)requestForMessagesWithRecipientId:(NSString *)recipientId AndDelegate:(id<MessagesDelegate>)delegate {
    if (!_bPendingRequest)
    {
        MessagesRequest *request = [[MessagesRequest alloc] init];
        request.delegate = delegate;
        request.strURL = [NSString stringWithFormat:@"%@/%@", [Settings controller].strServerURL, SERVER_CMD_GET_MESSAGES];
        request.strURL = [NSString stringWithFormat:@"%@/%@?recipient_id=%@",
                          [Settings controller].strServerURL,
                          SERVER_CMD_GET_MESSAGES,
                          recipientId];
        
        //NSLog(@"Messages: URL = %@", strURL);
        
        // create the request
        _bPendingRequest = YES;
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
}

- (void)requestForMessage:(NSString *)messageId completionHandler:(void (^)(STMMessage *, NSError *))completionHandler {
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@",
                     [Settings controller].strServerURL,
                     SERVER_CMD_GET_MESSAGES,
                     messageId];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    [config setHTTPAdditionalHeaders:[[UserData controller] dictStandardRequestHeaders]];
    
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    [[session dataTaskWithURL:[NSURL URLWithString:url]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                
                NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
                
                //NSLog(@"Messages: Results download returned: %@", jsonString );
                
                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
                NSDictionary *dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                NSString *strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];
                NSDictionary *dictData = [dictResults objectForKey:SERVER_RESULTS_DATA_KEY];
                
                
                STMMessage *message;
                
                if ([strStatus isEqualToString:SERVER_RESULTS_STATUS_SUCCESS]) {
                    
                    if (dictData)
                    {
                        message = [[STMMessage alloc] initWithDictionary:[dictData objectForKey:@"message"]];
                    }
                } else {
                    //STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Network error.", @"Message request failed.", url, nil, jsonString);
                    if (dictData ) {
                        NSString *failureReason = [dictData objectForKey:@"reason"];
                        NSMutableDictionary* details = [NSMutableDictionary dictionary];
                        [details setValue:dictData forKey:NSLocalizedDescriptionKey];
                        error = [NSError errorWithDomain:failureReason code:400 userInfo:details];
                    }
                    
                }
                
                completionHandler(message, error);
                
            }] resume];
}

- (void)cancelAllRequests
{
    [[DL_URLServer controller] cancelAllRequestsForDelegate:self];
    _bPendingRequest = NO;
}

#pragma mark - DL_URLServer Callbacks

// this is the results callback from DLURLServer
- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
    if (_bPendingRequest)
    {
        MessagesRequest *request = (MessagesRequest *)object;
        
        NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
        
        //NSLog(@"Messages: Results download returned: %@", jsonString );
        
        NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
        NSDictionary *dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
        NSString *strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];
        
        //NSLog(@"decode: %@", dictResults);
        
        NSArray *arrayMessages = nil;
        
        if (status == DL_URLRequestStatus_Success)
        {
            if ([strStatus isEqualToString:SERVER_RESULTS_STATUS_SUCCESS])
            {
                NSDictionary *dictData = [dictResults objectForKey:SERVER_RESULTS_DATA_KEY];
                if (dictData)
                {
                    arrayMessages = [self processMessagesResults:[dictData objectForKey:@"messages"]];
                }
            }
            else
            {
                STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Status check failed.", @"Message request failed.", request.strURL, nil, jsonString);
            }
        }
        else
        {
            STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Network error.", @"Message request failed.", request.strURL, nil, jsonString);
        }
        
        if (request.delegate)
        {
            if ([request.delegate respondsToSelector:@selector(MessagesResults:)])
            {
                [request.delegate MessagesResults:arrayMessages];
            }
        }
    }
    
    _bPendingRequest = NO;
}


@end
