//
//  STMNetworking.h
//  Pods
//
//  Created by Tracy Rojas on 8/1/17.
//
//

#import <Foundation/Foundation.h>

@protocol STMUploadResponseHandlerDelegate <NSObject>

- (void)processResponseData:(NSDictionary *)responseData withCompletionHandler:(void (^)(NSError *, id))completionHandler;

@end

@protocol STMBackgroundSession <NSObject>

+ (void)setBackgroundCompletionHandler:(void (^)())completionHandler;

@end

@interface STMNetworking : NSObject

+ (void)handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler;

@end

@interface STMUploadRequest : NSObject <NSURLSessionDataDelegate, STMBackgroundSession>

@property id<STMUploadResponseHandlerDelegate> delegate;

- (void)send:(NSDictionary *)data toUrl:(NSURL *)url usingHTTPMethod:(NSString *)httpMethod responseHandlerDelegate:(id<STMUploadResponseHandlerDelegate>)responseHandlerDelegate withCompletionHandler:(void (^)(NSError *, id))completionHandler;

- (void)sendInBackground:(NSDictionary *)data toUrl:(NSURL *)url usingHTTPMethod:(NSString *)httpMethod responseType:(NSString *)responseType delegate:(id<STMUploadResponseHandlerDelegate>)delegate;

@end
