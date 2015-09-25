//
//  Settings.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 11/04/14.
//  Copyright 2014 Ditty Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STMChannel.h"

#define SETTINGS_DATA_VERSION   3  // what version is this object (increased any time new items are added or existing items are changed)

typedef enum eSettingsAcctPref
{
    SettingsAcctPref_NotAskedYet = 0,
    SettingsAcctPref_NoAccountWanted,
    SettingsAcctPref_AccountWanted
} tSettingsAcctPref;


// this is singleton object class
// this means it has static methods that create on instance of itself for use by all

@interface Settings : NSObject

@property (nonatomic, copy)   NSString          *strDeviceID; // unique across all devices
@property (nonatomic, strong) STMChannel           *channel;
@property (nonatomic, copy)   NSString          *strAffiliateID;
@property (nonatomic, copy)   NSString          *strServerURL;

+ (void)initAll;
+ (void)freeAll;

+ (void)loadAll;
+ (void)saveAll;

+ (Settings *)controller;

- (void)save;

@end

