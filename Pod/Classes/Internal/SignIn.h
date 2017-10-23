//
//  SignIn.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 11/17/14.
//  Copyright 2014 Ditty Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Settings.h"

typedef enum eSTMSignInResult
{
    STMSignInResult_Success = 0,
    STMSignInResult_AlreadyServicing = 1,       // already servicing another call (only one allowed at a time)
    STMSignInResult_UnknownError = 2,
    STMSignInResult_CommError = 3,              // communication error
    STMSignInResult_Fail = 4,                   // server specifies failure
    STMSignInResult_InvalidVerificationCode = 5,
    STMSignInResult_HandleTaken = 6,
    STMSignInResult_UserAlreadyExists = 7,
    STMSignInResult_UserNotFound = 8,
    STMSignInResult_InvalidPhone = 9,
    STMSignInResult_InvalidAuthCode = 10
} tSTMSignInResult;

@protocol STMSignInDelegate <NSObject>

@required

@optional

- (void)STMSignInResult:(tSTMSignInResult)result;

@end

// this is singleton object class
// this means it has static methods that create on instance of itself for use by all

@interface SignIn : NSObject <STMSignInDelegate>

+ (void)initAll;
+ (void)freeAll;

+ (SignIn *)controller;

- (BOOL)isSignedIn;
- (void)signOut;
- (void)signInCheckAuthCodeWithDelegate:(id<STMSignInDelegate>)delegate;
- (void)signInAnonymousWithDelegate:(id<STMSignInDelegate>)delegate;
- (void)requestVerificationCodeWithPhone:(NSString *)strPhone andDelegate:(id<STMSignInDelegate>)delegate;
- (void)signInWithPhone:(NSString *)strPhone andCode:(NSString *)strCode andDelegate:(id<STMSignInDelegate>)delegate;
- (void)signUpWithPhone:(NSString *)strPhone andCode:(NSString *)strCode andDelegate:(id<STMSignInDelegate>)delegate;
- (void)verifyWithPhone:(NSString *)strPhone andCode:(NSString *)strCode andDelegate:(id<STMSignInDelegate>)delegate;
- (void)setHandle:(NSString *)strHandle withCompletionHandler:(void (^)(NSError *))completionHandler __deprecated_msg("Use [[STM user] setProperties:withCompletionHandler] instead");
- (void)setPlatformEndpointArn:(NSString *)platformEndpointArn withCompletionHandler:(void (^)(NSError *))completionHandler;
- (void)processData:(NSDictionary *)dictData;

@end



