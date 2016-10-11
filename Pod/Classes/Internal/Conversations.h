//
//  Conversations.h
//  Pods
//
//  Created by Tyler Clemens on 9/7/16.
//
//

#import <Foundation/Foundation.h>
#import "STMConversation.h"

@protocol ConversationsDelegate <NSObject>

@optional

- (void)ConversationsResults:(NSArray *)arrayConversations;

@end

@interface Conversations : NSObject

+ (void)initAll;
+ (void)freeAll;

+ (Conversations *)controller;

- (void)requestForConversation:(NSString *)conversationId completionHandler:(void (^)(STMConversation *conversation,
                                                                            NSError *error))completionHandler;
- (void)requestForSeenConversation:(NSString *)conversationId completionHandler:(void (^)(BOOL seen,
                                                                                      NSError *error))completionHandler;
- (void)requestForActiveConversationWith:(NSString *)channelId completionHandler:(void (^)(NSArray<STMConversation *> *conversations, NSError *error))completionHandler;
@end
