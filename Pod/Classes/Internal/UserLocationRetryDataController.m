//
//  STMCoreDataAdapter.m
//  STM
//
//  Created by Tracy Rojas on 2/19/18.
//

#import "UserLocationRetryDataController.h"
#import "User.h"
#import "Server.h"
#import "STM.h"

static NSUInteger const MAX_RECORDS = 1000;
static NSString *const DATA_STORE_NAME = @"STMData";
static NSString *const ENTITY_NAME = @"UserLocation";

@implementation UserLocationRetryDataController

-(void) deleteAllUserLocations
{
    if (@available(iOS 10.0, *)) {
        [self.persistentContainer performBackgroundTask:^(NSManagedObjectContext *managedObjectContext) {
            NSFetchRequest *request = [[NSFetchRequest alloc] initWithEntityName:ENTITY_NAME];
            NSBatchDeleteRequest *deleteRequest = [[NSBatchDeleteRequest alloc] initWithFetchRequest:request];
            NSError *deleteError = nil;
            [self.persistentContainer.persistentStoreCoordinator executeRequest:deleteRequest withContext:managedObjectContext error:&deleteError];
            
            if (deleteError) {
                NSLog(@"Failed to delete user locations from Core Data.");
                STM_ERROR(ErrorCategory_Internal, ErrorSeverity_Warning, @"Failed to delete user locations from Core Data.", deleteError.description, nil, nil, nil);
            }
        }];
    }  else {
        NSLog(@"Version less than iOS 10. User Location retry not supported.");
    }
}

-(void) getAllUserLocations:(void(^)(NSArray *))callbackBlock
{
    if (@available(iOS 10.0, *)) {
        [self.persistentContainer performBackgroundTask:^(NSManagedObjectContext *managedObjectContext) {
            NSMutableArray *userLocations = [NSMutableArray new];
            
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:ENTITY_NAME];
            
            NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:SERVER_DATE_KEY ascending:YES];
            [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
            
            NSError *error;
            NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
            if (error) {
                NSLog(@"An error occurred fetching user locations from Core Data");
                STM_ERROR(ErrorCategory_Internal, ErrorSeverity_Warning, @"An error occurred fetching user locations from Core Data", error.description, nil, nil, nil);
            } else {
                NSEnumerator *e = [results objectEnumerator];
                id object;
                while (object = [e nextObject]) {
                    NSMutableDictionary *userLocation = [NSMutableDictionary new];
                    NSManagedObject *managedObject = (NSManagedObject *)object;
                    [userLocation setValue:[managedObject valueForKey:SERVER_DATE_KEY] forKey:SERVER_DATE_KEY];
                    [userLocation setValue:[managedObject valueForKey:SERVER_LAT_KEY] forKey:SERVER_LAT_KEY];
                    [userLocation setValue:[managedObject valueForKey:SERVER_LON_KEY] forKey:SERVER_LON_KEY];
                    [userLocation setValue:[managedObject valueForKey:SERVER_RADIUS_KEY] forKey:SERVER_RADIUS_KEY];
                    NSNumber *metersSinceLastUpdate = [managedObject valueForKey:SERVER_METERS_SINCE_LAST_UPDATE_KEY];
                    if ([metersSinceLastUpdate doubleValue] >= 0) {
                        [userLocation setValue:metersSinceLastUpdate forKey:SERVER_METERS_SINCE_LAST_UPDATE_KEY];
                    }
                    
                    [userLocations addObject:[userLocation copy]];
                }
            }

            callbackBlock([userLocations copy]);
        }];
    } else {
        NSLog(@"Version less than iOS 10. User Location retry not supported.");
        callbackBlock(nil);
    }
}

-(void) saveUserLocation:(NSDictionary *)userLocationData
{
    if (@available(iOS 10.0, *)) {
        [self.persistentContainer performBackgroundTask:^(NSManagedObjectContext *managedObjectContext) {
            NSEntityDescription *description = [NSEntityDescription entityForName:ENTITY_NAME inManagedObjectContext:managedObjectContext];
            NSManagedObject *userLocationMO = [[NSManagedObject alloc] initWithEntity:description insertIntoManagedObjectContext:managedObjectContext];
            [userLocationMO setValue:[userLocationData valueForKey:SERVER_DATE_KEY] forKey:SERVER_DATE_KEY];
            [userLocationMO setValue:[userLocationData valueForKey:SERVER_LAT_KEY] forKey:SERVER_LAT_KEY];
            [userLocationMO setValue:[userLocationData valueForKey:SERVER_LON_KEY] forKey:SERVER_LON_KEY];
            [userLocationMO setValue:[userLocationData valueForKey:SERVER_RADIUS_KEY] forKey:SERVER_RADIUS_KEY];
            if ([userLocationData valueForKey:SERVER_METERS_SINCE_LAST_UPDATE_KEY]) {
                [userLocationMO setValue:[userLocationData valueForKey:SERVER_METERS_SINCE_LAST_UPDATE_KEY] forKey:SERVER_METERS_SINCE_LAST_UPDATE_KEY];
            } else {
                [userLocationMO setValue:[NSNumber numberWithDouble:-1] forKey:SERVER_METERS_SINCE_LAST_UPDATE_KEY];
            }
            
            [self saveContext:managedObjectContext];
            
            // Truncate number of records if more than the max
            NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:ENTITY_NAME];
            NSError *error;
            NSUInteger recordCount = [managedObjectContext countForFetchRequest:fetchRequest error:&error];
            if (error) {
                NSLog(@"An error occurred fetching the User Location record count from Core Data");
                STM_ERROR(ErrorCategory_Internal, ErrorSeverity_Warning, @"An error occurred fetching the User Location record count from Core Data", error.description, nil, nil, nil);
            } else if (recordCount > MAX_RECORDS) {
                NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:ENTITY_NAME];
                
                NSUInteger numRecordsToDelete = recordCount - MAX_RECORDS;
                [fetchRequest setFetchLimit:numRecordsToDelete];
                
                NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:SERVER_DATE_KEY ascending:YES];
                [fetchRequest setSortDescriptors:[NSArray arrayWithObject:sortDescriptor]];
                
                NSArray *results = [managedObjectContext executeFetchRequest:fetchRequest error:&error];
                NSEnumerator *e = [results objectEnumerator];
                id object;
                while (object = [e nextObject]) {
                    NSManagedObject *managedObject = (NSManagedObject *)object;
                    [managedObjectContext deleteObject:managedObject];
                }
                
                [self saveContext:managedObjectContext];
            }
        }];
    } else {
        NSLog(@"Version less than iOS 10. User Location retry not supported.");
    }
}

#pragma mark - Core Data stack

@synthesize persistentContainer = _persistentContainer;

- (NSPersistentContainer *)persistentContainer {
    @synchronized (self) {
        if (_persistentContainer == nil) {
            _persistentContainer = [[NSPersistentContainer alloc] initWithName:DATA_STORE_NAME];
            [_persistentContainer loadPersistentStoresWithCompletionHandler:^(NSPersistentStoreDescription *storeDescription, NSError *error) {
                if (error != nil) {
                    /*
                     Typical reasons for an error here include:
                     * The parent directory does not exist, cannot be created, or disallows writing.
                     * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                     * The device is out of space.
                     * The store could not be migrated to the current model version.
                     Check the error message to determine what the actual problem was.
                     */
                    NSLog(@"Unresolved error %@, %@", error, error.userInfo);
                    STM_ERROR(ErrorCategory_Internal, ErrorSeverity_Warning, @"Failed to initialize NSPersistentContainer.", error.description, nil, nil, nil);
                }
            }];
        }
    }
    
    return _persistentContainer;
}

#pragma mark - Core Data Saving support

- (void)saveContext:(NSManagedObjectContext *)context {
    NSError *error = nil;
    if ([context hasChanges] && ![context save:&error]) {
        NSLog(@"Unresolved error %@, %@", error, error.userInfo);
        STM_ERROR(ErrorCategory_Internal, ErrorSeverity_Warning, @"An error occurred saving NSManagedObjectContext", error.description, nil, nil, nil);
    }
}

@end
