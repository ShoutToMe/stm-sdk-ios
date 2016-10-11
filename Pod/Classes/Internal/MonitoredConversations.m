//
//  MonitoredConversations.m
//  Pods
//
//  Created by Tyler Clemens on 9/26/16.
//
//

#import "Server.h"
#import "MonitoredConversations.h"
#import "KeychainItemWrapper.h"
#import "Utils.h"
#import "STM_Defs.h"

#define MONITORED_CONVERSATIONS_DATA_FILENAME              @"MonitoredConversationsData"
#define KEY_MONITORED_CONVERSATIONS_DATA_ALL               @"MonitoredConversationsDataAll"
#define KEY_MONITORED_CONVERSATIONS_DATA_VERSION           @"MonitoredConversationsDataVer"
#define KEY_MONITORED_CONVERSATIONS                        @"MonitoredConversations"

static BOOL bInitialized = NO;

__strong static MonitoredConversations *singleton = nil; // this will be the one and only object this static singleton class has

@interface MonitoredConversations ()
{
    
}

@end


@implementation MonitoredConversations

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
    NSString *filePath = [self dataFilePath:MONITORED_CONVERSATIONS_DATA_FILENAME];
    
    // if the file exists
    if ([[NSFileManager defaultManager] fileExistsAtPath:filePath])
    {
        NSData *data = [[NSMutableData alloc] initWithContentsOfFile:filePath];
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        singleton = [unarchiver decodeObjectForKey:KEY_MONITORED_CONVERSATIONS_DATA_ALL];
        [unarchiver finishDecoding];
    }
    else
    {
        // just create a new one
        singleton = [[MonitoredConversations alloc] init];
    }
    
    //NSLog(@"Settings: %@", singleton);
}

// saves all the settings to persistant memory
+ (void)saveAll
{
    NSMutableData *data = [[NSMutableData alloc] init];
    NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
    [archiver encodeObject:singleton forKey:KEY_MONITORED_CONVERSATIONS_DATA_ALL];
    [archiver finishEncoding];
    [data writeToFile:[self dataFilePath:MONITORED_CONVERSATIONS_DATA_FILENAME] atomically:YES];
}

// returns the singleton
// (this call is both a container and an object class and the container holds one of itself)
+ (MonitoredConversations *)controller
{
    return (singleton);
}

#pragma mark - Object Methods

- (id)init
{
    self = [super init];
    if (self)
    {
        self.monitoredConversations = @{};
    }
    return self;
}

- (void)dealloc
{
    self.monitoredConversations = nil;
}

// overriding the description - used in debugging
- (NSString *)description
{
    return([NSString stringWithFormat:@"Monitored Regions[%lu]",
            (unsigned long)[self.monitoredConversations count]
            ]);
}

#pragma mark - NSCoding

- (id)initWithCoder:(NSCoder *)aDecoder
{
    if (nil != (self = [self init]))
    {
        int version = [aDecoder decodeIntForKey:KEY_MONITORED_CONVERSATIONS_DATA_VERSION];
        if (version >= MONITORED_CONVERSATIONS_DATA_VERSION)
        {
            NSDictionary *dictVal = nil;
            dictVal = [aDecoder decodeObjectForKey:KEY_MONITORED_CONVERSATIONS];
            if (dictVal) {
                self.monitoredConversations = dictVal;
            }
        }
    }
    
    return self;
}

- (void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeInt:MONITORED_CONVERSATIONS_DATA_VERSION forKey:KEY_MONITORED_CONVERSATIONS_DATA_VERSION];
    [aCoder encodeObject:self.monitoredConversations forKey:KEY_MONITORED_CONVERSATIONS];
}

#pragma mark - Public Methods

- (void)save
{
    [MonitoredConversations saveAll];
}

- (void)addMonitoredRegion:(CLCircularRegion *)region {
    NSMutableDictionary *mutableDictionary = [self.monitoredConversations mutableCopy];
    NSDictionary *newRegionToMonitor = [NSDictionary dictionaryWithObject:region forKey:region.identifier];
    [mutableDictionary addEntriesFromDictionary:newRegionToMonitor];
    self.monitoredConversations = [NSDictionary dictionaryWithDictionary:mutableDictionary];
    [self save];
}

- (void)addMonitoredConversation:(STMConversation *)conversation {
    if (conversation.location && conversation.location.lat && conversation.location.lon && conversation.location.radius_in_meters) {
        CLLocationCoordinate2D center = CLLocationCoordinate2DMake(conversation.location.lat,
                                                                   conversation.location.lon);
        CLCircularRegion *region = [[CLCircularRegion alloc]initWithCenter:center
                                                                                 radius:conversation.location.radius_in_meters
                                                                             identifier:conversation.str_id];
        NSMutableDictionary *mutableDictionary = [self.monitoredConversations mutableCopy];
        NSDictionary *newRegionToMonitor = [NSDictionary dictionaryWithObject:region forKey:region.identifier];
        [mutableDictionary addEntriesFromDictionary:newRegionToMonitor];
        self.monitoredConversations = [NSDictionary dictionaryWithDictionary:mutableDictionary];
        [self save];
    }
    
}


- (void)removeMonitoredConversation:(CLCircularRegion *)region {
    NSMutableDictionary *mutableDictionary = [self.monitoredConversations mutableCopy];
    [mutableDictionary removeObjectForKey:region.identifier];
    self.monitoredConversations = [NSDictionary dictionaryWithDictionary:mutableDictionary];
    [self save];
}

- (void)removeAllMonitoredConversations {
    self.monitoredConversations = @{};
    [self save];
}

@end
