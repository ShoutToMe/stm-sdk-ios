//
//  Location.m
//  ShoutToMeDev
//
//  Description:
//      This module provides location information (i.e., lat and lon)
//
//  Created by Adam Harris on 12/4/14.
//  Copyright 2014 Ditty Labs, LLC. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STMLocation.h"
#import "STM.h"
#import "STM_Defs.h"

//#define STOP_UPDATING_AT_ACCURACY // define this if don't want the location system to keep updating
#define ACCURACY_METERS 1

static BOOL bInitialized = NO;

static STMLocation *singleton = nil;  // this will be the one and only object this static singleton class has

@interface STMLocation ()
{
    double      _lastValidCourse;
    double      _lastValidSpeed;
}

@end

@implementation STMLocation;

@synthesize locationManager = m_locationManager;
@synthesize curLocation = m_curLocation;
@synthesize bHaveLocation = m_bHaveLocation;

#pragma mark - Static Methods

+ (void)initAll
{
	if (NO == bInitialized)
	{
        singleton = [[STMLocation alloc] init];
        
		bInitialized = YES;
	}   
}

+ (void)freeAll
{
	if (YES == bInitialized)
	{
        [singleton stop];
        
        // release our singleton
        singleton = nil;
        
		bInitialized = NO;
	}
}

// returns the user held by the singleton 
// (this call is both a container and an object class and the container holds one of itself)
+ (STMLocation *)controller
{
    return (singleton);
}

+ (void)startLocating
{
    if (bInitialized && singleton) 
    {
        NSError *error;
        [singleton stop];
        [singleton startWithError:&error];
    }
}

+ (void)stopLocating
{
    if (bInitialized && singleton) 
    {
        [singleton stop];
    }
}

#pragma mark - NSObject overrides

- (id)init
{
    self = [super init];
    if (self) 
	{
        self.curLocation = nil;
        _lastValidCourse = -1;
        _lastValidSpeed = -1;
        if (!self.locationManager)
        {
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
            //self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        }
    }
    
    return self;
}

- (void)dealloc 
{
    self.locationManager = nil;
    self.curLocation = nil;
}

#pragma mark - Public Methods

// start requesting location
- (void)startWithError:(NSError **)error
{
    [self stop];
    
    //NSLog(@"Starting location");
    
    if ((NO == [CLLocationManager locationServicesEnabled]) || ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways))
    {
        NSDictionary *userInfo = @{@"error description": @"Unable to start STMLocation, location services are not enabled or not authorized to kCLAuthorizationStatusAuthorizedAlways."};
        *error = [NSError errorWithDomain:ShoutToMeErrorDomain
                                     code:LocationServicesNotEnabledOrAuthorized
                                 userInfo:userInfo];

        NSLog(@"Shout to Me SDK requires requestAlwaysAuthorization to use the location features.");
    }
    else
    {
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        {
            [self.locationManager requestAlwaysAuthorization];
        }
//        [self.locationManager startUpdatingLocation];
        [self.locationManager startMonitoringSignificantLocationChanges];
    }
}

// stop requesting location
- (void)stop
{
    //NSLog(@"Stopping location");
    self.bHaveLocation = NO;
    if (self.locationManager)
    {
        [self.locationManager stopUpdatingLocation];
    }
}

// get the current speed
- (double)speed
{
    return _lastValidSpeed;
}

// get the current course
- (double)course
{
    return _lastValidCourse;
}

// return whether the user has enabled location services for the app
- (BOOL)locationServicesEnabled
{
   return ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied);
}

- (void)startMonitoringForRegion:(CLCircularRegion *)region {
    
    if (region.radius > [self.locationManager maximumRegionMonitoringDistance]) {
        // radius is too large, set it to the maximum
        region = [[CLCircularRegion alloc] initWithCenter:region.center radius:[self.locationManager maximumRegionMonitoringDistance] identifier:region.identifier];
    }
    
    [[STM monitoredConversations] addMonitoredRegion:region];
    if ([[[self locationManager] monitoredRegions] count] < STM_MAX_GEOFENCES) {
        [[self locationManager] startMonitoringForRegion:region];
    } else {
        // We have more than the maximum regions and need to only monitor the closest ones.
        [self monitorClosest];
    }
}

- (void)monitorClosest {
    // Stop monitoring all regions
    [self stopMonitoringForAllRegions];
    
    // Get the current user location
    CLLocation *usersLocation = [[STM location] curLocation];
    
    NSMutableDictionary *sortedRegions = [[NSMutableDictionary alloc] init];
    
    // Loop through local dictionary of conversations and order them by distance from user location
    for (CLCircularRegion *conversationId in [[STM monitoredConversations] monitoredConversations]) {
        CLCircularRegion *monitoredRegion = [[[STM monitoredConversations] monitoredConversations] objectForKey:conversationId];
        CLLocation *monitoredRegionLocation = [[CLLocation alloc] initWithLatitude:monitoredRegion.center.latitude longitude:monitoredRegion.center.longitude];
        CLLocationDistance distance =  [usersLocation distanceFromLocation:monitoredRegionLocation] - monitoredRegion.radius;
        [sortedRegions setObject:monitoredRegion forKey:[[NSNumber alloc] initWithDouble:distance]];
    }
    NSArray *sortedKeys = [sortedRegions.allKeys sortedArrayUsingDescriptors:@[[NSSortDescriptor sortDescriptorWithKey:@"self" ascending:YES]]];
    
    NSArray *sortedValues = [sortedRegions objectsForKeys:sortedKeys notFoundMarker:@""];

    // Monitor the closest regions
    NSInteger max;
    if ([sortedValues count] > STM_MAX_GEOFENCES) {
        max = STM_MAX_GEOFENCES;
    } else {
        max = [sortedValues count];
    }
    for (CLCircularRegion *region in [sortedValues subarrayWithRange:NSMakeRange(0, max)]) {
        [self startMonitoringForRegion:region];
    }
}

- (void)stopMonitoringForRegion:(CLCircularRegion *)region {
    [[STM monitoredConversations] removeMonitoredConversation:region];
    [[self locationManager] stopMonitoringForRegion:region];
}

- (void)syncMonitoredRegions {
    dispatch_group_t serviceGroup = dispatch_group_create();
    
    // Get list of subscriptions ( get to channel ids)
    NSMutableArray<STMConversation *> *activeConversations = [[NSMutableArray alloc] init];
    dispatch_group_enter(serviceGroup);
    [[STM subscriptions] requestForSubscriptionsWithcompletionHandler:^(NSArray<STMSubscription *> *subscriptions, NSError *error) {
//        NSLog(@"Number of subscriptions: %lu", (unsigned long)[subscriptions count]);
        
        // Get all active conversations for each channel
        for (STMSubscription *subscription in subscriptions) {
            dispatch_group_enter(serviceGroup);
            [[STM conversations]requestForActiveConversationWith:subscription.strChannelId completionHandler:^(NSArray<STMConversation *> *conversations, NSError *error) {
                if ([conversations count]) {
                    [activeConversations addObjectsFromArray:conversations];
                }
                dispatch_group_leave(serviceGroup);
            }];
        }
        dispatch_group_leave(serviceGroup);
    }];
    
    dispatch_group_notify(serviceGroup,dispatch_get_main_queue(),^{

        // Clear out all monitored conversations and geofences
        [[STM monitoredConversations] removeAllMonitoredConversations];
        [self stopMonitoringForAllRegions];
        
    
        dispatch_group_t conversationsSeenGroup = dispatch_group_create();
        
        // Now add relevant conversations back in
        for (STMConversation *conversation in activeConversations) {
            dispatch_group_enter(conversationsSeenGroup);
            [[STM conversations] requestForSeenConversation:conversation.str_id completionHandler:^(BOOL seen, NSError *error) {
                NSLog(@"Seen: %@", seen == YES ? @"True" : @"False");
                if (!error) {
                    if (!seen) {
                        if (conversation.location && conversation.location.lat && conversation.location.lon && conversation.location.radius_in_meters) {
                            // Add conversation to monitored conversations
                            CLLocationCoordinate2D center = CLLocationCoordinate2DMake(conversation.location.lat,
                                                                                       conversation.location.lon);
                            CLCircularRegion *conversation_region = [[CLCircularRegion alloc]initWithCenter:center
                                                                                                     radius:conversation.location.radius_in_meters
                                                                                                 identifier:conversation.str_id];
                            
                            if ([conversation_region containsCoordinate:[STMLocation controller].curLocation.coordinate]) {
                                [[STM messages] requestForCreateMessageForChannelId:conversation.str_channel_id ToRecipientId:[STM currentUser].strUserID WithConversationId:conversation.str_id AndMessage:conversation.str_publishing_message completionHandler:^(STMMessage *message, NSError *error) {
                                    
                                    NSLog(@"Created Message: %@", message);
                                    [[STM channels] requestForChannel:conversation.str_channel_id completionHandler:^(STMChannel *channel, NSError *error) {
                                        NSDictionary *messageData = @{
                                                                      @"body": conversation.str_publishing_message,
                                                                      @"category": @"MESSAGE_CATEGORY",
                                                                      @"channel_id": conversation.str_channel_id,
                                                                      @"content-available": @1,
                                                                      @"conversation_id": conversation.str_id,
                                                                      @"title": channel.strName,
                                                                      @"type": @"conversation message",
                                                                      @"message_id": message.strID
                                                                      };
                                        UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                                        localNotification.soundName = @"shout.wav";
                                        localNotification.alertTitle = [Utils stringFromKey:@"title" inDictionary:messageData];
                                        localNotification.alertBody = [Utils stringFromKey:@"body" inDictionary:messageData];
                                        localNotification.userInfo = messageData;
                                        
                                        [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                                        dispatch_group_leave(conversationsSeenGroup);
                                    }];
                                }];

                            } else {
                                [[STM monitoredConversations] addMonitoredConversation:conversation];
                                dispatch_group_leave(conversationsSeenGroup);
                            }
                            
                        } else {
                            [[STM messages] requestForCreateMessageForChannelId:conversation.str_channel_id ToRecipientId:[STM currentUser].strUserID WithConversationId:conversation.str_id AndMessage:conversation.str_publishing_message completionHandler:^(STMMessage *message, NSError *error) {
                                
                                NSLog(@"Created Message: %@", message);
                                [[STM channels] requestForChannel:conversation.str_channel_id completionHandler:^(STMChannel *channel, NSError *error) {
                                    NSDictionary *messageData = @{
                                                                  @"body": conversation.str_publishing_message,
                                                                  @"category": @"MESSAGE_CATEGORY",
                                                                  @"channel_id": conversation.str_channel_id,
                                                                  @"content-available": @1,
                                                                  @"conversation_id": conversation.str_id,
                                                                  @"title": channel.strName,
                                                                  @"type": @"conversation message",
                                                                  @"message_id": message.strID
                                                                  };
                                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                                    localNotification.soundName = @"shout.wav";
                                    localNotification.alertTitle = [Utils stringFromKey:@"title" inDictionary:messageData];
                                    localNotification.alertBody = [Utils stringFromKey:@"body" inDictionary:messageData];
                                    localNotification.userInfo = messageData;
                                    
                                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                                    dispatch_group_leave(conversationsSeenGroup);
                                }];
                            }];
                        }
                    } else {
                        dispatch_group_leave(conversationsSeenGroup);
                    }
                } else {
                    NSLog(@"%@", error);
                    dispatch_group_leave(conversationsSeenGroup);
                }
                
            }];
        }
        
        dispatch_group_notify(conversationsSeenGroup, dispatch_get_main_queue(), ^{
            // Add geofences based in using helper method
            if ([[[STM monitoredConversations] monitoredConversations] count] > 0) {
                [self monitorClosest];
            }
        });
    });
}

#pragma mark - CLLocationManagerDelegate Methods
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    self.curLocation = [locations lastObject];
    
    self.bHaveLocation = YES;
    
    if (self.curLocation.course >= 0.0)
    {
        _lastValidCourse = self.curLocation.course;
    }
    
    if (self.curLocation.speed >= 0.0)
    {
        _lastValidSpeed = self.curLocation.speed;
    }
    
    [self announceUpdate:self.curLocation];
    
    //    NSLog(@"%@", [newLocation description]);
    if ([[[self locationManager] monitoredRegions] count] >= STM_MAX_GEOFENCES) {
        [self monitorClosest];
    }
    
#ifdef STOP_UPDATING_AT_ACCURACY
    // if we are at our accuracy then we are done
    if (self.curLocation.horizontalAccuracy <= ACCURACY_METERS)
    {
        [self stop];
        
        NSLog(@"Location is accurate enough");
    }
#endif
}

- (void)announceUpdate:(CLLocation *)newLocation
{
    NSDictionary *dictNotification = @{ STM_NOTIFICATION_KEY_LOCATION_UPDATED_LOCATION  : newLocation };
    [[NSNotificationCenter defaultCenter] postNotificationName:STM_NOTIFICATION_LOCATION_UPDATED object:self userInfo:dictNotification];
}

- (void)announceDenied
{
    [[NSNotificationCenter defaultCenter] postNotificationName:STM_NOTIFICATION_LOCATION_DENIED object:self userInfo:nil];
}

// the location manager had an issue with obtaining the location
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	
    //NSLog(@"Location error: %d", (int) [error code]);
    
	if ([error domain] == kCLErrorDomain) 
	{
		// We handle CoreLocation-related errors here
		switch ([error code]) 
		{
				// "Don't Allow" on two successive app launches is the same as saying "never allow". The user
				// can reset this for all apps by going to Settings > General > Reset > Reset Location Warnings.
			case kCLErrorDenied:
				//[msg setString:NSLocalizedString(@"You have not allowed this application to obtain your location. Therefore, this application will not be able find shouts near you.", nil)];
                [self performSelector:@selector(announceDenied) withObject:nil afterDelay:0.0];
				break;
				
			case kCLErrorLocationUnknown:
				break;
				
			default:
				break;
		}
	}

    self.bHaveLocation = NO;
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSDictionary *dictNotification = @{ STM_NOTIFICATION_KEY_LOCATION_AUTHORIZATION_STATUS  : [NSNumber numberWithInt: status] };
    [[NSNotificationCenter defaultCenter] postNotificationName:STM_NOTIFICATION_LOCATION_AUTHORIZATION_CHANGED object:self userInfo:dictNotification];

    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
        {
            
        }
            break;
            
        default: {
//            [self.locationManager startUpdatingLocation];
            [self.locationManager startMonitoringSignificantLocationChanges];
        }
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didEnterRegion:(CLRegion *)region {
    NSLog(@"Entered Region: %@", [region description]);
    [[STM conversations] requestForConversation:[region identifier] completionHandler:^(STMConversation *conversation, NSError *error) {
        if (!conversation.expired) {
            [[STM messages] requestForCreateMessageForChannelId:conversation.str_channel_id ToRecipientId:[STM currentUser].strUserID WithConversationId:conversation.str_id AndMessage:conversation.str_publishing_message completionHandler:^(STMMessage *message, NSError *error) {
                NSLog(@"Created Message: %@", message);

                [[STM channels] requestForChannel:conversation.str_channel_id completionHandler:^(STMChannel *channel, NSError *error) {
                    NSDictionary *localNotificationData =
                    @{
                      @"body": message.strMessage,
                      @"category": @"MESSAGE_CATEGORY",
                      @"channel_id": message.strChannelId,
                      @"conversation_id": message.strConversationId,
                      @"title": channel.strName,
                      @"type": @"conversation message",
                      @"message_id": message.strID
                      };

                    UILocalNotification *localNotification = [[UILocalNotification alloc] init];
                    localNotification.soundName = @"shout.wav";
                    localNotification.alertTitle = channel.strName;
                    localNotification.alertBody = conversation.str_publishing_message;
                    localNotification.userInfo = localNotificationData;

                    [[UIApplication sharedApplication] scheduleLocalNotification:localNotification];
                    [self stopMonitoringForRegion:region];
                }];
            }];
        } else {
            [self stopMonitoringForRegion:region];
        }
    }];
}

- (void) stopMonitoringForAllRegions {
    for (CLRegion *region in self.locationManager.monitoredRegions) {
        [self.locationManager stopMonitoringForRegion:region];
    }
}

@end

