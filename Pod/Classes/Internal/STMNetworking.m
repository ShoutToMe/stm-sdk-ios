//
//  STMNetworking.m
//  Pods
//
//  Created by Tracy Rojas on 8/1/17.
//
//

#import "STMNetworking.h"
#import "Server.h"
#import "STM.h"
#import "STMError.h"
#import "UserData.h"
#import "Utils.h"

static void (^uploadRequestBackgroundURLSessionCompletionHandler)(void) = nil;
static NSString *uploadRequestURLSessionIdentifier = @"me.shoutto.UploadRequest.URLSession.Identifier.";

@implementation STMNetworking

+(void)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler
{
    if (!identifier) {
        return;
    }
    
    if ([identifier hasPrefix:uploadRequestURLSessionIdentifier]) {
        [STMBackgroundServerResponse setBackgroundCompletionHandler:completionHandler];
    }
}

@end

@implementation STMServerResponse

- (id)init
{
    self = [super init];
    if (self)
    {
        
    }
    return self;
}

- (id)initWithData:(NSData *)data andNSURLResponse:(NSURLResponse *)nsURLResponse
{
    self = [super init];
    if (self)
    {
        [self setPropertiesFromData:data andNSURLResponse:nsURLResponse];
    }
    return self;
}

- (void)setPropertiesFromData:(NSData *)data andNSURLResponse:(NSURLResponse *)nsURLResponse
{
    NSString *strJSONResults = [self extractJSONStringFromData:data];
    NSDictionary *responseDict = [NSDictionary new];
    if ([Utils stringIsSet:strJSONResults]) {
        responseDict = [self extractDataNodeFromJSONString:strJSONResults];
    } else {
        NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Shout to Me response parsing error" };
        self.error = [NSError errorWithDomain:ShoutToMeErrorDomain code:STMErrorUnknown userInfo:userInfo];
        return;
    }
    
    NSInteger statusCode = 0;
    if ([nsURLResponse respondsToSelector:@selector(statusCode)]) {
        statusCode = [(NSHTTPURLResponse *) nsURLResponse statusCode];
    }
    
    if ((statusCode && (statusCode < 200 || statusCode > 299))
            || [@"fail" isEqual:[responseDict objectForKey:@"status"]]
            || [@"error" isEqual:[responseDict objectForKey:@"status"]]) {
        NSLog(@"Shout to Me Error - Response JSON: %@", strJSONResults);
        
        NSString *errorMessage;
        if ([responseDict valueForKey:@"message"]) {
            errorMessage = [responseDict valueForKey:@"message"];
        } else if ([responseDict objectForKey:@"data"]) {
            errorMessage = [NSString stringWithFormat:@"%@", [responseDict objectForKey:@"data"]];
        }
        
        if (!errorMessage) {
            if (statusCode == 401) {
                errorMessage = @"Shout to Me Authorization Error";
            } else if (statusCode >= 400 && statusCode < 500) {
                errorMessage = @"Shout to Me Application Error";
            } else if (statusCode >= 500) {
                errorMessage = @"Shout to Me Server Error";
            } else {
                errorMessage = [NSString stringWithFormat:@"Unknown HTTP status code %ld", (long)statusCode];
            }
        }
        
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:errorMessage forKey:NSLocalizedDescriptionKey];
        NSError *httpError = [NSError errorWithDomain:ShoutToMeErrorDomain code:statusCode userInfo:details];
        self.error = httpError;
        return;
    }
    
    self.responseDict = [self extractDataNodeFromJSONString:strJSONResults];
}

#pragma mark - Helper methods
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

@implementation STMBackgroundServerResponse

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    NSString *responseJSON = [self extractJSONStringFromData:data];
    NSDictionary *responseDict = [self extractDataNodeFromJSONString:responseJSON];
    NSDictionary *dataDict = [responseDict objectForKey:SERVER_RESULTS_DATA_KEY];
    
    if (!dataDict) {
        NSLog(@"Shout to Me response - 'data' node not found in responseJSON. responseJSON is: %@", responseJSON);
    }
    
    if (self.delegate) {
        [self.delegate processResponseData:dataDict withCompletionHandler:nil];
    }
    
    STMBackgroundRequestFileManager *stmBackgroundRequestFileManager = [STMBackgroundRequestFileManager new];
    NSString *fileName = [session.configuration.identifier substringFromIndex:[uploadRequestURLSessionIdentifier length]];
    NSString *filePath = [stmBackgroundRequestFileManager buildFilePathFromName:fileName];
    NSError *error;
    [[NSFileManager defaultManager] removeItemAtPath:filePath error:&error];
    if (error) {
        NSString *errorDetails = [NSString stringWithFormat:@"Error message= %@. File path=%@",error.localizedDescription, filePath];
        STM_ERROR(ErrorCategory_Internal, ErrorSeverity_Warning, @"Error occurred removing temporary JSON file from Application Support directory", errorDetails, nil, nil, responseJSON);
    }
}

#pragma mark - NSURLSessionDelegate

- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session {
    if (uploadRequestBackgroundURLSessionCompletionHandler) {
        uploadRequestBackgroundURLSessionCompletionHandler();
        uploadRequestBackgroundURLSessionCompletionHandler = nil;
    }
}

- (void)URLSession:(NSURLSession *)session didBecomeInvalidWithError:(NSError *)error {
    STM_ERROR(ErrorCategory_Internal, ErrorSeverity_Warning, @"NSURLSession became invalid", error.localizedDescription, nil, nil, nil);
}

#pragma mark - STMBackgroundSession
+ (void)setBackgroundCompletionHandler:(void (^)(void))completionHandler
{
    uploadRequestBackgroundURLSessionCompletionHandler = completionHandler;
}

@end

@implementation STMBaseHTTPRequest

- (NSURLSession *)buildSession
{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    [config setHTTPAdditionalHeaders:[self buildHeaders]];
    return [NSURLSession sessionWithConfiguration:config];
}

- (NSURLSession *)buildBackgroundSession:(NSString *)sessionId delegate:(id<STMHTTPResponseHandlerDelegate>)delegate
{
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:sessionId];
    [config setHTTPAdditionalHeaders:[self buildHeaders]];
    STMBackgroundServerResponse *stmBackgroundServerResponse = [STMBackgroundServerResponse new];
    stmBackgroundServerResponse.delegate = delegate;
    return [NSURLSession sessionWithConfiguration:config delegate:stmBackgroundServerResponse delegateQueue:nil];
}

- (NSDictionary *)buildHeaders
{
    NSDictionary *headers = [[UserData controller] dictStandardRequestHeaders];
    [headers setValue:@"application/json" forKey:@"Content-Type"];
    return headers;
}

- (void)processServerResultsWithData:(NSData *)responseData URLResponse:(NSURLResponse *)urlResponse responseHandlerDelegate:(id<STMHTTPResponseHandlerDelegate>)responseHandlerDelegate andCompletionHandler:(void(^)(NSError *, id))completionHandler
{
    STMServerResponse *stmServerResponse = [[STMServerResponse alloc] initWithData:responseData andNSURLResponse:urlResponse];

    if (stmServerResponse.error) {
        if (completionHandler) {
            completionHandler(stmServerResponse.error, nil);
        }
        return;
    }
    
    if (responseHandlerDelegate) {
        return [responseHandlerDelegate processResponseData:[stmServerResponse.responseDict objectForKey:SERVER_RESULTS_DATA_KEY]
                                      withCompletionHandler:completionHandler];
    }
    
    if (completionHandler) {
        completionHandler(nil, [stmServerResponse.responseDict objectForKey:SERVER_RESULTS_DATA_KEY]);
    }
}

@end

@implementation STMUploadRequest

- (void)send:(NSDictionary *)data toUrl:(NSURL *)url usingHTTPMethod:(NSString *)httpMethod responseHandlerDelegate:(id<STMHTTPResponseHandlerDelegate>)responseHandlerDelegate withCompletionHandler:(void (^)(NSError *, id))completionHandler
{
    NSError *error = nil;
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:data
                                                   options:kNilOptions error:&error];

    if (!error) {
        [self sendJSON:requestData toUrl:url usingHTTPMethod:httpMethod responseHandlerDelegate:responseHandlerDelegate withCompletionHandler:completionHandler];
    } else {
        if (completionHandler) {
            completionHandler(error, nil);    
        }
    }

}

- (void)sendJSON:(NSData *)json toUrl:(NSURL *)url usingHTTPMethod:(NSString *)httpMethod responseHandlerDelegate:(id<STMHTTPResponseHandlerDelegate>)responseHandlerDelegate withCompletionHandler:(void (^)(NSError *, id))completionHandler
{
    NSURLSession *session = [self buildSession];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = httpMethod;
    NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                               fromData:json
                                                      completionHandler:^(NSData *responseData, NSURLResponse *urlResponse, NSError *error) {
                                                          [self processServerResultsWithData:responseData
                                                                                 URLResponse:urlResponse
                                                                     responseHandlerDelegate:responseHandlerDelegate
                                                                        andCompletionHandler:completionHandler];
                                                      }];
    [uploadTask resume];
}

- (void)sendInBackground:(NSDictionary *)data toUrl:(NSURL *)url usingHTTPMethod:(NSString *)httpMethod responseType:(NSString *)responseType delegate:(id<STMHTTPResponseHandlerDelegate>)delegate
{
    NSString *uuid = [[NSUUID new] UUIDString];
    STMBackgroundRequestFileManager *stmBackgroundRequestFileManager = [STMBackgroundRequestFileManager new];
    NSURL *fileUrl = [stmBackgroundRequestFileManager persistDataToFileFromDictionary:data withIdentifier:uuid];
    if (fileUrl) {
        NSString *sessionId = [uploadRequestURLSessionIdentifier stringByAppendingString:uuid];
        NSURLSession *session = [self buildBackgroundSession:sessionId delegate:delegate];
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
        urlRequest.HTTPMethod = httpMethod;
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:urlRequest fromFile:fileUrl];
        [uploadTask resume];
    } else {
        NSLog(@"Error persisting json file for background NSURLSession");
    }
}

@end

@implementation STMDataRequest

- (void)sendToUrl:(NSURL *)url responseHandlerDelegate:(id<STMHTTPResponseHandlerDelegate>)responseHandlerDelegate withCompletionHandler:(void (^)(NSError *, id))completionHandler
{
    NSURLSession *session = [self buildSession];
    NSURLSessionDataTask *dataTask = [session dataTaskWithURL:url
                                            completionHandler:^(NSData *responseData,
                                                                NSURLResponse *urlResponse,
                                                                NSError *error) {
                                                [self processServerResultsWithData:responseData
                                                                       URLResponse:urlResponse
                                                           responseHandlerDelegate:responseHandlerDelegate
                                                              andCompletionHandler:completionHandler];
                                            }];
    [dataTask resume];
}

@end

@implementation STMBackgroundRequestFileManager

- (NSURL *)persistDataToFileFromDictionary:(NSDictionary *)dict withIdentifier:(NSString *)identifier
{
    NSError *error = nil;
    NSData *dataJSON = [NSJSONSerialization dataWithJSONObject:dict options:kNilOptions error:&error];
    if (error) {
        NSString *dataDictionaryDump = [NSString stringWithFormat:@"%@", dict];
        STM_ERROR(ErrorCategory_Internal, ErrorSeverity_Warning, @"Error occurred converting data dictionary to JSON", error.localizedDescription, nil, nil, dataDictionaryDump);
        return nil;
    }
    
    NSString *filePath = [self buildFilePathFromName:identifier];
    if (filePath) {
        BOOL fileCreateResult = [dataJSON writeToFile:filePath atomically:YES];
        if (fileCreateResult) {
            return [NSURL fileURLWithPath:filePath];
        } else {
            NSString *errorDetails = [NSString stringWithFormat:@"File path: %@", filePath];
            STM_ERROR(ErrorCategory_Internal, ErrorSeverity_Warning, @"Error occurred creating temporary JSON file in Application Support directory", errorDetails, nil, nil, nil);
            return nil;
        }
    } else {
        return nil;
    }
}

- (NSString *)buildFilePathFromName:(NSString *)fileName
{
    if (!fileName) {
        NSLog(@"Cannot call buildFilePathFromName where fileName=nil");
        return nil;
    }
    
    NSError *error;
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSString *libraryPath = [NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES) objectAtIndex:0];
    BOOL isDirectory = NO;
    BOOL directoryExists = [fileManager fileExistsAtPath:libraryPath isDirectory:&isDirectory];
    
    if (!directoryExists || !isDirectory) {
        BOOL directoryCreated = [fileManager createDirectoryAtPath:libraryPath withIntermediateDirectories:YES attributes:nil error:&error];
        if (!directoryCreated) {
            STM_ERROR(ErrorCategory_Internal, ErrorSeverity_Warning, @"Error occurred creating Application Support directory", error.localizedDescription, nil, nil, nil);
            return nil;
        }
    }
    
    NSString *filePath = [libraryPath stringByAppendingPathComponent:[NSString stringWithFormat:@"%@.json", fileName]];
    return filePath;
}

@end
