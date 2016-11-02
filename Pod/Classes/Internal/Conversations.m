//
//  Conversations.m
//  Pods
//
//  Created by Tyler Clemens on 9/7/16.
//
//

#import "Utils.h"
#import "Settings.h"
#import "DL_URLServer.h"
#import "UserData.h"
#import "Conversations.h"

#import "Server.h"


static BOOL bInitialized = NO;

__strong static Conversations *singleton = nil; // this will be the one and only object this static singleton class has


@interface Conversations () <DL_URLRequestDelegate>
{
}

@end

@implementation Conversations

#pragma mark - Static methods

+ (void)initAll
{
    if (NO == bInitialized)
    {
        [DL_URLServer initAll];
        
        singleton = [[Conversations alloc] init];
        
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
+ (Conversations *)controller
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

#pragma mark - Public Methods

- (void)requestForConversation:(NSString *)conversationId completionHandler:(void (^)(STMConversation *, NSError *))completionHandler {
    
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@",
                     [Settings controller].strServerURL,
                     SERVER_CMD_GET_CONVERSATIONS,
                     conversationId];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    [config setHTTPAdditionalHeaders:[[UserData controller] dictStandardRequestHeaders]];
    
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    [[session dataTaskWithURL:[NSURL URLWithString:url]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                
                NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
                
                //NSLog(@"Conversations: Results download returned: %@", jsonString );
                
                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
                NSDictionary *dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                NSString *strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];
                NSDictionary *dictData = [dictResults objectForKey:SERVER_RESULTS_DATA_KEY];
                
                
                STMConversation *conversation;
                
                if ([strStatus isEqualToString:SERVER_RESULTS_STATUS_SUCCESS]) {
                    
                    if (dictData)
                    {
                        conversation = [[STMConversation alloc] initWithDictionary:[dictData objectForKey:@"conversation"]];
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
                
                completionHandler(conversation, error);
                
            }] resume];
}

- (void)requestForSeenConversation:(NSString *)conversationId completionHandler:(void (^)(BOOL, NSError *))completionHandler {
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@",
                     [Settings controller].strServerURL,
                     SERVER_CMD_GET_MESSAGES,
                     [NSString stringWithFormat:@"?conversation_id=%@&count_only=true", conversationId]];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    [config setHTTPAdditionalHeaders:[[UserData controller] dictStandardRequestHeaders]];
    
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    [[session dataTaskWithURL:[NSURL URLWithString:url]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                
                NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
                
                //NSLog(@"Conversations Count: Results download returned: %@", jsonString );
                
                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
                NSDictionary *dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                NSString *strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];
                NSDictionary *dictData = [dictResults objectForKey:SERVER_RESULTS_DATA_KEY];
                
                
                BOOL seen = false;
                
                if ([strStatus isEqualToString:SERVER_RESULTS_STATUS_SUCCESS]) {
                    
                    if (dictData)
                    {
                        seen = [Utils boolFromKey:@"count" inDictionary:dictData];
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
                completionHandler(seen, error);
                
            }] resume];
}

- (void)requestForActiveConversationWith:(NSString *)channelId completionHandler:(void (^)(NSArray<STMConversation *> *, NSError *))completionHandler {
    NSString *url = [NSString stringWithFormat:@"%@/%@/%@",
                     [Settings controller].strServerURL,
                     SERVER_CMD_GET_CONVERSATIONS,
                     [NSString stringWithFormat:@"?channel_id=%@&hours=0&date_field=expiration_date", channelId]
                    ];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    [config setHTTPAdditionalHeaders:[[UserData controller] dictStandardRequestHeaders]];
    
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    
    [[session dataTaskWithURL:[NSURL URLWithString:url]
            completionHandler:^(NSData *data,
                                NSURLResponse *response,
                                NSError *error) {
                
                NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
                
                //NSLog(@"Conversations: Results download returned: %@", jsonString );
                
                NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
                NSDictionary *dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                NSString *strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];
                NSDictionary *dictData = [dictResults objectForKey:SERVER_RESULTS_DATA_KEY];
                
                
                NSArray<STMConversation *> *conversations;
                
                if ([strStatus isEqualToString:SERVER_RESULTS_STATUS_SUCCESS]) {
                    
                    if (dictData)
                    {
                        conversations = [self processConversationsResults:[dictData objectForKey:@"conversations"]];
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
                
                completionHandler(conversations, error);
                
            }] resume];

}

#pragma mark - Misc Methods


// process the results returned from the server
- (NSArray<STMConversation *> *)processConversationsResults:(NSObject *)results
{
    NSMutableArray<STMConversation *> *arrayConversations = [[NSMutableArray alloc] init];
    
    if ([results isKindOfClass:[NSDictionary class]])
    {
        STMConversation *conversation = [[STMConversation alloc] initWithDictionary:(NSDictionary *)results];
        [arrayConversations addObject:conversation];
    }
    else if ([results isKindOfClass:[NSArray class]])
    {
        NSArray *arrayConversationDictionaries = (NSArray *)results;
        for (NSDictionary *dictConversation in arrayConversationDictionaries)
        {
            STMConversation *conversation = [[STMConversation alloc] initWithDictionary:dictConversation];
            [arrayConversations addObject:conversation];
        }
    }
    
    return arrayConversations;
}
@end
