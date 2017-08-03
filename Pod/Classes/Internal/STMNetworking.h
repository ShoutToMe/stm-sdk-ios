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

@interface STMUploadRequest : NSObject

- (void)send:(NSDictionary *)data toUrl:(NSURL *)url usingHTTPMethod:(NSString *)httpMethod responseHandlerDelegate:(id<STMUploadResponseHandlerDelegate>)responseHandlerDelegate withCompletionHandler:(void (^)(NSError *, id))completionHandler;

@end
