//
//  RecordingSystem.h
//  ShoutToMeDev
//
//  Created by Tyler Clemens on 7/23/15.
//  Copyright (c) 2015 Adam Harris. All rights reserved.
//

#import <Foundation/Foundation.h>


// this is singleton object class
// this means it has static methods that create on instance of itself for use by all

@interface RecordingSystem : NSObject

@property int vadTimeout;
@property int vadSensitivity;

+ (void)initAll;
+ (void)freeAll;

+ (void)loadAll;
+ (void)saveAll;

+ (RecordingSystem *)controller;

- (void)save;

@end