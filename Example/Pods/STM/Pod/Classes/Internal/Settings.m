//
//  Settings.m
//  ShoutToMeDev
//
//  Description:
//      This module provides a place to persist settings for STM
//
//  Created by Adam Harris on 11/04/14.
//  Copyright 2014 Ditty Labs. All rights reserved.
//

#import "Server.h"
#import "Settings.h"
#import "KeychainItemWrapper.h"
#import "Utils.h"
#import "STM_Defs.h"

#define KEY_DEVICE_ID                       @"com.ShoutToMe.DeviceID"

#define SETTINGS_DATA_FILENAME              @"SettingsData"

#define KEY_SETTINGS_DATA_ALL               @"SettingsDataAll"

#define KEY_SETTINGS_DATA_VERSION           @"SettingsDataVer"
#define KEY_SETTINGS_CHANNEL                @"SettingsChannel"
#define KEY_SETTINGS_AFFILIATE_ID           @"SettingsAffiliateId"
#define KEY_SETTINGS_SERVER_URL             @"SettingsServerURL"

static BOOL bInitialized = NO;

__strong static Settings *singleton = nil; // this will be the one and only object this static singleton class has

@interface Settings ()
{

}

@end

@implementation Settings

#pragma mark - Static methods

+ (void)initAll
{
	if (NO == bInitialized)
	{
        // load will create a new singleton if needed
        [self loadAll];

		bInitialized = YES;
	}
}

+ (void)freeAll
{
	if (YES == bInitialized)
	{
        // release our singleton
        singleton = nil;
		
		bInitialized = NO;
	}
}

// returns the full file path for the given file
+ (NSString *)dataFilePath:(NSString *)fileName
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

// loads all the settings from persistant memory
+ (void)loadAll
{
    if (nil != singleton)
    {
        singleton = nil;
    }

    // get the file name
    NSString *filePath = [self dataFilePath:SETTINGS_DATA_FILENAME];

    // if the file exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSData *data = [[NSMutableData alloc] initWithContentsOfFile:filePath];
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        singleton = [unarchiver decodeObjectForKey:KEY_SETTINGS_DATA_ALL];
        [unarchiver finishDecoding];
    }
    else
    {
        // just create a new one
        singleton = [[Settings alloc] init];
    }

    // load the device id
    [singleton loadDeviceID];

    //NSLog(@"Settings: %@", singleton);
}

// saves all the settings to persistant memory
+ (void)saveAll
{
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:singleton forKey:KEY_SETTINGS_DATA_ALL];
    [archiver finishEncoding];
    [data writeToFile:[self dataFilePath:SETTINGS_DATA_FILENAME] atomically:YES];
}

// returns the singleton 
// (this call is both a container and an object class and the container holds one of itself)
+ (Settings *)controller
{
    return (singleton);
}

#pragma mark - Object Methods

- (id)init
{
    self = [super init];
    if (self) 
	{
        self.strDeviceID = @"";
        self.strAffiliateID = @"";
        self.strServerURL = SERVER_URL;
        self.channel = [[STMChannel alloc] init];
    }
    return self;
}

- (void)dealloc
{
    self.strDeviceID = nil;
}

// overriding the description - used in debugging
- (NSString *)description
{
    return([NSString stringWithFormat:@"DeviceID: %@, AffiliateID: %@, Channel: %@, ServerURL: %@",
            self.strDeviceID,
            self.strAffiliateID,
            self.channel,
            self.strServerURL
            ]);
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (nil != (self = [self init]))
    {
        int version = [aDecoder decodeIntForKey:KEY_SETTINGS_DATA_VERSION];
        if (version >= SETTINGS_DATA_VERSION)
        {
            STMChannel *channel = [aDecoder decodeObjectForKey:KEY_SETTINGS_CHANNEL];
            if (channel)
            {
                self.channel = channel;
            }

            NSString *strVal = nil;
            strVal = [aDecoder decodeObjectForKey:KEY_SETTINGS_AFFILIATE_ID];
            if (strVal)
            {
                self.strAffiliateID = strVal;
            }
            strVal = [aDecoder decodeObjectForKey:KEY_SETTINGS_SERVER_URL];
            if (strVal)
            {
                self.strServerURL = strVal;
            }
        }
    }

    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:SETTINGS_DATA_VERSION forKey:KEY_SETTINGS_DATA_VERSION];
    [aCoder encodeObject:self.channel forKey:KEY_SETTINGS_CHANNEL];
    [aCoder encodeObject:self.strAffiliateID forKey:KEY_SETTINGS_AFFILIATE_ID];
    [aCoder encodeObject:self.strServerURL forKey:KEY_SETTINGS_SERVER_URL];
}

#pragma mark - Misc Methods

// this loads or creates the device id. unlike the other settings, this is store in the keychain so it persists even after app deletion
- (void)loadDeviceID
{
    KeychainItemWrapper *wrapperKeychainDeviceID = [[KeychainItemWrapper alloc] initWithIdentifier:KEY_DEVICE_ID accessGroup:nil];

    // get the device id
    NSString *strDeviceID = [wrapperKeychainDeviceID objectForKey:(__bridge id)kSecValueData];

    // if there was one stored
    if ([Utils stringIsSet:strDeviceID])
    {
        //NSLog(@"Loaded device id: %@", strDeviceID);
        self.strDeviceID = strDeviceID;
    }
    else
    {
        // create a device id
        self.strDeviceID = [Utils createGUID];
        //NSLog(@"No device id set. New device id: %@", self.strDeviceID);
        [wrapperKeychainDeviceID setObject:self.strDeviceID forKey:(__bridge id)kSecValueData];
    }
}

- (void)setChannel:(STMChannel *)channel {
    _channel = channel;
    NSDictionary *dictNotification = @{ STM_NOTIFICATION_KEY_CHANNEL_UPDATED_CHANNEL  : channel };
    [[NSNotificationCenter defaultCenter] postNotificationName:STM_NOTIFICATION_SETTINGS_CHANNEL_CHANGED object:self userInfo:dictNotification];
}

#pragma mark - Public Methods

- (void)save
{
    [Settings saveAll];
}


@end
