//
//  User.m
//
//  Created by Tracy Rojas on 7/31/17.
//  Copyright (c) Shout to Me 2017. All rights reserved.
//
//

#import "User.h"
#import "Server.h"
#import "Settings.h"
#import "STMNetworking.h"
#import "UserData.h"
#import "Utils.h"

static BOOL bInitialized = NO;

__strong static User *singleton = nil;

@implementation SetUserPropertiesInput
{
    NSMutableDictionary *properties;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        properties = [NSMutableDictionary new];
    }
    return self;
}

- (void)setEmail:(NSString *)email
{
    _email = email;
    [self setProperty:self.email forKey:SERVER_RESULTS_USER_EMAIL_KEY];
}

- (void)setHandle:(NSString *)handle
{
    _handle = handle;
    [self setProperty:self.handle forKey:SERVER_HANDLE_KEY];
}

- (void)setPhoneNumber:(NSString *)phoneNumber
{
    _phoneNumber = phoneNumber;
    [self setProperty:self.phoneNumber forKey:SERVER_PHONE_NUMBER_KEY];
}

- (NSDictionary *)getPropertyDictionary
{
    return [properties copy];
}

- (void)setProperty:(NSString *)value forKey:(NSString *)key
{
    if (!value || [@"" isEqual:value]) {
        [properties setObject:[NSNull null] forKey:key];
    } else {
        [properties setObject:value forKey:key];
    }
}

@end

@implementation User

#pragma mark - Static methods

+ (void)initAll
{
    if (NO == bInitialized)
    {
        [Settings initAll];
        [DL_URLServer initAll];
        
        singleton = [[User alloc] init];
        
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
+ (User *)controller
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
    return(@"User");
}

#pragma mark - Public Methods

- (void)setProperties:(SetUserPropertiesInput *)setUserPropertiesInput withCompletionHandler:(void (^)(NSError *, id))completionHandler
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@",
                                       [Settings controller].strServerURL,
                                       SERVER_CMD_PERSONALIZE,
                                       [UserData controller].user.strUserID
                                       ]];
    
    STMUploadRequest *uploadRequest = [STMUploadRequest new];
    [uploadRequest send:[setUserPropertiesInput getPropertyDictionary] toUrl:url usingHTTPMethod:@"PUT" responseHandlerDelegate:self withCompletionHandler:completionHandler];
}

#pragma mark - STMUploadResponseHandlerDelegate
- (void)processResponseData:(NSDictionary *)responseData withCompletionHandler:(void (^)(NSError *, id))completionHandler
{
    NSMutableDictionary *mutableUserDict = [[NSMutableDictionary alloc] initWithDictionary:[responseData objectForKey:SERVER_RESULTS_USER_KEY]];
    [mutableUserDict setObject:[responseData objectForKey:SERVER_RESULTS_AUTH_TOKEN_KEY] forKey:SERVER_RESULTS_AUTH_TOKEN_KEY];
    
    STMUser *user = [[STMUser alloc] initWithDictionary:[mutableUserDict copy]];
    NSLog(@"%@", user);
    
    if (user.strEmail) {
        [[UserData controller].user setStrEmail:user.strEmail];
    } else {
        [[UserData controller].user setStrEmail:@""];
    }
    if (user.strHandle) {
        [[UserData controller].user setStrHandle:user.strHandle];
    } else {
        [[UserData controller].user setStrHandle:@""];
    }
    if (user.strPhoneNumber) {
        [[UserData controller].user setStrPhoneNumber:user.strPhoneNumber];
    } else {
        [[UserData controller].user setStrPhoneNumber:@""];
    }
    [UserData saveAll];
    
    completionHandler(nil, user);
}

@end
