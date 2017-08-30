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

@property (nonatomic, strong, nullable) CLLocationManager	*locationManager;
@property (nonatomic, strong, nullable) CLLocation        *curLocation;

// static methods
+ (void)initAll;
+ (void)freeAll;
+ (nullable STMLocation *)controller;

- (void)startWithError:(NSError * _Nullable * _Null_unspecified)error;
- (void)stop;
- (double)speed;
- (double)course;
- (void)processGeofenceUpdate;

@end

@interface STMGeofence : CLCircularRegion

- (instancetype _Nullable )initWithCenter:(CLLocationCoordinate2D)center;

extern NSString * _Nonnull const STMGeofenceIdentifier;
extern CLLocationDistance const STMGeofenceRadius;


@end
