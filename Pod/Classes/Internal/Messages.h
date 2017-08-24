//
//  Messages.h
//  Pods
//
//  Created by Tyler Clemens on 6/2/16.
//
//

#import <Foundation/Foundation.h>
#import "STMMessage.h"

@protocol MessagesDelegate <NSObject>

@optional

- (void)MessagesResults:(NSArray *_Nullable)arrayMessages;
- (void)UnreadMessageResults:(NSNumber *_Nullable)count;

@end

@interface Messages : NSObject <STMHTTPResponseHandlerDelegate>

+ (void)initAll;
+ (void)freeAll;

+ (Messages *_Nonnull)controller;

- (void)requestForMessagesWithDelegate:(id<MessagesDelegate> _Nullable)delegate;
- (void)requestForUnreadMessageCountWithDelegate:(id<MessagesDelegate> _Nullable)delegate;
- (void)requestForMessage:(NSString * _Nonnull)messageId completionHandler:(void (^_Nullable)(NSError *_Nullable, id _Nullable))completionHandler;
- (void)cancelAllRequests;


@end
