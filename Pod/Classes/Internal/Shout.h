//
//  SendShout.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 12/08/14.
//  Copyright 2014 Ditty Labs. All rights reserved.
//

#import <AWSS3/AWSS3.h>
#import <Foundation/Foundation.h>
#import "Settings.h"
#import "STMNetworking.h"
#import "STMShout.h"

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

@protocol CreateShoutDelegate <NSObject>

-(void)shoutCreated:(STMShout*)shout error:(NSError*)err;

@end

@interface SendShoutDelegateHandler : NSObject<SendShoutDelegate>

@property (weak) id<CreateShoutDelegate> createShoutDelegate;

- (void)onSendShoutCompleteWithShout:(STMShout *) shout WithStatus:(tSendShoutStatus)status;

@end

@interface Shout : NSObject <STMUploadResponseHandlerDelegate>

@property SendShoutDelegateHandler *sendShoutDelegate;

+ (void)initAll;
+ (void)freeAll;

+ (Shout *)controller;

- (void)uploadFromFile:(NSURL *)localFileURL text:(NSString *)text tags:(NSString *)tags topic:(NSString *)topic description:(NSString *)description withDelegate:(id<CreateShoutDelegate>)delegate;
- (void)sendData:(NSData *)dataShout text:(NSString *)strText replyToId:(NSString *)strReplyToId tags:(NSString *)tags topic:(NSString *)topic withDelegate:(id<SendShoutDelegate>)delegate;
- (void)sendData:(NSData *)dataShout text:(NSString *)strText replyToId:(NSString *)strReplyToId withDelegate:(id<SendShoutDelegate>)delegate;
- (void)sendFile:(NSURL *)localFileURL text:(NSString *)strText tags:(NSString *)tags topic:(NSString *)topic description:(NSString *)description;
- (void)undoLastSend;
- (void)undoLastSendWithDelegate:(id<SendShoutDelegate>)delegate;
- (NSDate *)dateOfLastSend;
- (STMShout *)lastSentShout;

@end

