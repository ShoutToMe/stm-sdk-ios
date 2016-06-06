//
//  SendShout.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 12/08/14.
//  Copyright 2014 Ditty Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Settings.h"

// this is singleton object class
// this means it has static methods that create on instance of itself for use by all

typedef enum eSendShoutStatus
{
    SendShoutStatus_NotStarted,
    SendShoutStatus_Success,
    SendShoutStatus_Failure
} tSendShoutStatus;

@protocol SendShoutDelegate <NSObject>

@optional

- (void)onSendShoutCompleteWithStatus:(tSendShoutStatus)status;
- (void)onSendShoutCompleteWithShout:(STMShout *) shout WithStatus:(tSendShoutStatus)status;
- (void)onUndoLastSendCompleteWithStatus:(tSendShoutStatus)status;

@end


@interface SendShout : NSObject

+ (void)initAll;
+ (void)freeAll;

+ (SendShout *)controller;

- (void)sendData:(NSData *)dataShout text:(NSString *)strText replyToId:(NSString *)strReplyToId tags:(NSString *)tags topic:(NSString *)topic withDelegate:(id<SendShoutDelegate>)delegate;
- (void)sendData:(NSData *)dataShout text:(NSString *)strText replyToId:(NSString *)strReplyToId withDelegate:(id<SendShoutDelegate>)delegate;
- (void)undoLastSend;
- (void)undoLastSendWithDelegate:(id<SendShoutDelegate>)delegate;
- (NSDate *)dateOfLastSend;
- (STMShout *)lastSentShout;

@end

