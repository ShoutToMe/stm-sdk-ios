//
//  Channels.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 2/18/15.
//  Copyright 2015 Ditty Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Channel.h"

@protocol ChannelsDelegate <NSObject>

@optional

- (void)ChannelsResults:(NSArray *)arrayChannels;

@end

// this is singleton object class
// this means it has static methods that create on instance of itself for use by all


@interface Channels : NSObject

+ (void)initAll;
+ (void)freeAll;

+ (Channels *)controller;

- (void)requestForChannelsWithDelegate:(id<ChannelsDelegate>)delegate;
- (void)cancelAllRequests;

@end

