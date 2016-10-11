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
        [self showAlert:NSLocalizedString(@"You have not allowed this application to obtain your location. Therefore, this application will not be able find shouts near you. If you would like this feature, please go to the device settings under \"General / Location Services\" and enable it.", nil)
              withTitle:NSLocalizedString(@"Location Warning", nil)];
        NSLog(@"No general location to start with");
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

#pragma mark - Misc Methods

- (void)showAlert:(NSString *)strMsg withTitle:(NSString *)strTitle
{
    UIAlertView *alert = [[UIAlertView alloc]
						  initWithTitle:strTitle 
						  message:strMsg
						  delegate:nil
						  cancelButtonTitle:@"OK"
						  otherButtonTitles:nil];
	[alert show];
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
        [[STM stmGeofenceLocationManager] monitorClosest];
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

    if (msg)
    {
        [self showAlert:msg withTitle:@"Location Warning"];
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

