//
//  STMNetworking.h
//  Pods
//
//  Created by Tracy Rojas on 8/1/17.
//
//

#import <Foundation/Foundation.h>

@protocol STMHTTPResponseHandlerDelegate <NSObject>

- (void)processResponseData:(NSDictionary *)responseData withCompletionHandler:(void (^)(NSError *, id))completionHandler;

@end

@protocol STMBackgroundSession <NSObject>

+ (void)setBackgroundCompletionHandler:(void (^)(void))completionHandler;

@end

@interface STMNetworking : NSObject

+ (void)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)(void))completionHandler;

@end

@interface STMServerResponse : NSObject

@property NSError *error;
@property NSDictionary *responseDict;

- (id)initWithData:(NSData *)data andNSURLResponse:(NSURLResponse *)nsURLResponse;

@end

@interface STMBackgroundServerResponse : STMServerResponse <NSURLSessionDataDelegate, STMBackgroundSession>

@property id<STMHTTPResponseHandlerDelegate> delegate;

@end

@interface STMBaseHTTPRequest : NSObject

@end

@interface STMUploadRequest : STMBaseHTTPRequest

- (void)send:(NSDictionary *)data toUrl:(NSURL *)url usingHTTPMethod:(NSString *)httpMethod responseHandlerDelegate:(id<STMHTTPResponseHandlerDelegate>)responseHandlerDelegate withCompletionHandler:(void (^)(NSError *, id))completionHandler;

- (void)sendInBackground:(NSDictionary *)data toUrl:(NSURL *)url usingHTTPMethod:(NSString *)httpMethod responseType:(NSString *)responseType delegate:(id<STMHTTPResponseHandlerDelegate>)delegate;

@end

@interface STMDataRequest : STMBaseHTTPRequest

@property id<STMHTTPResponseHandlerDelegate> delegate;

- (void)sendToUrl:(NSURL *)url responseHandlerDelegate:(id<STMHTTPResponseHandlerDelegate>)responseHandlerDelegate withCompletionHandler:(void (^)(NSError *, id))completionHandler;

@end

@interface STMBackgroundRequestFileManager : NSObject

- (NSURL *)persistDataToFileFromDictionary:(NSDictionary *)dict withIdentifier:(NSString *)identifier;
- (NSString *)buildFilePathFromName:(NSString *)fileName;

@end
