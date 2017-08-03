//
//  STMNetworking.m
//  Pods
//
//  Created by Tracy Rojas on 8/1/17.
//
//

#import "STMNetworking.h"
#import "Server.h"
#import "STMError.h"
#import "UserData.h"
#import "Utils.h"

@implementation STMUploadRequest

- (void)send:(NSDictionary *)data toUrl:(NSURL *)url usingHTTPMethod:(NSString *)httpMethod responseHandlerDelegate:(id<STMUploadResponseHandlerDelegate>)responseHandlerDelegate withCompletionHandler:(void (^)(NSError *, id))completionHandler
{
    NSError *error = nil;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:data
                                                   options:kNilOptions error:&error];
    
    if (!error) {
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
        NSDictionary *headers = [[UserData controller] dictStandardRequestHeaders];
        [headers setValue:@"application/json" forKey:@"Content-Type"];
        [config setHTTPAdditionalHeaders:headers];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
        request.HTTPMethod = httpMethod;
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                                   fromData:requestData completionHandler:^(NSData *responseData, NSURLResponse *response, NSError *error) {
                                                                       
                                                                       if (error) {
                                                                           return completionHandler(error, nil);
                                                                       }
                                                                       
                                                                       NSString *strJSONResults = [self extractJSONStringFromData:responseData];
                                                                       
                                                                       // Handle non-successful HTTP status codes
                                                                       if ([response respondsToSelector:@selector(statusCode)]) {
                                                                           NSInteger statusCode = [(NSHTTPURLResponse *) response statusCode];
                                                                           if (statusCode < 200 || statusCode > 299) {
                                                                               NSLog(@"Shout to Me Error - Response JSON: %@", strJSONResults);
                                                                               
                                                                               NSMutableDictionary* details = [NSMutableDictionary dictionary];
                                                                               if (statusCode == 401) {
                                                                                   [details setValue:@"Shout to Me Authorization Error" forKey:NSLocalizedDescriptionKey];
                                                                               } else if (statusCode >= 400 && statusCode < 500) {
                                                                                   [details setValue:@"Shout to Me Application Error" forKey:NSLocalizedDescriptionKey];
                                                                               } else if (statusCode >= 500) {
                                                                                   [details setValue:@"Shout to Me Server Error" forKey:NSLocalizedDescriptionKey];
                                                                               } else {
                                                                                   [details setValue:[NSString stringWithFormat:@"Unknown HTTP status code %ld", (long)statusCode] forKey:NSLocalizedDescriptionKey];
                                                                               }
                                                                               
                                                                               NSError *httpError = [NSError errorWithDomain:ShoutToMeErrorDomain code:statusCode userInfo:details];
                                                                               return completionHandler(httpError, nil);
                                                                           }
                                                                       }
                                                                       
                                                                       if ([Utils stringIsSet:strJSONResults]) {
                                                                           NSDictionary *dictData = [self extractDataNodeFromJSONString:strJSONResults];
                                                                           return [responseHandlerDelegate processResponseData:[dictData objectForKey:SERVER_RESULTS_DATA_KEY] withCompletionHandler:completionHandler];
                                                                       } else {
                                                                           NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Shout to Me response parsing error" };
                                                                           NSError *parsingError = [NSError errorWithDomain:ShoutToMeErrorDomain code:STMErrorUnknown userInfo:userInfo];
                                                                           return completionHandler(parsingError, nil);
                                                                       }
                                                                   }];
        [uploadTask resume];
    } else {
        completionHandler(error, nil);
    }

}

- (NSString *)extractJSONStringFromData:(NSData *)data
{
    NSString *strJSONResults = nil;
    if (data && [data length]) {
        strJSONResults = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    }
    return strJSONResults;
}

- (NSDictionary *)extractDataNodeFromJSONString:(NSString *)strJSON
{
    NSData *jsonData = [strJSON dataUsingEncoding:NSUTF32BigEndianStringEncoding];
    return [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
}

@end
