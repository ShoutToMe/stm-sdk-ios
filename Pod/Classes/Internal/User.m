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
#import "STM.h"
#import "STMNetworking.h"
#import "UserData.h"
#import "Utils.h"
#import "UserLocationRetryDataController.h"

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

@interface UserResponseHandler : NSObject <STMHTTPResponseHandlerDelegate>
@end

@interface ChannelSubscriptionResponseHandler : NSObject <STMHTTPResponseHandlerDelegate>
@end

@interface TopicPreferenceResponseHandler : NSObject <STMHTTPResponseHandlerDelegate>
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

- (void)updateProperties:(NSDictionary *)properties withCompletionHandler:(void (^)(NSError *, id))completionHandler
{
    NSURL *url = [NSURL URLWithString:[NSString stringWithFormat:@"%@/%@/%@",
                                       [Settings controller].strServerURL,
                                       SERVER_CMD_PERSONALIZE,
                                       [UserData controller].user.strUserID
                                       ]];
    
    STMUploadRequest *uploadRequest = [STMUploadRequest new];
    [uploadRequest send:properties toUrl:url usingHTTPMethod:@"PUT" responseHandlerDelegate:[UserResponseHandler new] withCompletionHandler:completionHandler];
}

- (NSURL *)getSubscriptionUrl
{
    NSString *strUrl = [NSString stringWithFormat:@"%@/%@/%@/%@",
                        [Settings controller].strServerURL,
                        SERVER_CMD_PERSONALIZE,
                        [UserData controller].user.strUserID,
                        SERVER_CMD_CHANNEL_SUBSCRIPTION];
    NSURL *url = [NSURL URLWithString:strUrl];
    return url;
}

- (NSURL *)getTopicPreferenceUrl
{
    NSString *strUrl = [NSString stringWithFormat:@"%@/%@/%@/%@",
                        [Settings controller].strServerURL,
                        SERVER_CMD_PERSONALIZE,
                        [UserData controller].user.strUserID,
                        SERVER_CMD_TOPIC_PREFERENCE];
    NSURL *url = [NSURL URLWithString:strUrl];
    return url;
}

#pragma mark - Public Methods

- (void)setProperties:(SetUserPropertiesInput *)setUserPropertiesInput withCompletionHandler:(void (^)(NSError *, id))completionHandler
{
    [self updateProperties:[setUserPropertiesInput getPropertyDictionary] withCompletionHandler:completionHandler];
}

- (void)enableNotifications
{
    [self updateProperties:[[NSDictionary alloc] initWithObjectsAndKeys:@"true", SERVER_PLATFORM_ENDPOINT_ENABLED_KEY, nil] withCompletionHandler:nil];
}

- (void)subscribeTo:(NSString *)channelId withCompletionHandler:(void (^)(NSError * _Nullable, id _Nullable))completionHandler
{
    STMUploadRequest *uploadRequest = [STMUploadRequest new];
    [uploadRequest send:@{ SERVER_CHANNEL_ID_KEY: channelId } toUrl:[self getSubscriptionUrl] usingHTTPMethod:@"PUT" responseHandlerDelegate:[ChannelSubscriptionResponseHandler new] withCompletionHandler:completionHandler];
}

- (void)unsubscribeFrom:(NSString *)channelId withCompletionHandler:(void (^)(NSError * _Nullable, id _Nullable))completionHandler
{
    STMUploadRequest *uploadRequest = [STMUploadRequest new];
    [uploadRequest send:@{ SERVER_CHANNEL_ID_KEY: channelId } toUrl:[self getSubscriptionUrl] usingHTTPMethod:@"DELETE" responseHandlerDelegate:[ChannelSubscriptionResponseHandler new] withCompletionHandler:completionHandler];
}

- (void)setChannelSubscriptions:(NSArray<NSString *> *)channelIds withCompletionHandler:(void (^)(NSError * _Nullable, id _Nullable))completionHandler
{
    STMUploadRequest *uploadRequest = [STMUploadRequest new];
    [uploadRequest send:@{ SERVER_CHANNEL_ID_KEY: channelIds } toUrl:[self getSubscriptionUrl] usingHTTPMethod:@"POST" responseHandlerDelegate:[ChannelSubscriptionResponseHandler new] withCompletionHandler:completionHandler];
}

- (BOOL)isSubscribedToChannel:(NSString *)channelId
{
    BOOL userIsSubscribed = NO;
    NSLog(@"%@", [STM currentUser].channelSubscriptions);
    for (NSString *subscribedChannelId in [STM currentUser].channelSubscriptions) {
        if ([subscribedChannelId isEqualToString:channelId]) {
            userIsSubscribed = YES;
            break;
        }
    }
    return userIsSubscribed;
}

- (void)addTopicPreference:(NSString *_Nonnull)topic withCompletionHandler:(void (^_Nullable)(NSError *_Nullable, id _Nullable))completionHandler
{
    STMUploadRequest *uploadRequest = [STMUploadRequest new];
    [uploadRequest send:@{ SERVER_TOPIC_KEY: topic } toUrl:[self getTopicPreferenceUrl] usingHTTPMethod:@"PUT" responseHandlerDelegate:[TopicPreferenceResponseHandler new] withCompletionHandler:completionHandler];
}

- (void)removeTopicPreference:(NSString *_Nonnull)topic withCompletionHandler:(void (^_Nullable)(NSError *_Nullable, id _Nullable))completionHandler
{
    STMUploadRequest *uploadRequest = [STMUploadRequest new];
    [uploadRequest send:@{ SERVER_TOPIC_KEY: topic } toUrl:[self getTopicPreferenceUrl] usingHTTPMethod:@"DELETE" responseHandlerDelegate:[TopicPreferenceResponseHandler new] withCompletionHandler:completionHandler];
}

- (void)setTopicPreferences:(NSArray<NSString *>*_Nonnull)topics withCompletionHandler:(void (^_Nullable)(NSError *_Nullable, id _Nullable))completionHandler
{
    STMUploadRequest *uploadRequest = [STMUploadRequest new];
    [uploadRequest send:@{ SERVER_TOPIC_KEY: topics } toUrl:[self getTopicPreferenceUrl] usingHTTPMethod:@"POST" responseHandlerDelegate:[TopicPreferenceResponseHandler new] withCompletionHandler:completionHandler];
}

- (BOOL)isFollowingTopic:(NSString *_Nonnull)topic
{
    BOOL isFollowingTopic = NO;
    for (NSString *followedTopic in [STM currentUser].topicPreferences) {
        if ([followedTopic isEqualToString:topic]) {
            isFollowingTopic = YES;
            break;
        }
    }
    return isFollowingTopic;
}

@end

@implementation UserResponseHandler

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
    
    if (completionHandler) {
        completionHandler(nil, user);
    }
}

@end

@implementation ChannelSubscriptionResponseHandler

- (void)processResponseData:(NSDictionary *)responseData withCompletionHandler:(void (^)(NSError *, id))completionHandler
{
    NSArray<NSString *> *channelSubscriptions = [NSArray<NSString *> new];
    if (responseData && responseData.count > 0) {
        channelSubscriptions = [responseData objectForKey:SERVER_RESULTS_CHANNEL_SUBSCRIPTIONS];
    }
    
    [[STM userData] setChannelSubscriptions:channelSubscriptions];
    
    if (completionHandler) {
        completionHandler(nil, channelSubscriptions);
    }
}

@end

@implementation TopicPreferenceResponseHandler

- (void)processResponseData:(NSDictionary *)responseData withCompletionHandler:(void (^)(NSError *, id))completionHandler
{
    NSArray<NSString *> *topicPreferences = [NSArray<NSString *> new];
    if (responseData && responseData.count > 0) {
        topicPreferences = [responseData objectForKey:SERVER_RESULTS_TOPIC_PREFERENCES];
    }
    
    [[STM userData] setTopicPreferences:topicPreferences];
    
    if (completionHandler) {
        completionHandler(nil, topicPreferences);
    }
}

@end

@implementation UserLocation

@synthesize timestamp;
@synthesize lat;
@synthesize lon;

NSString *fingerprint;
NSString *const STM_USER_DEFAULTS_FINGERPRINT_KEY = @"me.shoutto.sdk.UserLocation.fingerprint";
NSString *const TIME_ZONE_UTC = @"UTC";

- (id)init
{
    self = [super init];
    
    if (self) {
        NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
        fingerprint = [userDefaults stringForKey:STM_USER_DEFAULTS_FINGERPRINT_KEY];
        if (!fingerprint) {
            fingerprint = [[NSUUID UUID] UUIDString];
            [userDefaults setObject:fingerprint forKey:STM_USER_DEFAULTS_FINGERPRINT_KEY];
        }
    }
    
    return self;
}

- (void)update
{
    UserLocationRetryDataController *userLocationRetryDataController = [UserLocationRetryDataController new];

    void (^getAllLocationsCallbackBlock)(NSArray *) = ^(NSArray *previousUserLocations) {
        NSMutableArray *locations = [NSMutableArray new];
        if (previousUserLocations && [previousUserLocations count] > 0) {
            NSEnumerator *e = [previousUserLocations objectEnumerator];
            id object;
            while (object = [e nextObject]) {
                NSDictionary *previousLocation = (NSDictionary *)object;
                NSDictionary *adaptedPreviousLocation = [self buildLocationWithDate:[previousLocation valueForKey:SERVER_DATE_KEY] lat:[previousLocation valueForKey:SERVER_LAT_KEY] lon:[previousLocation valueForKey:SERVER_LON_KEY] radius:STM_USER_GEOFENCE_RADIUS metersSinceLastUpdate:[previousLocation objectForKey:SERVER_METERS_SINCE_LAST_UPDATE_KEY]];
                [locations addObject:adaptedPreviousLocation];
            }
        }
        
        NSDictionary *currentLocation = [self buildLocationWithDate:self.timestamp lat:[NSNumber numberWithDouble:self.lat] lon:[NSNumber numberWithDouble:self.lon] radius:STM_USER_GEOFENCE_RADIUS metersSinceLastUpdate:self.metersSinceLastUpdate];
        [locations addObject:currentLocation];
        
        NSDictionary *requestData = @{ SERVER_CMD_LOCATIONS: [locations copy] };
        
        NSString *strUrl = [NSString stringWithFormat:@"%@/%@/%@/%@",
                            [Settings controller].strServerURL,
                            SERVER_CMD_PERSONALIZE,
                            [UserData controller].user.strUserID,
                            SERVER_CMD_LOCATIONS];
        NSURL *url = [NSURL URLWithString:strUrl];
        
        STMUploadRequest *uploadRequest = [STMUploadRequest new];
        [uploadRequest send:requestData toUrl:url usingHTTPMethod:@"PUT" responseHandlerDelegate:self withCompletionHandler:^(NSError *uploadRequestError, id obj) {
            // NOTE: This completion handler occurs when there is an error sending the request to the Shout to Me service.
            NSLog(@"An error occurred %@", uploadRequestError);
            
            STM_ERROR(ErrorCategory_Internal, ErrorSeverity_Warning, @"An error occurred uploading a user location", uploadRequestError.description, nil, nil, nil);
            
            NSMutableDictionary *userLocationRecordData = [NSMutableDictionary new];
            [userLocationRecordData setValue:self.timestamp forKey:SERVER_DATE_KEY];
            [userLocationRecordData setValue:[NSNumber numberWithDouble:self.lat] forKey:SERVER_LAT_KEY];
            [userLocationRecordData setValue:[NSNumber numberWithDouble:self.lon] forKey:SERVER_LON_KEY];
            [userLocationRecordData setValue:[NSNumber numberWithDouble:STM_USER_GEOFENCE_RADIUS] forKey:SERVER_RADIUS_KEY];
            if (self.metersSinceLastUpdate) {
                [userLocationRecordData setValue:self.metersSinceLastUpdate forKey:SERVER_METERS_SINCE_LAST_UPDATE_KEY];
            }
            [userLocationRetryDataController saveUserLocation:[userLocationRecordData copy]];
        }];
    };
    
    [userLocationRetryDataController getAllUserLocations:getAllLocationsCallbackBlock];
}

- (NSDictionary *)buildLocationWithDate:(NSDate *)date lat:(NSNumber *)lat lon:(NSNumber *)lon radius:(double)radius metersSinceLastUpdate:(NSNumber *)metersSinceLastUpdate
{
    NSMutableDictionary *location = [NSMutableDictionary new];
    
    [location setObject:@{
                          SERVER_TYPE_KEY: SERVER_TYPE_SHAPE_CIRCLE,
                          SERVER_COORDINATES_KEY: @[lon, lat],
                          SERVER_RADIUS_KEY: [NSString stringWithFormat:@"%f", radius]
                          } forKey:SERVER_CMD_LOCATION];
    [location setObject:[self getUTCFormateDate:date] forKey:SERVER_DATE_KEY];
    if (metersSinceLastUpdate) {
        [location setValue:metersSinceLastUpdate forKey:SERVER_METERS_SINCE_LAST_UPDATE_KEY];
    }
    
    return [location copy];
}

- (NSString *)getUTCFormateDate:(NSDate *)date
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    NSTimeZone *timeZone = [NSTimeZone timeZoneWithName:TIME_ZONE_UTC];
    [dateFormatter setTimeZone:timeZone];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss'Z'"];
    NSString *dateString = [dateFormatter stringFromDate:date];
    return dateString;
}

#pragma mark - STMHTTPResponseHandlerDelegate
// NOTE: This callback method occurs during successful sending of request to the Shout to Me service.
- (void)processResponseData:(NSDictionary *)responseData withCompletionHandler:(void (^)(NSError *, id))completionHandler
{
    UserLocationRetryDataController *userLocationRetryDataController = [UserLocationRetryDataController new];
    [userLocationRetryDataController deleteAllUserLocations];
}
@end
