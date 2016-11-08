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
        [singleton stop];
        [singleton start];
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
        [self start];
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
- (void)start
{
    [self stop];
    
    //NSLog(@"Starting location");
    
    if (NO == [CLLocationManager locationServicesEnabled])
    {
        NSLog(@"Shout to Me SDK requires requestAlwaysAuthorization to use the location features.");
    }
    else
    {
        if (!self.locationManager)
        {
            self.locationManager = [[CLLocationManager alloc] init];
            self.locationManager.delegate = self;
            //self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
        }
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        {
            [self.locationManager requestAlwaysAuthorization];
        }
        [self.locationManager startUpdatingLocation];
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
    if ([[[self locationManager] monitoredRegions] count] < 20) {
        [[self locationManager] startMonitoringForRegion:region];
    } else {
        // We have 20 or more regions and need to only monitor the closest ones.
        [[STM monitoredConversations] addMonitoredRegion:region];
        [self monitorClosest];
    }
}

- (void)monitorClosest {
    // Stop monitoring all regions
    for (CLRegion *monitored in [[self locationManager] monitoredRegions])
        [[self locationManager] stopMonitoringForRegion:monitored];
    
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
    
    // Monitor the closest 20 regions
    NSInteger max;
    if ([sortedValues count] > 20) {
        max = 20;
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
        // Won't get here until everything has finished
        // TODO: Monitor the closest 20 conversations
//        NSLog(@"active conversations: %lu", (unsigned long)[activeConversations count]);
        
        [[STM monitoredConversations] removeAllMonitoredConversations];
        for (STMConversation *conversation in activeConversations) {
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
                                    }];
                                }];

                            } else {
                                [[STM monitoredConversations] addMonitoredConversation:conversation];
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
                                }];
                            }];
                        }
                    }
                }
                
            }];
        }
        if ([[[STM monitoredConversations] monitoredConversations] count] > 0) {
            [self monitorClosest];
        }
    });
}

#pragma mark - CLLocationManagerDelegate Methods

-(void)locationManager:(CLLocationManager *)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
    self.bHaveLocation = YES;
    self.curLocation = newLocation;
    
    //NSLog(@"Aquired location: %lf, %lf (%lf), course: %lf, speed: %lf", newLocation.coordinate.latitude, newLocation.coordinate.longitude, newLocation.horizontalAccuracy, newLocation.course, newLocation.speed);

    if (newLocation.course >= 0.0)
    {
        _lastValidCourse = newLocation.course;
    }

    if (newLocation.speed >= 0.0)
    {
        _lastValidSpeed = newLocation.speed;
    }

    self.bHaveLocation = YES;

    [self announceUpdate:newLocation];
    
//    NSLog(@"%@", [newLocation description]);
    if ([[[self locationManager] monitoredRegions] count] > 20) {
        [self monitorClosest];
    }

#ifdef STOP_UPDATING_AT_ACCURACY
	// if we are at our accuracy then we are done
	if (newLocation.horizontalAccuracy <= ACCURACY_METERS)
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
    NSMutableString *msg = nil;//[[NSMutableString alloc] initWithString:@"The application is having difficulty obtaining your location. Please try again later."];
	
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
            [self.locationManager startUpdatingLocation];
            [self.locationManager startMonitoringSignificantLocationChanges];
        }
            break;
    }
}



@end

