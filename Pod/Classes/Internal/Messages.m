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

typedef enum eRequestType
{
    RequestType_None = 0,
    RequestType_MessageCount,
    RequestType_Messages
} tRequestType;

static BOOL bInitialized = NO;

__strong static Messages *singleton = nil;

@interface MessagesRequest : NSObject
{
}
@property (nonatomic, weak)     id<MessagesDelegate>    delegate;
@property (nonatomic, copy)     NSString                *strURL;
@property (nonatomic, assign)   tRequestType            type;

@end

@implementation MessagesRequest

@end

@interface Messages () <DL_URLRequestDelegate>
{
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

- (void)requestForMessagesWithDelegate:(id<MessagesDelegate>)delegate {
    
    MessagesRequest *request = [[MessagesRequest alloc] init];
    request.type = RequestType_Messages;
    request.delegate = delegate;
    request.strURL = [NSString stringWithFormat:@"%@/%@",
                      [Settings controller].strServerURL,
                      SERVER_CMD_GET_MESSAGES];
    
    //NSLog(@"Messages: URL = %@", strURL);
    
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

- (void)requestForUnreadMessageCountWithDelegate:(id<MessagesDelegate>)delegate {
    MessagesRequest *request = [[MessagesRequest alloc] init];
    request.delegate = delegate;
    request.type = RequestType_MessageCount;
    request.strURL = [NSString stringWithFormat:@"%@/%@/%@",
                      [Settings controller].strServerURL,
                      SERVER_CMD_GET_MESSAGES,
                      @"?count_only=true&unread_only=true"];
    
    //NSLog(@"Messages: URL = %@", strURL);
    
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

- (void)requestForCreateMessageForChannelId:(NSString *)channelId ToRecipientId:(NSString *)recipientId WithConversationId:(NSString *)conversationId AndMessage:(NSString *)message completionHandler:(void (^)(STMMessage *, NSError *))completionHandler {
    NSLog(@"requestForCreateMessageForChannelId:%@ ToRecipientId:%@ WithConversationId:%@ AndMessage:%@", channelId, recipientId, conversationId, message);
    NSError *error;
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
                                       [Settings controller].strServerURL,
                                       SERVER_CMD_GET_MESSAGES]];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setHTTPAdditionalHeaders:[[UserData controller] dictStandardRequestHeaders]];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    [request setHTTPMethod:@"POST"];
    NSDictionary *postBodyData = @{@"channel_id": channelId,
                                   @"recipient_id": recipientId,
                                   @"conversation_id": conversationId,
                                   @"message": message };
    
    NSData *postData = [NSJSONSerialization dataWithJSONObject:postBodyData options:0 error:&error];
    [request setHTTPBody:postData];
    
    if (!error) {
        [[session dataTaskWithRequest:request
                    completionHandler:^(NSData * _Nullable data,
                                        NSURLResponse * _Nullable response,
                                        NSError * _Nullable error) {
                        NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
                        //NSLog(@"Subscriptions: Results download returned: %@", jsonString );
                        
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
                                if ([dictData isKindOfClass:[NSDictionary class]] && [[dictData allKeys] containsObject:@"reason"]) {
                                    NSString *failureReason = [dictData objectForKey:@"reason"];
                                    NSMutableDictionary* details = [NSMutableDictionary dictionary];
                                    [details setValue:dictData forKey:NSLocalizedDescriptionKey];
                                    error = [NSError errorWithDomain:failureReason code:400 userInfo:details];
                                }
                            }
                            
                        }
                        
                        completionHandler(message, error);
                        
                    }] resume];
    }
}

- (void)cancelAllRequests
{
    [[DL_URLServer controller] cancelAllRequestsForDelegate:self];
}

#pragma mark - DL_URLServer Callbacks

// this is the results callback from DLURLServer
- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
    MessagesRequest *request = (MessagesRequest *)object;
    
    NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    
    //NSLog(@"Messages: Results download returned: %@", jsonString );
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
    NSDictionary *dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    NSString *strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];
    
    //NSLog(@"decode: %@", dictResults);
    
    NSArray *arrayMessages = nil;
    NSNumber *messageCount = 0;
    
    if (status == DL_URLRequestStatus_Success)
    {
        if ([strStatus isEqualToString:SERVER_RESULTS_STATUS_SUCCESS])
        {
            NSDictionary *dictData = [dictResults objectForKey:SERVER_RESULTS_DATA_KEY];
            if (dictData) {
                if (request.type == RequestType_Messages) {
                    arrayMessages = [self processMessagesResults:[dictData objectForKey:@"messages"]];
                } else if (request.type == RequestType_MessageCount) {
                    messageCount = [NSNumber numberWithInt:[Utils intFromKey:@"count" inDictionary:dictData]];
                }
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
        if (request.type == RequestType_Messages) {
            if ([request.delegate respondsToSelector:@selector(MessagesResults:)])
            {
                [request.delegate MessagesResults:arrayMessages];
            }
        } else if (request.type == RequestType_MessageCount) {
            if ([request.delegate respondsToSelector:@selector(UnreadMessageResults:)]) {
                [request.delegate UnreadMessageResults:messageCount];
            }
        }
        
    }
}


@end
