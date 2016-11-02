//
//  Location.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 12/4/14.
//  Copyright 2014 Ditty Labs, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface STMLocation : NSObject <CLLocationManagerDelegate>
{

}

@property (nonatomic, strong) CLLocationManager	*locationManager;
@property (nonatomic, strong) CLLocation        *curLocation;
@property (nonatomic, assign) BOOL              bHaveLocation;

// static methods
+ (void)initAll;
+ (void)freeAll;
+ (STMLocation *)controller;

- (void)start;
- (void)stop;
- (double)speed;
- (double)course;
- (BOOL)locationServicesEnabled;
- (void)startMonitoringForRegion:(CLCircularRegion *)region;
- (void)stopMonitoringForRegion:(CLCircularRegion *)region;
- (void)syncMonitoredRegions;



@end
