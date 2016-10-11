//
//  STMGeofenceLocationManager.h
//  Pods
//
//  Created by Tyler Clemens on 9/9/16.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

@interface STMGeofenceLocationManager : NSObject <CLLocationManagerDelegate>
{
    
}

@property (nonatomic, strong) CLLocationManager	*locationManager;
@property (nonatomic, strong) CLLocation        *curLocation;
@property (nonatomic, assign) BOOL              bHaveLocation;

// static methods
+ (void)initAll;
+ (void)freeAll;
+ (STMGeofenceLocationManager *)controller;

- (void)start;
- (void)stop;
- (void)monitorWithLat:(double)lat andLon:(double)lon andRadius:(double)radius andConversationId:(NSString *)conversationId;
- (void)startMonitoringForRegion:(CLCircularRegion *)region;
- (void)stopMonitoringForRegion:(CLCircularRegion *)region;
- (void)syncMonitoredRegions;
- (void)monitorClosest;
- (BOOL)locationServicesEnabled;

@end
