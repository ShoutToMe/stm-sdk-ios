//
//  UserData.m
//  ShoutToMeDev
//
//  Description:
//      This module persists the user information
//
//  Created by Adam Harris on 3/02/14.
//  Copyright 2015 Ditty Labs. All rights reserved.
//

#import "Server.h"
#import "UserData.h"
#import "Utils.h"
#import "SignIn.h"
#import "STM.h"

#define USER_DATA_VERSION   3  // what version is this object (increased any time new items are added or existing items are changed)

#define USER_DATA_FILENAME              @"UserData"

#define KEY_USER_DATA_ALL               @"UserDataAll"

#define KEY_USER_DATA_VERSION           @"UserDataVer"
#define KEY_USER_DATA_USER              @"UserDataUser"

static BOOL bInitialized = NO;

__strong static UserData *singleton = nil; // this will be the one and only object this static singleton class has

@interface UserData ()
{

}

@end

@implementation UserData

#pragma mark - Static methods

+ (void)initAll
{
	if (NO == bInitialized)
	{
        // load will create a new singleton if needed
        [self loadAll];

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

// returns the full file path for the given file
+ (NSString *)dataFilePath:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

// loads all the settings from persistant memory
+ (void)loadAll
{
    if (nil != singleton)
    {
        singleton = nil;
    }

    // get the file name
    NSString *filePath = [self dataFilePath:USER_DATA_FILENAME];

    // if the file exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSData *data = [[NSMutableData alloc] initWithContentsOfFile:filePath];
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        singleton = [unarchiver decodeObjectForKey:KEY_USER_DATA_ALL];
        [unarchiver finishDecoding];
    }
    else
    {
        // just create a new one
        singleton = [[UserData alloc] init];
    }

    //NSLog(@"UserData: %@", singleton);
}

// saves all the settings to persistant memory
+ (void)saveAll
{
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:singleton forKey:KEY_USER_DATA_ALL];
    [archiver finishEncoding];
    [data writeToFile:[self dataFilePath:USER_DATA_FILENAME] atomically:YES];
}

// returns the singleton 
// (this call is both a container and an object class and the container holds one of itself)
+ (UserData *)controller
{
    return (singleton);
}

#pragma mark - Object Methods

- (id)init
{
    self = [super init];
    if (self) 
	{
        self.user = [[User alloc] init];
    }
    return self;
}

- (void)dealloc
{

}

// overriding the description - used in debugging
- (NSString *)description
{
    return([NSString stringWithFormat:@"User: %@",
            self.user
            ]);
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (nil != (self = [self init]))
    {
        int version = [aDecoder decodeIntForKey:KEY_USER_DATA_VERSION];
        if (version >= USER_DATA_VERSION)
        {
            User *user = [aDecoder decodeObjectForKey:KEY_USER_DATA_USER];
            if (user)
            {
                self.user = user;
            }
        }
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:USER_DATA_VERSION forKey:KEY_USER_DATA_VERSION];

    [aCoder encodeObject:self.user forKey:KEY_USER_DATA_USER];
}

#pragma mark - SignIn Delegates
- (void)STMSignInResult:(tSTMSignInResult)result {
    if (result == STMSignInResult_Success) {
        [self save];
    }
    
}

#pragma mark - Misc Methods


#pragma mark - Public Methods

- (BOOL)isSignedIn
{
   return [Utils stringIsSet:self.user.strAuthCode];
}

- (void)signOut
{
    if (self.user) {
        [self.user setBVerified:NO];
        [self.user setStrAuthCode:@""];
        [self.user setStrPhoneNumber:@""];
        [self.user setStrUserID:@""];
        [self.user setStrHandle:@""];
        [self.user setStrPlatformEndpointArn:@""];
        [self save];
    }

}

- (BOOL)isAnonymous
{
    return ![self isVerified];
}

- (BOOL)isVerified
{
    return self.user.bVerified;
}

- (NSDictionary *)dictBasicRequestHeaders
{
    NSMutableDictionary *dictHeaders = [[NSMutableDictionary alloc] init];

    [dictHeaders setObject:[NSString stringWithFormat:@"%@ %@", BASIC_AUTH_PREFIX, [STM sharedInstance].accessToken] forKey:AUTH_KEY];
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    [dictHeaders setObject:[NSString stringWithFormat:@"%@", appBuildString] forKey:BUILD_HEADER_PREFIX];

    return dictHeaders;
}

- (NSDictionary *)dictStandardRequestHeaders
{
    NSMutableDictionary *dictHeaders = [[NSMutableDictionary alloc] init];
    
    if ([self isSignedIn]) {
        [dictHeaders setObject:[NSString stringWithFormat:@"%@ %@", STD_AUTH_PREFIX, self.user.strAuthCode] forKey:AUTH_KEY];
    } else {
        [self signIn];
    }

    [dictHeaders setObject:[NSString stringWithFormat:@"%@ %@", STD_AUTH_PREFIX, self.user.strAuthCode] forKey:AUTH_KEY];
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    [dictHeaders setObject:[NSString stringWithFormat:@"%@", appBuildString] forKey:BUILD_HEADER_PREFIX];

    return dictHeaders;
}

- (void)signIn {
    dispatch_semaphore_t sema = dispatch_semaphore_create(0);
    
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@",
                                       [Settings controller].strServerURL,
                                       SERVER_CMD_SKIP]];
    NSURLSessionConfiguration *config = [NSURLSessionConfiguration defaultSessionConfiguration];
    NSString * appBuildString = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"];
    [config setHTTPAdditionalHeaders:@{@"Authorization":[NSString stringWithFormat:@"%@ %@", BASIC_AUTH_PREFIX, [STM sharedInstance].accessToken],
                                       @"BuildNumber":[NSString stringWithFormat:@"%@", appBuildString],
                                       @"Content-Type": @"application/json"}];
    
    NSURLSession *session = [NSURLSession sessionWithConfiguration:config];
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:url];
    request.HTTPMethod = @"POST";
    NSDictionary *dictionary = @{@"device_id": [Settings controller].strDeviceID};
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
                                                                                   UIAlertView * alert = [[UIAlertView alloc] initWithTitle:@"Shout To Me API accessToken required"
                                                                                                                                    message:@"Be sure to set your STM accessToken."
                                                                                                                                   delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil];
                                                                                   [alert show];
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
                                                                                   }
                                                                               }
                                                                           }
                                                                           
                                                                           
                                                                           
                                                                           dispatch_semaphore_signal(sema);
                                                                           
                                                                       } else {
                                                                           dispatch_semaphore_signal(sema);
                                                                       }
                                                                   }];
        [uploadTask resume];
    }
    dispatch_semaphore_wait(sema, DISPATCH_TIME_FOREVER);
}

- (void)setHandle:(NSString *)strHandle
{
    self.user.strHandle = strHandle;
    [self save];
}

- (void)setPhone:(NSString *)strPhone
{
    self.user.strPhoneNumber = strPhone;
    [self save];
}

- (void)setLastReadMessages:(NSDate *)date {
    self.user.dateLastReadMessages = date;
    [self save];
}

- (void)setPlatformEndpointArn:(NSString *)platformEndpointArn {
    self.user.strPlatformEndpointArn = platformEndpointArn;
    [self save];
}

- (void)save
{
    [UserData saveAll];
}


@end
