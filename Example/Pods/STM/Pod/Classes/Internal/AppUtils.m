//
//  AppUtils.m
//  ShoutToMeDev
//
//  Created by Adam Harris on 3/19/15.
//  Copyright (c) 2015 Adam Harris. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <CoreTelephony/CTCallCenter.h>
#import <CoreTelephony/CTCall.h>
#import <AVFoundation/AVFoundation.h>
#import "AppUtils.h"

@implementation AppUtils

// returns the number of seconds that have elapsed since the given date
+ (NSTimeInterval)secondsSinceDate:(NSDate *)date
{
    return [[NSDate date] timeIntervalSinceDate:date];
}

// returns whether the given date is more resent than the next data (TODO: belongs in AppUtils)
+ (BOOL)date:(NSDate *)date1 isNewerThan:(NSDate *)date2
{
    BOOL bIsNewer = NO;

    if (date1 && date2)
    {
        if ([date1 compare:date2] == NSOrderedDescending)
        {
            bIsNewer = YES;
        }
    }

    return bIsNewer;
}

// Returns YES if the user is currently on a phone call (TODO: belongs in AppUtils)
+ (BOOL)isOnPhoneCall
{
    CTCallCenter *callCenter = [[CTCallCenter alloc] init];
    for (CTCall *call in callCenter.currentCalls)
    {
        if (call.callState == CTCallStateConnected)
        {
            return YES;
        }
    }
    return NO;
}

// if the user is on a phone call, this will bring up an alert saying to wait until off
// returns YES if alert was brought up, otherwise returns NO
+ (BOOL)phoneCallBlocker
{
    BOOL bOnPhoneCall = [AppUtils isOnPhoneCall];

    if (bOnPhoneCall)
    {
        [AppUtils showAlert:NSLocalizedString(@"You can not perform this action while on the phone. Please try again after you complete your call.", nil)
                  withTitle:nil];
    }

    return bOnPhoneCall;
}

// brings up a non-delegated alert view with the given message and title
+ (void)showAlert:(NSString *)strMsg withTitle:(NSString *)strTitle
{
    UIAlertView *alert = [[UIAlertView alloc]
                          initWithTitle:strTitle
                          message:strMsg
                          delegate:nil
                          cancelButtonTitle:@"OK"
                          otherButtonTitles:nil];
    [alert show];
}

@end
