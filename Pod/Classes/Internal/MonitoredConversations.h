//
//  MonitoredConversations.h
//  Pods
//
//  Created by Tyler Clemens on 9/26/16.
//
//

#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "STMConversation.h"

#define MONITORED_CONVERSATIONS_DATA_VERSION   2  // what version is this object (increased any time new items are added or existing items are changed)

@interface MonitoredConversations : NSObject

@property (nonatomic, copy)   NSDictionary          *monitoredConversations;

+ (void)initAll;
+ (void)freeAll;

+ (void)loadAll;
+ (void)saveAll;

+ (MonitoredConversations *)controller;


- (void)addMonitoredRegion:(CLCircularRegion *)region __deprecated;
- (void)removeMonitoredConversation:(CLCircularRegion *)region __deprecated;
- (void)removeAllMonitoredConversations __deprecated;

- (void)addMonitoredConversation:(STMConversation *)conversation __deprecated;

- (void)save __deprecated;

@end
