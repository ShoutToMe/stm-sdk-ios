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

static void (^uploadRequestBackgroundURLSessionCompletionHandler)() = nil;
static NSString *uploadRequestURLSessionIdentifier = @"me.shoutto.UploadRequest.URLSession.Identifier.";

@implementation STMNetworking

+(void)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler
{
    if (!identifier) {
        return;
    }
    
    if ([identifier hasPrefix:uploadRequestURLSessionIdentifier]) {
        [STMUploadRequest setBackgroundCompletionHandler:completionHandler];
    }
}

@end

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
                                                                           if (completionHandler) {
                                                                               return completionHandler(error, nil);
                                                                           }
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
                                                                               if (completionHandler) {
                                                                                    return completionHandler(httpError, nil);
                                                                               }
                                                                           }
                                                                       }
                                                                       
                                                                       if ([Utils stringIsSet:strJSONResults]) {
                                                                           NSDictionary *dictData = [self extractDataNodeFromJSONString:strJSONResults];
                                                                           return [responseHandlerDelegate processResponseData:[dictData objectForKey:SERVER_RESULTS_DATA_KEY] withCompletionHandler:completionHandler];
                                                                       } else {
                                                                           NSDictionary *userInfo = @{ NSLocalizedDescriptionKey: @"Shout to Me response parsing error" };
                                                                           NSError *parsingError = [NSError errorWithDomain:ShoutToMeErrorDomain code:STMErrorUnknown userInfo:userInfo];
                                                                           if (completionHandler) {
                                                                                return completionHandler(parsingError, nil);
                                                                           }
                                                                       }
                                                                   }];
        [uploadTask resume];
    } else {
        if (completionHandler) {
            completionHandler(error, nil);    
        }
    }

}

- (void)sendInBackground:(NSDictionary *)data toUrl:(NSURL *)url usingHTTPMethod:(NSString *)httpMethod responseType:(NSString *)responseType delegate:(id<STMUploadResponseHandlerDelegate>)delegate
{
    if (delegate) {
        self.delegate = delegate;
    } else {
        self.delegate = nil;
    }
    
    NSString *uuid = [[NSUUID new] UUIDString];
    NSURL *fileUrl = [self persistDataToFileFromDictionary:data withIdentifier:uuid];
    if (fileUrl) {
        NSString *sessionId = [uploadRequestURLSessionIdentifier stringByAppendingString:uuid];
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfigurationWithIdentifier:sessionId];
        NSDictionary *headers = [[UserData controller] dictStandardRequestHeaders];
        [headers setValue:@"application/json" forKey:@"Content-Type"];
        [config setHTTPAdditionalHeaders:headers];
        
        NSURLSession *session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
        NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url];
        urlRequest.HTTPMethod = httpMethod;
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:urlRequest fromFile:fileUrl];
        [uploadTask resume];
    } else {
        NSLog(@"Error persisting json file for background NSURLSession");
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

#pragma mark - NSURLSessionDataDelegate
- (void)URLSession:(NSURLSession *)session dataTask:(NSURLSessionDataTask *)dataTask
    didReceiveData:(NSData *)data
{
    NSString *responseJSON = [self extractJSONStringFromData:data];
    NSDictionary *responseDict = [self extractDataNodeFromJSONString:responseJSON];
    NSDictionary *dataDict = [responseDict objectForKey:SERVER_RESULTS_DATA_KEY];
    if (self.delegate) {
        [self.delegate processResponseData:dataDict withCompletionHandler:nil];
    }
    
    NSString *fileName = [session.configuration.identifier substringFromIndex:[uploadRequestURLSessionIdentifier length]];
    NSString *filePath = [self buildFilePathFromName:fileName];
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
+ (void)setBackgroundCompletionHandler:(void (^)())completionHandler
{
    uploadRequestBackgroundURLSessionCompletionHandler = completionHandler;
}

@end
