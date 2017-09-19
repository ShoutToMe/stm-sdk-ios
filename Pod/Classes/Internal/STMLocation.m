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

#import "STMLocation.h"
#import "STMError.h"
#import "STM_Defs.h"
#import "User.h"

#define STOP_UPDATING_AT_ACCURACY // define this if don't want the location system to keep updating
#define ACCURACY_METERS 10

static NSString *const MESSAGE_CATEGORY = @"SHOUTTOME_MESSAGE";
static BOOL bInitialized = NO;
static double const RECENT_UPDATE_MAX_SECONDS = 60.0;

static STMLocation *singleton = nil;  // this will be the one and only object this static singleton class has

@interface STMLocation ()
{
    double      _lastValidCourse;
    double      _lastValidSpeed;
    NSTimer * _Nullable updateLocationTimer;
}

@end

@implementation STMLocation;

@synthesize locationManager = m_locationManager;
@synthesize curLocation = m_curLocation;
@synthesize prevLocation = m_prevLocation;

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

#pragma mark - NSObject overrides

- (id)init
{
    self = [super init];
    if (self) 
	{
        self.curLocation = nil;
        self.prevLocation = nil;
        _lastValidCourse = -1;
        _lastValidSpeed = -1;
        if (!self.locationManager)
        {
            self.locationManager = [[CLLocationManager alloc] init];
            [self.locationManager setDelegate:self];
            //self.locationManager.desiredAccuracy = kCLLocationAccuracyBest;
            [self.locationManager setPausesLocationUpdatesAutomatically:YES];
            [self.locationManager setActivityType:CLActivityTypeOther];
            [self.locationManager setDistanceFilter:100.0];
        }
    }
    
    return self;
}

- (void)dealloc 
{
    self.locationManager = nil;
    self.curLocation = nil;
    self.prevLocation = nil;
}

#pragma mark - Public Methods

- (void)startWithError:(NSError **)error
{
    [self stop];
    
    //NSLog(@"Starting location");
    
    if ((NO == [CLLocationManager locationServicesEnabled])
        || ([CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedAlways
            && [CLLocationManager authorizationStatus] != kCLAuthorizationStatusAuthorizedWhenInUse))
    {
                NSDictionary *userInfo = @{@"error description": @"Unable to start STMLocation, location services are not enabled or not authorized to kCLAuthorizationStatusAuthorizedAlways or kCLAuthorizationStatusAuthorizedWhenInUse."};
        
                *error = [NSError errorWithDomain:ShoutToMeErrorDomain
                                             code:LocationServicesNotEnabledOrAuthorized
                                         userInfo:userInfo];
        
        NSLog(@"Shout to Me SDK requires Always or When In Use authorization to use the location features.");
    }
    else
    {
        if ([self.locationManager respondsToSelector:@selector(requestAlwaysAuthorization)])
        {
            [self.locationManager requestAlwaysAuthorization];
        }
        
        [self processGeofenceUpdate];
        [self startSignificantLocationChangeUpdates];
    }
}

- (void)stop
{
    if (self.locationManager)
    {
        [self.locationManager stopUpdatingLocation];
        [self stopSignificantLocationChangeUpdates];
        [self deleteGeofence];
    }
    self.curLocation = nil;
    self.prevLocation = nil;
    _lastValidCourse = -1;
    _lastValidSpeed = -1;
}

- (double)speed
{
    return _lastValidSpeed;
}

- (double)course
{
    return _lastValidCourse;
}

- (void)processGeofenceUpdate
{
    if (!updateLocationTimer) {
        
        if (![self deviceSupportsRegionMonitoring]) {
            NSLog(@"Region monitoring not supported or always authorizationStatus not set.");
            return;
        }
        
        self.prevLocation = self.curLocation;
        self.curLocation = nil;
        
        // Start location listening
        [self.locationManager startUpdatingLocation];
        
        // Start the timer for updating the location/geofence
        [self startLocationListeningTimer];
    }
}

#pragma mark - High level process methods

- (void)processLocationUpdateWithLocation:(CLLocation *)location
{
    if (location.course >= 0.0)
    {
        _lastValidCourse = location.course;
    }
    
    if (location.speed >= 0.0)
    {
        _lastValidSpeed = location.speed;
    }
    
    if (updateLocationTimer) {
        [self setLocation:location];
    } else if (![self locationInGeofenceAreaWithLocation:location]) {

        // [self sendSignificantLocationNotInGeofenceEmail:location];
        
        [self deleteGeofence];
        [self processGeofenceUpdate];
    }
}

- (void)sendSignificantLocationNotInGeofenceEmail:(CLLocation *)location {
    NSString *locationCoordinates = [NSString stringWithFormat:@"%f, %f", location.coordinate.latitude, location.coordinate.longitude];
    NSString *geofenceCoordinates = @"";
    CLCircularRegion *region = [self findSTMGeofence];
    if (region) {
        geofenceCoordinates = [NSString stringWithFormat:@"%f, %f", region.center.latitude, region.center.longitude];
    }
    NSString *locationData = [NSString stringWithFormat:@"Current location: %@ | Geofence location: %@", locationCoordinates, geofenceCoordinates];
    
    [[STMError controller] logErrorWithCategory:ErrorCategory_Location withSeverity:ErrorSeverity_Warning andDescription:@"User not in geofence" andDetails:@"Significant Change Location Service detected that user was not within the current geofence bounds" andRequest:nil andRequestData:nil andResults:locationData inFunction:[NSString stringWithUTF8String:__func__] inSource:[NSString stringWithUTF8String:__FILE__] onLine:(int)__LINE__];
}

#pragma mark - Timer methods

- (void)startLocationListeningTimer
{
    updateLocationTimer = [NSTimer scheduledTimerWithTimeInterval:2.0
                                                           target:self
                                                         selector:@selector(locationTimerCallback:)
                                                         userInfo:nil
                                                          repeats:NO];
}

- (void)locationTimerCallback:(NSTimer *)theTimer
{
    [self.locationManager stopUpdatingLocation];
    updateLocationTimer = nil;
    
    [self updateUserLocation];
    
    [self createGeofence];
}

#pragma mark - Client notification methods

- (void)announceUpdate:(STMGeofence *)stmGeofence
{
    NSDictionary *dictNotification = @{ STM_NOTIFICATION_KEY_LOCATION_UPDATED_LOCATION  : stmGeofence };
    [[NSNotificationCenter defaultCenter] postNotificationName:STM_NOTIFICATION_LOCATION_UPDATED object:self userInfo:dictNotification];
}

- (void)announceDenied
{
    [[NSNotificationCenter defaultCenter] postNotificationName:STM_NOTIFICATION_LOCATION_DENIED object:self userInfo:nil];
}

#pragma mark - Helper methods

- (void)createGeofence
{
    if (self.curLocation) {
        STMGeofence *geofence = [[STMGeofence alloc] initWithCenter:self.curLocation.coordinate];
        [self.locationManager startMonitoringForRegion:geofence];
        [self announceUpdate:geofence];
    }
}

- (void)deleteGeofence
{
    CLCircularRegion *stmRegion = [self findSTMGeofence];
    if (stmRegion) {
        [self.locationManager stopMonitoringForRegion:stmRegion];
    }
}

- (BOOL)deviceSupportsRegionMonitoring
{
    return [CLLocationManager isMonitoringAvailableForClass:[CLCircularRegion class]]
    && ([CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedAlways
        || [CLLocationManager authorizationStatus] == kCLAuthorizationStatusAuthorizedWhenInUse);
}

- (CLCircularRegion *)findSTMGeofence
{
    CLCircularRegion *stmRegion = nil;
    if ([self deviceSupportsRegionMonitoring]) {
        for (CLRegion *region in [self.locationManager monitoredRegions]) {
            if ([[region identifier] isEqualToString:STMGeofenceIdentifier]) {
                stmRegion = (CLCircularRegion *)region;
            }
        }
    }
    return stmRegion;
}

- (BOOL)locationInGeofenceAreaWithLocation:(CLLocation *)location
{
    CLCircularRegion *stmRegion = [self findSTMGeofence];
    if (stmRegion) {
        CLLocation *regionLocation = [[CLLocation alloc] initWithLatitude:stmRegion.center.latitude longitude:stmRegion.center.longitude];
        CLLocationDistance distance = [regionLocation distanceFromLocation:location];
        if (distance - location.horizontalAccuracy < stmRegion.radius) {
            return YES;
        } else {
            return NO;
        }
    } else {
        return NO;
    }
}

- (void)setLocation:(CLLocation *)location
{
    if (self.curLocation) {
        NSTimeInterval secondsSinceLastUpdate = fabs([location.timestamp timeIntervalSinceDate:self.curLocation.timestamp]);
        if (location.horizontalAccuracy <= self.curLocation.horizontalAccuracy || secondsSinceLastUpdate > RECENT_UPDATE_MAX_SECONDS) {
            [self setCurLocation:location];
        }
    } else {
        [self setCurLocation:location];
    }
}

- (void) startSignificantLocationChangeUpdates {
    if (self.locationManager)
    {
        [self.locationManager setAllowsBackgroundLocationUpdates:YES];
        [self.locationManager startMonitoringSignificantLocationChanges];
    }
}

- (void)stopSignificantLocationChangeUpdates {
    if (self.locationManager) {
        [self.locationManager setAllowsBackgroundLocationUpdates:NO];
        [self.locationManager stopMonitoringSignificantLocationChanges];
    }
}

- (void)updateUserLocation {
    
    if (self.curLocation) {
        UserLocation *userLocation = [UserLocation new];
        [userLocation setTimestamp:self.curLocation.timestamp];
        [userLocation setLat:self.curLocation.coordinate.latitude];
        [userLocation setLon:self.curLocation.coordinate.longitude];
        
        if (self.prevLocation) {
            [userLocation setMetersSinceLastUpdate:[NSNumber numberWithDouble:[self.curLocation distanceFromLocation:self.prevLocation]]];
        }
        
        [userLocation update];
    }
}


#pragma mark - CLLocationManagerDelegate Methods
-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations {
    CLLocation *location = [locations lastObject];
    if (location) {
        [self processLocationUpdateWithLocation:location];
    }
}

-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	
    NSLog(@"LocationManager didFailWithError error: %@", error);
    if ([error domain] == kCLErrorDomain)
    {
        switch ([error code])
        {
            case kCLErrorDenied:
                [self performSelector:@selector(announceDenied) withObject:nil afterDelay:0.0];
                break;
                
            case kCLErrorLocationUnknown:
                break;
                
            default:
                break;
        }
    }
}

- (void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status {
    NSDictionary *dictNotification = @{ STM_NOTIFICATION_KEY_LOCATION_AUTHORIZATION_STATUS  : [NSNumber numberWithInt: status] };
    [[NSNotificationCenter defaultCenter] postNotificationName:STM_NOTIFICATION_LOCATION_AUTHORIZATION_CHANGED object:self userInfo:dictNotification];
    
    switch (status) {
        case kCLAuthorizationStatusNotDetermined:
        case kCLAuthorizationStatusRestricted:
        case kCLAuthorizationStatusDenied:
        {
            [self stop];
        }
            break;
            
        default: {
            [self startSignificantLocationChangeUpdates];
            [self processGeofenceUpdate];
        }
            break;
    }
}

- (void)locationManager:(CLLocationManager *)manager didExitRegion:(nonnull CLRegion *)region
{
    [self.locationManager stopMonitoringForRegion:region];
    [self processGeofenceUpdate];
}

- (void)locationManager:(CLLocationManager *)manager monitoringDidFailForRegion:(CLRegion *)region withError:(NSError *)error
{
    NSLog(@"LocationManager monitoringDidFailForRegion error: %@", error);
}
@end

@implementation STMGeofence

NSString *const STMGeofenceIdentifier = @"me.shoutto.user_geofence";
CLLocationDistance const STMGeofenceRadius = STM_USER_GEOFENCE_RADIUS;

- (instancetype)initWithCenter:(CLLocationCoordinate2D)center
{
    return [self initWithCenter:center radius:STMGeofenceRadius identifier:STMGeofenceIdentifier];
}

@end
