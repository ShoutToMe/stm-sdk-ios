//
//  STMGeofenceLocationManager.m
//  Pods
//
//  Created by Tyler Clemens on 9/9/16.
//
//

#import <UIKit/UIKit.h>
#import "STMGeofenceLocationManager.h"
#import "STM.h"
#import "STM_Defs.h"

//#define STOP_UPDATING_AT_ACCURACY // define this if don't want the location system to keep updating
#define ACCURACY_METERS 1

static BOOL bInitialized = NO;

static STMGeofenceLocationManager *singleton = nil;  // this will be the one and only object this static singleton class has


@implementation STMGeofenceLocationManager

@synthesize locationManager = m_locationManager;
@synthesize curLocation = m_curLocation;
@synthesize bHaveLocation = m_bHaveLocation;

#pragma mark - Static Methods

+ (void)initAll
{
    if (NO == bInitialized)
    {
        singleton = [[STMGeofenceLocationManager alloc] init];
        
        bInitialized = YES;
    }
    [singleton start];
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
+ (STMGeofenceLocationManager *)controller
{
    return (singleton);
}

#pragma mark - Public Methods

// start requesting location
- (void)start
{
    [self stop];
    
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
            //self.locationManager.desiredAccuracy = kCLLocationAccuracyBestForNavigation;
        }
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        {
            [self.locationManager requestAlwaysAuthorization];
        }
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
//        NSLog(@"active conversations: %lu", (unsigned long)[activeConversations count]);
        
        [[STM monitoredConversations] removeAllMonitoredConversations];
        for (STMConversation *conversation in activeConversations) {
            [[STM conversations] requestForSeenConversation:conversation.str_id completionHandler:^(BOOL seen, NSError *error) {
                NSLog(@"Seen: %@", seen == YES ? @"True" : @"False");
                if (!error) {
                    //                        if(true) {
                    if (!seen) {
                        if (conversation.location && conversation.location.lat && conversation.location.lon && conversation.location.radius_in_meters) {
                            // Add conversation to monitored conversations
                            [[STM monitoredConversations] addMonitoredConversation:conversation];
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

// return whether the user has enabled location services for the app
- (BOOL)locationServicesEnabled
{
    return ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusDenied);
}

#pragma mark - CLLocationManagerDelegate Methods

- (void)locationManager:(CLLocationManager *)manager didStartMonitoringForRegion:(CLCircularRegion *)region {
    NSLog(@"Started Monitoring Region: %@", [region description]);
    [[STM monitoredConversations] addMonitoredRegion:region];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error {
    NSLog(@"Failed Monitoring Region: %@, Error: %@", [region description], [error description]);
    
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
                    [manager stopMonitoringForRegion:region];                    
                }];
            }];
            
        }
    }];
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(CLCircularRegion *)region {
    NSLog(@"Exited Region: %@", [region description]);
    [self stopMonitoringForRegion:region];
}

@end
