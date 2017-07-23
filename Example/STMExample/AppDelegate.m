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
    
    // Initialize Shout To Me SDK, Replace "STM_ACCESS_TOKEN" with your Shout to Me token
    [STM initWithAccessToken:@"STM_ACCESS_TOKEN" andApplication:application andDelegate:self];
    
    // Set your Shout to Me Channel ID
    [STM setChannelId:@"CHANNEL_ID"];
    
    return YES;
}

- (void)application:(UIApplication *)application handleEventsForBackgroundURLSession:(NSString *)identifier completionHandler:(void (^)())completionHandler {
    [STM application:application handleEventsForBackgroundURLSession:identifier completionHandler:completionHandler];
}

@end
