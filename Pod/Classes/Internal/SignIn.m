//
//  SignIn.m
//  ShoutToMeDev
//
//  Description:
//      This module provides the functionality associated with user sign-in and acccount creation
//
//  Created by Adam Harris on 11/17/14.
//  Copyright 2014 Ditty Labs. All rights reserved.
//

#import "STM.h"
#import "Utils.h"
#import "Settings.h"
#import "SignIn.h"
#import "DL_URLServer.h"
#import "Server.h"
#import "UserData.h"

typedef enum eSignInRequestType
{
    SignInRequestType_None = 0,
    SignInRequestType_SignInAnonymous,
    SignInRequestType_SignIn,
    SignInRequestType_SignUp,
    SignInRequestType_VerifyAccount,
    SignInRequestType_SetHandle,
    SignInRequestType_SetLastReadMessages,
    SignInRequestType_SetPlatformEndpointARN,
    SignInRequestType_VerificationCode,
    SignInRequestType_CheckAuthCode
} tSignInRequestType;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface SignInRequest : NSObject
{
}

@property (nonatomic, assign)   tSignInRequestType      type;
@property (nonatomic, copy)     NSString                *strRequestURL;
@property (nonatomic, strong)   NSMutableDictionary     *dictRequestData;
@property (nonatomic, weak)     id<STMSignInDelegate>   delegate;
@property (nonatomic, assign)   tSTMSignInResult        result;
@property (nonatomic, copy)     NSString                *strJSONResults;

@end

@implementation SignInRequest

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

static BOOL bInitialized = NO;

__strong static SignIn *singleton = nil; // this will be the one and only object this static singleton class has

@interface SignIn () <DL_URLRequestDelegate, STMSignInDelegate>
{

}

@property (nonatomic, strong)   SignInRequest   *request;

@end

@implementation SignIn

#pragma mark - Static methods

+ (void)initAll
{
	if (NO == bInitialized)
	{
        [Settings initAll];
        [DL_URLServer initAll];

        singleton = [[SignIn alloc] init];

		bInitialized = YES;
	}
}

+ (void)freeAll
{
	if (YES == bInitialized)
	{
        // release our singleton
        singleton = nil;
		
		bInitialized = NO;
	}
}

// returns the singleton 
// (this call is both a container and an object class and the container holds one of itself)
+ (SignIn *)controller
{
    return (singleton);
}

#pragma mark - Object Methods

- (id)init
{
    self = [super init];
    if (self) 
	{

    }
    return self;
}

- (void)dealloc
{
    [[DL_URLServer controller] cancelAllRequestsForDelegate:self];
}

// overriding the description - used in debugging
- (NSString *)description
{
    return(@"SignIn");
}

#pragma mark - Misc Methods

// send the sign-in results to the delegate
- (void)sendResult:(tSTMSignInResult)result toDelegate:(id<STMSignInDelegate>)delegate
{
    if (delegate)
    {
        if ([delegate respondsToSelector:@selector(STMSignInResult:)])
        {
            [delegate STMSignInResult:result];
        }
    }
}

// process the data coming back from the server
- (void)processData:(NSDictionary *)dictData
{
    if (dictData)
    {
        NSString *strAuthCode = [dictData objectForKey:SERVER_RESULTS_AUTH_TOKEN_KEY];
        if (strAuthCode)
        {
            [[UserData controller].user setStrAuthCode:strAuthCode];
        }

        NSDictionary *dictUser = [dictData objectForKey:SERVER_RESULTS_USER_KEY];
        if (dictUser)
        {
            NSString *strUserID = [dictUser objectForKey:SERVER_RESULTS_USER_ID_KEY];
            if (strUserID)
            {
                [[UserData controller].user setStrUserID:strUserID];
            }
            NSString *strHandle = [dictUser objectForKey:SERVER_RESULTS_HANDLE_ID_KEY];
            if (strHandle)
            {
                [[UserData controller].user setStrHandle:strHandle];
            }
            if ([dictUser objectForKey:SERVER_RESULTS_VERIFIED_KEY])
            {
                [[UserData controller].user setBVerified:[Utils boolFromKey:SERVER_RESULTS_VERIFIED_KEY inDictionary:dictUser]];
            }
            NSDate *dateLastViewedMessages = [dictUser objectForKey:SERVER_RESULTS_LAST_READ_MESSAGES_KEY];
            if (dateLastViewedMessages) {
                [[UserData controller].user setDateLastReadMessages:[Utils dateFromString:[Utils stringFromKey:SERVER_RESULTS_LAST_READ_MESSAGES_KEY inDictionary:dictUser]]];
            }
            NSString *strAffiliateID = [dictUser objectForKey:SERVER_RESULTS_AFFILIATE_KEY];
            if (strAffiliateID)
            {
                [[Settings controller] setStrAffiliateID:strAffiliateID];
            }
            NSString *strPlatformEndpointARN = [dictUser objectForKey:SERVER_RESULTS_PLATFORM_ENDPOINT_ARN_KEY];
            if (strPlatformEndpointARN) {
                [[UserData controller].user setStrPlatformEndpointArn:strPlatformEndpointARN];
            }
            NSDictionary *dictAffiliate = [dictUser objectForKey:SERVER_RESULTS_AFFILIATE_DATA_KEY];
            if (dictAffiliate)
            {
                strAffiliateID = [dictAffiliate objectForKey:SERVER_RESULTS_AFFILIATE_ID_KEY];
                if (strAffiliateID)
                {
                    [[Settings controller] setStrAffiliateID:strAffiliateID];
                }
                /*
                NSDictionary *dictDefaultChannel = [dictAffiliate objectForKey:SERVER_RESULTS_DEFAULT_CHANNEL_KEY];

                if (dictDefaultChannel)
                {
                    NSString *strChannelID = [dictDefaultChannel objectForKey:SERVER_RESULTS_CHANNEL_ID_KEY];
                    if (strChannelID)
                    {
                        [Settings controller].channel.strID = strChannelID;
                    }
                    NSString *strChannelName = [dictDefaultChannel objectForKey:SERVER_RESULTS_CHANNEL_NAME_KEY];
                    if (strChannelName)
                    {
                        [Settings controller].channel.strName = strChannelName;
                    }
                    NSString *strChannelDescription = [dictDefaultChannel objectForKey:SERVER_RESULTS_CHANNEL_DESCRIPTION_KEY];
                    if (strChannelDescription)
                    {
                        [Settings controller].channel.strDescription = strChannelDescription;
                    }
                    NSString *strChannelImage = [dictDefaultChannel objectForKey:SERVER_RESULTS_CHANNEL_IMAGE_KEY];
                    if (strChannelImage)
                    {
                        [Settings controller].channel.strChannelImage = strChannelImage;
                    }
                    NSString *strChannelListImage = [dictDefaultChannel objectForKey:SERVER_RESULTS_CHANNEL_LIST_IMAGE_KEY];
                    if (strChannelImage)
                    {
                        [Settings controller].channel.strChannelImageList = strChannelListImage;
                    }
                    NSDictionary *dictMixPanel = [dictDefaultChannel objectForKey:SERVER_RESULTS_MIX_PANEL_KEY];
                    if (dictMixPanel)
                    {
                        NSString *strMixPanelToken = [dictMixPanel objectForKey:SERVER_RESULTS_MIX_PANEL_TOKEN_KEY];
                        if (strMixPanelToken)
                        {
                            //[[Analytics controller] setMixPanelToken:strMixPanelToken];
                        }
                    }
                    NSDictionary *dictWit = [dictDefaultChannel objectForKey:SERVER_RESULTS_WIT_KEY];
                    if (dictWit)
                    {
                        NSString *strWitAccessToken = [dictWit objectForKey:SERVER_RESULTS_WIT_ACCESS_TOKEN_KEY];
                        if (strWitAccessToken)
                        {
                            //[[VoiceCmd controller] setWitAccessToken:strWitAccessToken];
                        }
                    }
                }
                 */
            }

            [Settings saveAll];
        }

        [UserData saveAll];
    }
}

// finalize the request
- (void)requestComplete:(SignInRequest *)request
{
    tSignInRequestType type = request.type;
    tSTMSignInResult result = request.result;
    id<STMSignInDelegate> delegate = request.delegate;

    if (result != STMSignInResult_Success)
    {
        // if this is not an error our UI is ready to handle
        if ((result != STMSignInResult_InvalidVerificationCode) && (result != STMSignInResult_HandleTaken) &&
            (result != STMSignInResult_UserAlreadyExists) && (result != STMSignInResult_UserNotFound) &&
            (result != STMSignInResult_InvalidPhone) &&
            (type != SignInRequestType_CheckAuthCode))
        {
            NSString *strErr = [NSString stringWithFormat:@"SignIn: error - %d", (int) result];
            STM_ERROR(ErrorCategory_Network, ErrorSeverity_Warning, @"SignIn error.", strErr, request.strRequestURL, request.dictRequestData, request.strJSONResults);
        }
    }

    self.request = nil;
    [self sendResult:result toDelegate:delegate];
}

// returns the result code based upon the data from the server
- (tSTMSignInResult)resultCodeForServerErrorData:(NSDictionary *)dictServerData
{
    tSTMSignInResult result = STMSignInResult_UnknownError;

    if (dictServerData)
    {
        result = STMSignInResult_Fail;


        NSNumber *numError = [dictServerData objectForKey:SERVER_RESULTS_STATUS_FAILURE_CODE_KEY];
        if (numError)
        {
            int errCode = [numError intValue];

            switch (errCode)
            {
                case SERVER_ERR_USER_NOT_FOUND:
                    result = STMSignInResult_UserNotFound;
                    break;

                case SERVER_ERR_USER_ALREADY_EXISTS:
                    result = STMSignInResult_UserAlreadyExists;
                    break;

                case SERVER_ERR_HANDLE_ALREADY_EXISTS:
                    result = STMSignInResult_HandleTaken;
                    break;

                case SERVER_ERR_INVALID_VERIFICATION_CODE:
                    result = STMSignInResult_InvalidVerificationCode;
                    break;

                case SERVER_ERR_INVALID_PHONE:
                    result = STMSignInResult_InvalidPhone;
                    break;

                default:
                    result = STMSignInResult_Fail;
                    break;
            }

        }
    }

    return result;
}

#pragma mark - Public Methods

// returns YES if the user is signed in
- (BOOL)isSignedIn
{
    return [[UserData controller] isSignedIn];
}

// signs the user out
- (void)signOut
{
    // clear the settings that are obtained while running
    [Settings controller].channel = [[STMChannel alloc] init];
    [Settings controller].strAffiliateID = @"";
    [Settings saveAll];

    // signout the user
    [[UserData controller] signOut];
}

// checks the user's authentication code and returns the results to the delegate
- (void)signInCheckAuthCodeWithDelegate:(id<STMSignInDelegate>)delegate
{
    if (self.request == nil)
    {
        self.request = [[SignInRequest alloc] init];
        self.request.delegate = delegate;
        self.request.type = SignInRequestType_CheckAuthCode;

        // use a shout request to check the auth code

        self.request.strRequestURL = [NSString stringWithFormat:@"%@/%@",
                                         [Settings controller].strServerURL,
                                         SERVER_CMD_GET_SHOUTS
                                         ];

        // set the json data
        self.request.dictRequestData = nil;

        //NSLog(@"Sign In: Query = %@", self.request.strRequestURL);

        [[DL_URLServer controller] issueRequestURL:self.request.strRequestURL
                                        methodType:DL_URLRequestMethod_Get
                                        withParams:nil
                                        withObject:self.request
                                      withDelegate:self
                                acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                       cacheResult:NO
                                       contentType:CONTENT_TYPE
                                    headerRequests:[[UserData controller] dictStandardRequestHeaders]];
    }
    else
    {
        [self sendResult:STMSignInResult_AlreadyServicing toDelegate:delegate];
    }
}

// signs the user in anonymously
- (void)signInAnonymousWithDelegate:(id<STMSignInDelegate>)delegate
{
    if (self.request == nil)
    {
        self.request = [[SignInRequest alloc] init];
        self.request.delegate = delegate;
        self.request.type = SignInRequestType_SignInAnonymous;

        // set the json data
        self.request.dictRequestData = [[NSMutableDictionary alloc] initWithDictionary:@{ SERVER_DEVICE_ID_KEY : [Settings controller].strDeviceID }];
        NSError *error = nil;
        NSData *dataJSON = [NSJSONSerialization dataWithJSONObject:self.request.dictRequestData options:NSJSONWritingPrettyPrinted error:&error];
        NSString *strJSON = [[NSString alloc] initWithData:dataJSON encoding:NSUTF8StringEncoding];

        self.request.strRequestURL = [NSString stringWithFormat:@"%@/%@",
                                    [Settings controller].strServerURL,
                                    SERVER_CMD_SKIP];
        //NSLog(@"Sign In: Query = %@, JSON = %@", self.request.strRequestURL, strJSON);

        [[DL_URLServer controller] issueRequestURL:self.request.strRequestURL
                                        methodType:DL_URLRequestMethod_Post
                                        withParams:strJSON
                                        withObject:self.request
                                      withDelegate:self
                                acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                       cacheResult:NO
                                       contentType:CONTENT_TYPE
                                    headerRequests:[[UserData controller] dictBasicRequestHeaders]];
    }
    else
    {
        [self sendResult:STMSignInResult_AlreadyServicing toDelegate:delegate];
    }
}

// requests a verification code to be sent to the given phone number via SMS
- (void)requestVerificationCodeWithPhone:(NSString *)strPhone andDelegate:(id<STMSignInDelegate>)delegate
{
    if (self.request == nil)
    {
        [[UserData controller] setPhone:strPhone];

        self.request = [[SignInRequest alloc] init];
        self.request.delegate = delegate;
        self.request.type = SignInRequestType_VerificationCode;

        self.request.strRequestURL = [NSString stringWithFormat:@"%@/%@?%@=%@",
                                      [Settings controller].strServerURL,
                                      SERVER_CMD_VERIFY,
                                      SERVER_VERIFY_PHONE_ARG,
                                      strPhone];
        //NSLog(@"Sign In: Query = %@", self.request.strRequestURL);

        [[DL_URLServer controller] issueRequestURL:self.request.strRequestURL
                                        methodType:DL_URLRequestMethod_Get
                                        withParams:nil
                                        withObject:self.request
                                      withDelegate:self
                                acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                       cacheResult:NO
                                       contentType:CONTENT_TYPE
                                    headerRequests:[[UserData controller] dictBasicRequestHeaders]];
    }
    else
    {
        [self sendResult:STMSignInResult_AlreadyServicing toDelegate:delegate];
    }
}

// signs the user in with the given phone number and verification code
- (void)signInWithPhone:(NSString *)strPhone andCode:(NSString *)strCode andDelegate:(id<STMSignInDelegate>)delegate
{
    if (self.request == nil)
    {
        self.request = [[SignInRequest alloc] init];
        self.request.delegate = delegate;
        self.request.type = SignInRequestType_SignIn;

        // set the json data
        self.request.dictRequestData = [[NSMutableDictionary alloc] initWithDictionary:@{ SERVER_DEVICE_ID_KEY          : [Settings controller].strDeviceID,
                                                                                          SERVER_VERIFICATION_CODE_KEY  : strCode,
                                                                                          SERVER_PHONE_NUMBER_KEY       : strPhone,
                                                                                          }];
        NSError *error = nil;
        NSData *dataJSON = [NSJSONSerialization dataWithJSONObject:self.request.dictRequestData options:NSJSONWritingPrettyPrinted error:&error];
        NSString *strJSON = [[NSString alloc] initWithData:dataJSON encoding:NSUTF8StringEncoding];

        self.request.strRequestURL = [NSString stringWithFormat:@"%@/%@",
                                      [Settings controller].strServerURL,
                                      SERVER_CMD_SIGNIN];
        //NSLog(@"Sign In: Query = %@, JSON = %@", self.request.strRequestURL, strJSON);

        [[DL_URLServer controller] issueRequestURL:self.request.strRequestURL
                                        methodType:DL_URLRequestMethod_Post
                                        withParams:strJSON
                                        withObject:self.request
                                      withDelegate:self
                                acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                       cacheResult:NO
                                       contentType:CONTENT_TYPE
                                    headerRequests:[[UserData controller] dictBasicRequestHeaders]];
    }
    else
    {
        [self sendResult:STMSignInResult_AlreadyServicing toDelegate:delegate];
    }
}

// signs the user up for a new account with the given phone number and verification code
- (void)signUpWithPhone:(NSString *)strPhone andCode:(NSString *)strCode andDelegate:(id<STMSignInDelegate>)delegate
{
    if (self.request == nil)
    {
        self.request = [[SignInRequest alloc] init];
        self.request.delegate = delegate;
        self.request.type = SignInRequestType_SignUp;

        // set the json data
        self.request.dictRequestData = [[NSMutableDictionary alloc] initWithDictionary:@{ SERVER_DEVICE_ID_KEY          : [Settings controller].strDeviceID,
                                                                                          SERVER_VERIFICATION_CODE_KEY  : strCode,
                                                                                          SERVER_PHONE_NUMBER_KEY       : strPhone,
                                                                                          }];
        NSError *error = nil;
        NSData *dataJSON = [NSJSONSerialization dataWithJSONObject:self.request.dictRequestData options:NSJSONWritingPrettyPrinted error:&error];
        NSString *strJSON = [[NSString alloc] initWithData:dataJSON encoding:NSUTF8StringEncoding];

        self.request.strRequestURL = [NSString stringWithFormat:@"%@/%@",
                                      [Settings controller].strServerURL,
                                      SERVER_CMD_SIGNUP];
        //NSLog(@"Sign In: Query = %@, JSON = %@", self.request.strRequestURL, strJSON);

        [[DL_URLServer controller] issueRequestURL:self.request.strRequestURL
                                        methodType:DL_URLRequestMethod_Post
                                        withParams:strJSON
                                        withObject:self.request
                                      withDelegate:self
                                acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                       cacheResult:NO
                                       contentType:CONTENT_TYPE
                                    headerRequests:[[UserData controller] dictBasicRequestHeaders]];
    }
    else
    {
        [self sendResult:STMSignInResult_AlreadyServicing toDelegate:delegate];
    }
}

// verifies the user's account with the given phone number and verification code
- (void)verifyWithPhone:(NSString *)strPhone andCode:(NSString *)strCode andDelegate:(id<STMSignInDelegate>)delegate
{
    if (self.request == nil)
    {
        self.request = [[SignInRequest alloc] init];
        self.request.delegate = delegate;
        self.request.type = SignInRequestType_VerifyAccount;

        // set the json data
        self.request.dictRequestData = [[NSMutableDictionary alloc] initWithDictionary:@{ SERVER_DEVICE_ID_KEY          : [Settings controller].strDeviceID,
                                                                                          SERVER_VERIFICATION_CODE_KEY  : strCode,
                                                                                          SERVER_PHONE_NUMBER_KEY       : strPhone,
                                                                                          }];
        NSError *error = nil;
        NSData *dataJSON = [NSJSONSerialization dataWithJSONObject:self.request.dictRequestData options:NSJSONWritingPrettyPrinted error:&error];
        NSString *strJSON = [[NSString alloc] initWithData:dataJSON encoding:NSUTF8StringEncoding];

        self.request.strRequestURL = [NSString stringWithFormat:@"%@/%@",
                                      [Settings controller].strServerURL,
                                      SERVER_CMD_VERIFY];
        //NSLog(@"Sign In: Query = %@, JSON = %@", self.request.strRequestURL, strJSON);

        [[DL_URLServer controller] issueRequestURL:self.request.strRequestURL
                                        methodType:DL_URLRequestMethod_Post
                                        withParams:strJSON
                                        withObject:self.request
                                      withDelegate:self
                                acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                       cacheResult:NO
                                       contentType:CONTENT_TYPE
                                    headerRequests:[[UserData controller] dictStandardRequestHeaders]];
    }
    else
    {
        [self sendResult:STMSignInResult_AlreadyServicing toDelegate:delegate];
    }
}

// sets the user's handle
- (void)setHandle:(NSString *)strHandle withCompletionHandler:(void (^)(NSError *))completionHandler {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@",
                                       [Settings controller].strServerURL,
                                       SERVER_CMD_PERSONALIZE,
                                       [UserData controller].user.strUserID
                                       ]];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSDictionary *headers = [[UserData controller] dictStandardRequestHeaders];
    [headers setValue:@"application/json" forKey:@"Content-Type"];
    [config setHTTPAdditionalHeaders:headers];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"PUT";
    NSDictionary *dictionary = @{SERVER_HANDLE_KEY: strHandle};
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary
                                                   options:kNilOptions error:&error];
    
    if (!error) {
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                                   fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                                                                       
                                                                       // Check to make sure the server didn't respond with a "Not Authorized"
                                                                       if ([response respondsToSelector:@selector(statusCode)]) {
                                                                           if ([(NSHTTPURLResponse *) response statusCode] == 401) {
                                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                                   // Remind the user to update the API Key
                                                                                   NSMutableDictionary* details = [NSMutableDictionary dictionary];
                                                                                   [details setValue:@"Shout To Me API accessToken required." forKey:NSLocalizedDescriptionKey];
                                                                                   NSError *error = [NSError errorWithDomain:@"Access Denied" code:400 userInfo:details];
                                                                                   return;
                                                                               });
                                                                           } else if ([(NSHTTPURLResponse *) response statusCode] == 409) {
                                                                               NSMutableDictionary* details = [NSMutableDictionary dictionary];
                                                                               [details setValue:@"Handle must be unique" forKey:NSLocalizedDescriptionKey];
                                                                               NSError *error = [NSError errorWithDomain:@"HandleTaken" code:400 userInfo:details];
                                                                               return completionHandler(error);

                                                                           }
                                                                       }
                                                                       
                                                                       if (!error) {
                                                                           NSDictionary *dictResults = nil;
                                                                           NSString *strJSONResults = nil;
                                                                           
                                                                           if (data)
                                                                           {
                                                                               if ([data length])
                                                                               {
                                                                                   strJSONResults = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
                                                                                   if ([Utils stringIsSet:strJSONResults])
                                                                                   {
                                                                                       NSData *jsonData = [strJSONResults dataUsingEncoding:NSUTF32BigEndianStringEncoding];
                                                                                       dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                                                                                       [[SignIn controller] processData:[dictResults objectForKey:SERVER_RESULTS_DATA_KEY]];
                                                                                       completionHandler(error);
                                                                                   }
                                                                               }
                                                                           }
                                                                           
                                                                       } else {
                                                                           completionHandler(error);
                                                                       }
                                                                   }];
        [uploadTask resume];
    } else {
        completionHandler(error);
    }


}

- (void)setHandle:(NSString *)strHandle withDelegate:(id<STMSignInDelegate>)delegate
{
    if (self.request == nil)
    {
        [[UserData controller] setHandle:strHandle];

        self.request = [[SignInRequest alloc] init];
        self.request.delegate = delegate;
        self.request.type = SignInRequestType_SetHandle;

        // set the json data
        self.request.dictRequestData = [[NSMutableDictionary alloc] initWithDictionary:@{ SERVER_HANDLE_KEY : strHandle }];
        NSError *error = nil;
        NSData *dataJSON = [NSJSONSerialization dataWithJSONObject:self.request.dictRequestData options:NSJSONWritingPrettyPrinted error:&error];
        NSString *strJSON = [[NSString alloc] initWithData:dataJSON encoding:NSUTF8StringEncoding];

        self.request.strRequestURL = [NSString stringWithFormat:@"%@/%@/%@",
                                      [Settings controller].strServerURL,
                                      SERVER_CMD_PERSONALIZE,
                                      [UserData controller].user.strUserID
                                      ];
        //NSLog(@"Personalize: Query = %@, JSON = %@", strServerQuery, strJSON);

        [[DL_URLServer controller] issueRequestURL:self.request.strRequestURL
                                        methodType:DL_URLRequestMethod_Put
                                        withParams:strJSON
                                        withObject:self.request
                                      withDelegate:self
                                acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                       cacheResult:NO
                                       contentType:CONTENT_TYPE
                                    headerRequests:[[UserData controller] dictStandardRequestHeaders]];
    }
    else
    {
        [self sendResult:STMSignInResult_AlreadyServicing toDelegate:delegate];
    }
}

- (void)setLastReadMessages:(NSDate *)date withDelegate:(id<STMSignInDelegate>)delegate {
    if (self.request == nil)
    {
        NSString *strDate = [Utils getISO8601String:date];
        [[UserData controller] setLastReadMessages:date];
        
        self.request = [[SignInRequest alloc] init];
        self.request.delegate = delegate;
        self.request.type = SignInRequestType_SetLastReadMessages;
        
        // set the json data
        self.request.dictRequestData = [[NSMutableDictionary alloc] initWithDictionary:@{ SERVER_LAST_READ_MESSAGES_KEY : strDate }];
        NSError *error = nil;
        NSData *dataJSON = [NSJSONSerialization dataWithJSONObject:self.request.dictRequestData options:NSJSONWritingPrettyPrinted error:&error];
        NSString *strJSON = [[NSString alloc] initWithData:dataJSON encoding:NSUTF8StringEncoding];
        
        self.request.strRequestURL = [NSString stringWithFormat:@"%@/%@/%@",
                                      [Settings controller].strServerURL,
                                      SERVER_CMD_PERSONALIZE,
                                      [UserData controller].user.strUserID
                                      ];
        //NSLog(@"Personalize: Query = %@, JSON = %@", strServerQuery, strJSON);
        
        [[DL_URLServer controller] issueRequestURL:self.request.strRequestURL
                                        methodType:DL_URLRequestMethod_Put
                                        withParams:strJSON
                                        withObject:self.request
                                      withDelegate:self
                                acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                       cacheResult:NO
                                       contentType:CONTENT_TYPE
                                    headerRequests:[[UserData controller] dictStandardRequestHeaders]];
    }
    else
    {
        [self sendResult:STMSignInResult_AlreadyServicing toDelegate:delegate];
    }
}

- (void)setPlatformEndpointArn:(NSString *)platformEndpointArn withDelegate:(id<STMSignInDelegate>)delegate {
    if (self.request == nil)
    {
        [[UserData controller] setPlatformEndpointArn: platformEndpointArn];

        self.request = [[SignInRequest alloc] init];
        self.request.delegate = delegate;
        self.request.type = SignInRequestType_SetPlatformEndpointARN;

        // set the json data
        self.request.dictRequestData = [[NSMutableDictionary alloc] initWithDictionary:@{ SERVER_PLATFORM_ENDPOINT_ARN_KEY : platformEndpointArn }];
        NSError *error = nil;
        NSData *dataJSON = [NSJSONSerialization dataWithJSONObject:self.request.dictRequestData options:NSJSONWritingPrettyPrinted error:&error];
        NSString *strJSON = [[NSString alloc] initWithData:dataJSON encoding:NSUTF8StringEncoding];

        self.request.strRequestURL = [NSString stringWithFormat:@"%@/%@/%@",
                                      [Settings controller].strServerURL,
                                      SERVER_CMD_PERSONALIZE,
                                      [UserData controller].user.strUserID
                                      ];
        //NSLog(@"Personalize: Query = %@, JSON = %@", strServerQuery, strJSON);

        [[DL_URLServer controller] issueRequestURL:self.request.strRequestURL
                                        methodType:DL_URLRequestMethod_Put
                                        withParams:strJSON
                                        withObject:self.request
                                      withDelegate:self
                                acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                       cacheResult:NO
                                       contentType:CONTENT_TYPE
                                    headerRequests:[[UserData controller] dictStandardRequestHeaders]];
    }
    else
    {
        [self sendResult:STMSignInResult_AlreadyServicing toDelegate:delegate];
    }
}

- (void)setPlatformEndpointArn:(NSString *)platformEndpointArn withCompletionHandler:(void (^)(NSError *))completionHandler {
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@",
                                       [Settings controller].strServerURL,
                                       SERVER_CMD_PERSONALIZE,
                                       [UserData controller].user.strUserID
                                       ]];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSDictionary *headers = [[UserData controller] dictStandardRequestHeaders];
    [headers setValue:@"application/json" forKey:@"Content-Type"];
    [config setHTTPAdditionalHeaders:headers];

    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"PUT";
    NSDictionary *dictionary = @{SERVER_PLATFORM_ENDPOINT_ARN_KEY: platformEndpointArn};
    NSError *error = nil;
    NSData *data = [NSJSONSerialization dataWithJSONObject:dictionary
                                                   options:kNilOptions error:&error];

    if (!error) {
        NSURLSessionUploadTask *uploadTask = [session uploadTaskWithRequest:request
                                                                   fromData:data completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {

                                                                       // Check to make sure the server didn't respond with a "Not Authorized"
                                                                       if ([response respondsToSelector:@selector(statusCode)]) {
                                                                           if ([(NSHTTPURLResponse *) response statusCode] == 401) {
                                                                               dispatch_async(dispatch_get_main_queue(), ^{
                                                                                   // Remind the user to update the API Key
                                                                                   NSMutableDictionary* details = [NSMutableDictionary dictionary];
                                                                                   [details setValue:@"Shout To Me API accessToken required." forKey:NSLocalizedDescriptionKey];
                                                                                   NSError *error = [NSError errorWithDomain:ShoutToMeErrorDomain
                                                                                                                        code:APITokenNotSet
                                                                                                                    userInfo:details];
                                                                                   return;
                                                                               });
                                                                           }
                                                                       }

                                                                       if (!error) {
                                                                           NSDictionary *dictResults = nil;
                                                                           NSString *strJSONResults = nil;

                                                                           if (data)
                                                                           {
                                                                               if ([data length])
                                                                               {
                                                                                   strJSONResults = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
                                                                                   if ([Utils stringIsSet:strJSONResults])
                                                                                   {
                                                                                       NSData *jsonData = [strJSONResults dataUsingEncoding:NSUTF32BigEndianStringEncoding];
                                                                                       dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
                                                                                       [[SignIn controller] processData:[dictResults objectForKey:SERVER_RESULTS_DATA_KEY]];
                                                                                       completionHandler(error);
                                                                                   }
                                                                               }
                                                                           }

                                                                       } else {
                                                                           completionHandler(error);
                                                                       }
                                                                   }];
        [uploadTask resume];
    } else {
        completionHandler(error);
    }
}

#pragma mark - DL_URLServer Callbacks

// this is the results callback from DLURLServer
- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
    SignInRequest *request = (SignInRequest *)object;
    request.result = STMSignInResult_CommError;

    BOOL bSuccess = NO;
    NSString *strStatus = @"";
    NSDictionary *dictResults = nil;
    NSString *strJSONResults = nil;

    if (data)
    {
        if ([data length])
        {
            strJSONResults = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
            //NSLog(@"Results download returned: %@", strJSONResults );
            if ([strJSONResults isEqualToString:@"Unauthorized"])
            {
                request.result = STMSignInResult_InvalidAuthCode;
            }
        }
    }

    request.strJSONResults = strJSONResults;
    if ([Utils stringIsSet:strJSONResults])
    {
        NSData *jsonData = [strJSONResults dataUsingEncoding:NSUTF32BigEndianStringEncoding];
        dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
        if (dictResults)
        {
            strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];
        }
    }

    //NSLog(@"decode: %@", dictResults);

    if (status == DL_URLRequestStatus_Success)
    {
        if ([[strStatus lowercaseString] isEqualToString:SERVER_RESULTS_STATUS_SUCCESS])
        {
            // if this request had user data included in the response
            if ((request.type == SignInRequestType_SignInAnonymous) ||
                (request.type == SignInRequestType_SignIn) ||
                (request.type == SignInRequestType_SignUp) ||
                (request.type == SignInRequestType_VerifyAccount))
            {
                // save the data that came back in the user and settings
                [self processData:[dictResults objectForKey:SERVER_RESULTS_DATA_KEY]];
            }

            request.result = STMSignInResult_Success;
            bSuccess = YES;
        }
    }

    if (!bSuccess)
    {
        tSTMSignInResult result = [self resultCodeForServerErrorData:dictResults];

        if (result != STMSignInResult_UnknownError)
        {
            request.result = [self resultCodeForServerErrorData:dictResults];
        }
    }

    [self performSelector:@selector(requestComplete:) withObject:request afterDelay:0.0];
}

#pragma mark - SignIn Callbacks
- (void)STMSignInResult:(tSTMSignInResult)result {
    NSLog(@"STMSignInResult");
}

@end
