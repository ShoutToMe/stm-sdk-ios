//
//  AppDelegate.m
//  STMExample
//
//  Created by Tyler Clemens on 6/6/16.
//  Copyright © 2016 Tyler Clemens. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    // Override point for customization after application launch.
    
    // This category is appropriate for simultaneous recording and playback, and also for apps that record and play back but not simultaneously.
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:nil];
    // Activates your app’s audio session.
    [[AVAudioSession sharedInstance] setActive:YES error:nil];
    
    // Initialize Shout To Me SDK, Replace with your Shout to Me token
    [STM initWithAccessToken:@"STM_ACCESS_TOKEN"];
    
    // Set your channel Id
    [STM setChannelId:@"CHANNEL_ID"];
    
    return YES;
}

@end