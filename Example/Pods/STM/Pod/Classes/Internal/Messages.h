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

- (void)MessagesResults:(NSArray *)arrayMessages;

@end

@interface Messages : NSObject

+ (void)initAll;
+ (void)freeAll;

+ (Messages *)controller;

- (void)requestForMessagesWithChannelId:(NSString *)channelId AndDelegate:(id<MessagesDelegate>)delegate;
- (void)requestForMessagesWithRecipientId:(NSString *)recipientId AndDelegate:(id<MessagesDelegate>)delegate;
- (void)requestForMessagesWithChannelId:(NSString *)channelId AndLastSeenDate:(NSDate *)lastSeenDate AndDelegate:(id<MessagesDelegate>)delegate;
- (void)requestForMessagesWithRecipientId:(NSString *)recipientId AndLastSeenDate:(NSDate *)lastSeenDate AndDelegate:(id<MessagesDelegate>)delegate;
- (void)requestForMessage:(NSString *)messageId completionHandler:(void (^)(STMMessage *message,
                                                                            NSError *error))completionHandler;
- (void)cancelAllRequests;


@end