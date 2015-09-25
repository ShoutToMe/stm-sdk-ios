//
//  AppUtils.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 3/19/15.
//  Copyright (c) 2015 Adam Harris. All rights reserved.
//

#import <Foundation/Foundation.h>

#define IS_IPHONE4  (([[UIScreen mainScreen] bounds].size.height == 480) ? TRUE : FALSE)

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

@interface AppUtils : NSObject

+ (NSTimeInterval)secondsSinceDate:(NSDate *)date;
+ (BOOL)date:(NSDate *)date1 isNewerThan:(NSDate *)date2;
+ (BOOL)isOnPhoneCall;
+ (BOOL)phoneCallBlocker;
+ (void)showAlert:(NSString *)strMsg withTitle:(NSString *)strTitle;

@end
