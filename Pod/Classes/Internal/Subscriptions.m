//
//  Subscriptions.m
//  Pods
//
//  Created by Tyler Clemens on 7/6/16.
//
//
#import "STM.h"
#import "Utils.h"
#import "Settings.h"
#import "DL_URLServer.h"
#import "Server.h"
#import "Subscriptions.h"

typedef enum eRequestType
{
    RequestType_None = 0,
    RequestType_SubscriptionsRequest
} tRequestType;


static BOOL bInitialized = NO;

__strong static Subscriptions *singleton = nil;

@interface SubscriptionsRequest : NSObject
{
}
@property (nonatomic, weak)     id<SubscriptionsDelegate>    delegate;
@property (nonatomic, copy)     NSString                *strURL;
@property (nonatomic, assign)   tRequestType            type;

@end

@implementation SubscriptionsRequest

@end

@interface Subscriptions () <DL_URLRequestDelegate>
{
}

@end


@implementation Subscriptions

#pragma mark - Static methods

+ (void)initAll
{
    if (NO == bInitialized)
    {
        [DL_URLServer initAll];
        
        singleton = [[Subscriptions alloc] init];
        
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
+ (Subscriptions *)controller
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

- (void)requestForSubscriptionForChannel:(NSString *)channelId withDelegate:(id<SubscriptionsDelegate>)delegate {
    SubscriptionsRequest *request = [[SubscriptionsRequest alloc] init];
    request.type = RequestType_SubscriptionsRequest;
    request.delegate = delegate;
    request.strURL = [NSString stringWithFormat:@"%@/%@/%@/%@",
                      [Settings controller].strServerURL,
                      SERVER_CMD_GET_CHANNELS,
                      channelId,
                      SERVER_CMD_GET_SUBSCRIPTIONS];
    
    //NSLog(@"Subscriptions: URL = %@", strURL);
    
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

- (void)requestForSubscriptionForChannel:(NSString *)channelId completionHandler:(void (^)(STMSubscription *, NSError *))completionHandler {
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@/%@",
                     [Settings controller].strServerURL,
                     SERVER_CMD_GET_CHANNELS,
                     channelId,
                     SERVER_CMD_GET_SUBSCRIPTIONS];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    [config setHTTPAdditionalHeaders:[[UserData controller] dictStandardRequestHeaders]];
    
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    [[session dataTaskWithURL:[NSURL URLWithString:url]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                
                NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
                
                //NSLog(@"Subscriptions: Results download returned: %@", jsonString );
                
                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
                NSDictionary *dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                NSString *strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];
                NSDictionary *dictData = [dictResults objectForKey:SERVER_RESULTS_DATA_KEY];
                
                
                STMSubscription *subscription;
                
                if ([strStatus isEqualToString:SERVER_RESULTS_STATUS_SUCCESS]) {
                    
                    if (dictData)
                    {
                        subscription = [[STMSubscription alloc] initWithDictionary:[dictData objectForKey:@"subscription"]];
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
                
                completionHandler(subscription, error);
                
            }] resume];

}

- (void)requestForSubscribe:(NSString *)channelId completionHandler:(void (^)(STMSubscription *, NSError *))completionHandler {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@/%@",
                                       [Settings controller].strServerURL,
                                       SERVER_CMD_GET_CHANNELS,
                                       channelId,
                                       SERVER_CMD_GET_SUBSCRIPTIONS]];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setHTTPAdditionalHeaders:[[UserData controller] dictStandardRequestHeaders]];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    
    NSDictionary *dictionary = @{};
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary
                                                   options:kNilOptions error:&error];
    
    if (!error) {
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request fromData:data
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
                //NSLog(@"Subscriptions: Results download returned: %@", jsonString );
                
                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
                NSDictionary *dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                NSString *strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];
                NSDictionary *dictData = [dictResults objectForKey:SERVER_RESULTS_DATA_KEY];
                
                
                STMSubscription *subscription;
                
                if ([strStatus isEqualToString:SERVER_RESULTS_STATUS_SUCCESS]) {
                    
                    if (dictData)
                    {
                        subscription = [[STMSubscription alloc] initWithDictionary:[dictData objectForKey:@"subscription"]];
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
                
                completionHandler(subscription, error);
        
                }];
        [uploadTask resume];
    }
}

- (void)requestForUnSubscribe:(NSString *)channelId completionHandler:(void (^)(Boolean *, NSError *))completionHandler {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@/%@",
                                       [Settings controller].strServerURL,
                                       SERVER_CMD_GET_CHANNELS,
                                       channelId,
                                       SERVER_CMD_GET_SUBSCRIPTIONS]];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setHTTPAdditionalHeaders:[[UserData controller] dictStandardRequestHeaders]];
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"DELETE";
    
    NSDictionary *dictionary = @{};
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary
                                                   options:kNilOptions error:&error];
    
    if (!error) {
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request fromData:data
            completionHandler:^(NSData *data,
            NSURLResponse *response,
            NSError *error) {
                NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
                //NSLog(@"Subscriptions: Results download returned: %@", jsonString );
                
                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
                NSDictionary *dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                NSString *strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];
                NSDictionary *dictData = [dictResults objectForKey:SERVER_RESULTS_DATA_KEY];
                
                Boolean result = false;
                if ([strStatus isEqualToString:SERVER_RESULTS_STATUS_SUCCESS]) {
                    result = true;
                } else {
                    //STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Network error.", @"Message request failed.", url, nil, jsonString);
                    if (dictData ) {
                        NSString *failureReason = [dictData objectForKey:@"reason"];
                        NSMutableDictionary* details = [NSMutableDictionary dictionary];
                        [details setValue:dictData forKey:NSLocalizedDescriptionKey];
                        error = [NSError errorWithDomain:failureReason code:400 userInfo:details];
                    }
                    
                }
                
                completionHandler(&result, error);
                
            }];
        [uploadTask resume];
    }
}

#pragma mark - DL_URLServer Callbacks

// this is the results callback from DLURLServer
- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
    SubscriptionsRequest *request = (SubscriptionsRequest *)object;
    
    NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    
    //NSLog(@"Subscriptions: Results download returned: %@", jsonString );
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
    NSDictionary *dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    NSString *strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];
    
    //NSLog(@"decode: %@", dictResults);
    
    STMSubscription *subscription;
    
    if (status == DL_URLRequestStatus_Success)
    {
        if ([strStatus isEqualToString:SERVER_RESULTS_STATUS_SUCCESS])
        {
            NSDictionary *dictData = [dictResults objectForKey:SERVER_RESULTS_DATA_KEY];
            if (dictData) {
                if (request.type == RequestType_SubscriptionsRequest) {
                    subscription = [[STMSubscription alloc] initWithDictionary:[dictData objectForKey:@"subscription"]];
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
        NSDictionary *dictData = [dictResults objectForKey:SERVER_RESULTS_DATA_KEY];
        if (dictData) {
            NSDictionary *dictReason = [dictData objectForKey:@"reason"];
            if (dictReason) {
                if (dictReason) {
                    subscription = nil;
                }
            }
        } else {
            STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"Network error.", @"Message request failed.", request.strURL, nil, jsonString);
        }
    }
    
    if (request.delegate)
    {
        if (request.type == RequestType_SubscriptionsRequest) {
            if ([request.delegate respondsToSelector:@selector(requestForSubscriptionForChannelResult:)])
            {
                [request.delegate requestForSubscriptionForChannelResult:subscription];
            }
        }
    }
}


@end
