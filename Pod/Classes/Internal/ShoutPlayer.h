//
//  ShoutPlayer.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 12/12/14.
//  Copyright 2014 Ditty Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Settings.h"
#import "STMShout.h"

#define SHOUT_PLAYER_NO_SHOUT_PLAYED -1

@protocol ShoutPlayerDelegate <NSObject>

@optional

- (void)ShoutPlayerFinished:(STMShout *)shout;
- (void)ShoutAudioLoaded:(STMShout *)shout success:(BOOL)bSuccess;

@end

// this is singleton object class
// this means it has static methods that create on instance of itself for use by all


@interface ShoutPlayer : NSObject

+ (void)initAll;
+ (void)freeAll;

+ (ShoutPlayer *)controller;

- (void)play:(STMShout *)shout withDelegate:(id<ShoutPlayerDelegate>)delegate;
- (void)loadAudioForShout:(STMShout *)shout withDelegate:(id<ShoutPlayerDelegate>)delegate;
- (void)replayLastShoutWithDelegate:(id<ShoutPlayerDelegate>)delegate;
- (void)stop;
- (void)stop:(STMShout *)shout;
- (BOOL)isPlaying;
- (STMShout *)currentShout;
- (NSDate *)timeLastShoutWasPlayed;
- (NSInteger)secondsSinceLastPlayedShout;
- (STMShout *)lastPlayedShout;
- (void)downvoteShout:(STMShout *)shout;
- (BOOL)haveAudioForShout:(STMShout *)shout;
- (void)clearCache;

@end

