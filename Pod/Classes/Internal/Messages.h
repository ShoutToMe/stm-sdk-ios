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
- (void)UnreadMessageResults:(NSNumber *)count;

@end

@interface Messages : NSObject

+ (void)initAll;
+ (void)freeAll;

+ (Messages *)controller;

- (void)requestForMessagesWithDelegate:(id<MessagesDelegate>)delegate;
- (void)requestForUnreadMessageCountWithDelegate:(id<MessagesDelegate>)delegate;
- (void)requestForMessage:(NSString *)messageId completionHandler:(void (^)(STMMessage *message,
                                                                            NSError *error))completionHandler;
- (void)cancelAllRequests;


@end