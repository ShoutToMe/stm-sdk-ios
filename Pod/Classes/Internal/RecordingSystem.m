//
//  RecordingSystem.m
//  ShoutToMeDev
//
//  Created by Tyler Clemens on 7/23/15.
//  Copyright (c) 2015 Adam Harris. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Error.h"
#import "Server.h"
#import "RecordingSystem.h"
#import "STM_Defs.h"
#import "STMLocation.h"
#import "DL_URLServer.h"
#import "Settings.h"

#define RECORDING_SYSTEM_DATA_VERSION   1  // what version is this object (increased any time new items are added or existing items are changed)

#define RECORDING_SYSTEM_DATA_FILENAME              @"RecordingSystemData"

#define KEY_RECORDING_SYSTEM_DATA_ALL               @"RecordingSystemDataDataAll"

#define KEY_RECORDING_SYSTEM_DATA_VERSION           @"RecordingSystemDataVer"
#define KEY_RECORDING_SYSTEM_DATA_VAD_TIMEOUT       @"RecordingSystemDataVadTimeout"
#define KEY_RECORDING_SYSTEM_DATA_VAD_SENSITIVITY   @"RecordingSystemDataVadSensitivity"

static BOOL bInitialized = NO;

__strong static RecordingSystem *singleton = nil; // this will be the one and only object this static singleton class has

@interface RecordingSystem ()
{
    int _vadTimeout;
    int _vadSensitivity;
}

@end


@implementation RecordingSystem

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
    NSString *filePath = [self dataFilePath:RECORDING_SYSTEM_DATA_FILENAME];
    
    // if the file exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSData *data = [[NSMutableData alloc] initWithContentsOfFile:filePath];
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        singleton = [unarchiver decodeObjectForKey:KEY_RECORDING_SYSTEM_DATA_ALL];
        [unarchiver finishDecoding];
    }
    else
    {
        // just create a new one
        singleton = [[RecordingSystem alloc] init];
    }

}

// saves all the settings to persistant memory
+ (void)saveAll
{
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:singleton forKey:KEY_RECORDING_SYSTEM_DATA_ALL];
    [archiver finishEncoding];
    [data writeToFile:[self dataFilePath:RECORDING_SYSTEM_DATA_FILENAME] atomically:YES];
}


// returns the singleton
// (this call is both a container and an object class and the container holds one of itself)
+ (RecordingSystem *)controller
{
    return (singleton);
}

#pragma mark - Object Methods

- (id)init
{
    self = [super init];
    if (self)
    {
        self.vadSensitivity = 0;
        self.vadTimeout = 15000;
    }
    return self;
}

- (void)dealloc
{
    
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (nil != (self = [self init]))
    {
        int version = [aDecoder decodeIntForKey:KEY_RECORDING_SYSTEM_DATA_VERSION];
        if (version >= RECORDING_SYSTEM_DATA_VERSION)
        {
            int val;
            val = [aDecoder decodeIntForKey:KEY_RECORDING_SYSTEM_DATA_VAD_SENSITIVITY ];
            if (val)
            {
                self.vadSensitivity = val;
            }
            val = [aDecoder decodeIntForKey:KEY_RECORDING_SYSTEM_DATA_VAD_TIMEOUT ];
            if (val)
            {
                self.vadTimeout = val;
            }


        }
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:RECORDING_SYSTEM_DATA_VERSION forKey:KEY_RECORDING_SYSTEM_DATA_VERSION];
    [aCoder encodeInt:self.vadSensitivity forKey:KEY_RECORDING_SYSTEM_DATA_VAD_SENSITIVITY];
    [aCoder encodeInt:self.vadTimeout forKey:KEY_RECORDING_SYSTEM_DATA_VAD_TIMEOUT];
}

#pragma mark - Public Methods

- (void)save
{
    [RecordingSystem saveAll];
}


@end
