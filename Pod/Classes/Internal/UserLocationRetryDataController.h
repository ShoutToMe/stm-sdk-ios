//
//  STMCoreDataAdapter.h
//  STM
//
//  Created by Tracy Rojas on 2/19/18.
//

#import <CoreData/CoreData.h>

@interface UserLocationRetryDataController : NSObject

@property (readonly, strong) NSPersistentContainer * _Nonnull persistentContainer NS_AVAILABLE_IOS(10.0);

-(void) deleteAllUserLocations;
-(void) getAllUserLocations:(void(^_Nonnull)(NSArray *_Nullable))callbackBlock;
-(void) saveUserLocation:(NSDictionary *_Nonnull)userLocationData;

@end
