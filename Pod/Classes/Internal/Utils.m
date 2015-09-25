//
//  Utils.m
//  ShoutToMeDev
//
//  Description:
//      This module provides generic utilitarian functions
//
//  Created by Adam Harris on 11/3/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import "Utils.h"


#define ARC4RANDOM_MAX  0x100000000

@implementation Utils

// dynamically generates a Globally Unique Identifier
+ (NSString *)createGUID
{
    CFUUIDRef theUUID = CFUUIDCreate(NULL);
    CFStringRef string = CFUUIDCreateString(NULL, theUUID);
    CFRelease(theUUID);

    NSString *strGUID = [[NSString alloc] initWithString:(__bridge NSString *)string];
    CFRelease(string);

    return strGUID;
}

// checks for a valid (format-only) email address
+ (BOOL)isValidEMail:(NSString *)strEMail
{
    BOOL bIsValid = NO;

    if (nil == strEMail)
    {
        if ([strEMail length])
        {
            // make sure it has one @ and at least 1 dot
            NSArray *validateAtSymbol  = [strEMail componentsSeparatedByString:@"@"];
            NSArray *validateDotSymbol = [strEMail componentsSeparatedByString:@"."];
            if(([validateAtSymbol count] == 2) && ([validateDotSymbol count] >= 2))
            {
                bIsValid = YES;
            }
        }
    }

    return bIsValid;
}

+ (BOOL)regExp:(NSString *)strRegExp matchedBy:(NSString *)strCheck
{
    NSPredicate *test = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", strRegExp];
    return [test evaluateWithObject:strCheck];
}

// checks for a validly formated phone number
+ (BOOL)isValidPhone:(NSString *)strPhone
{
    BOOL bIsValid = NO;

    if (strPhone)
    {
        if (
            [Utils regExp:@"^[0-9]{10}$" matchedBy:strPhone] ||
            [Utils regExp:@"^[0-9]{7}$" matchedBy:strPhone] ||
            [Utils regExp:@"^\\([0-9]{3}\\) [0-9]{3}-[0-9]{4}$" matchedBy:strPhone] ||
            [Utils regExp:@"^[0-9]{3}-[0-9]{3}-[0-9]{4}$" matchedBy:strPhone] ||
            [Utils regExp:@"^[0-9]{3}-[0-9]{4}$" matchedBy:strPhone]
            )
        {
            bIsValid = YES;
        }
    }

    return bIsValid;
}

// determines whether the given string has a non-blank value
+ (BOOL)stringIsSet:(NSString *)strString
{
    BOOL bIsSet = NO;

    if (strString)
    {
        if ([strString length])
        {
            bIsSet = YES;
        }
    }

    return bIsSet;
}

+ (NSInteger)randomNumFrom:(NSInteger)start to:(NSInteger)end
{
    NSInteger randomNumber = arc4random() % labs((end + 1) - start);
    randomNumber += start;

    return randomNumber;
}

+ (float)randomFloatFrom:(float)start to:(float)end
{
    float range = end - start;
    float val = ((float)arc4random() / ARC4RANDOM_MAX) * range + start;
    return val;
}

+ (NSString *)stringFromKey:(NSString *)strKey inDictionary:(NSDictionary *)dict
{
    NSString *strRet = @"";

    if (strKey && dict)
    {
        NSString *strVal = [dict objectForKey:strKey];
        if ((strVal != nil) && ([dict objectForKey:strKey] != [NSNull null]))
        {
            strRet = strVal;
        }
    }

    return strRet;
}

+ (int)intFromKey:(NSString *)strKey inDictionary:(NSDictionary *)dict
{
    int ret = 0;

    if (strKey && dict)
    {
        NSNumber *val = [dict objectForKey:strKey];
        if ((val != nil) && ([dict objectForKey:strKey] != [NSNull null]))
        {
            ret = [val intValue];
        }
    }

    return ret;
}

+ (double)doubleFromKey:(NSString *)strKey inDictionary:(NSDictionary *)dict
{
    double ret = 0.0;

    if (strKey && dict)
    {
        NSNumber *val = [dict objectForKey:strKey];
        if ((val != nil) && ([dict objectForKey:strKey] != [NSNull null]))
        {
            ret = [val doubleValue];
        }
    }

    return ret;
}

+ (BOOL)boolFromKey:(NSString *)strKey inDictionary:(NSDictionary *)dict
{
    BOOL bRet = NO;

    if (strKey && dict)
    {
        if ([dict objectForKey:strKey] != [NSNull null])
        {
            bRet = [[dict valueForKey:strKey] boolValue];
        }
    }
    
    return bRet;
}

// parses a string into a data. example format: 2014-09-14T04:10:45.286Z
+ (NSDate *)dateFromString:(NSString *)strDate
{
    NSDateFormatter *rfc3339DateFormatter = [[NSDateFormatter alloc] init];
    NSLocale *enUSPOSIXLocale = [[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"];
    [rfc3339DateFormatter setLocale:enUSPOSIXLocale];
    [rfc3339DateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss.SSS'Z'"];
    [rfc3339DateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];

    // Convert the RFC 3339 date time string to an NSDate.
    return [rfc3339DateFormatter dateFromString:strDate];
}

// given a number of seconds, returns a string representing the time
+ (NSString *)timeStringForSeconds:(double)seconds
{
    NSString *strRet = @"";
    
    int minutes = (int) ((seconds / 60.0) + 0.5);
    int hours = (int) ((seconds / (60.0 * 60.0)) + 0.5);
    int days = (int) ((seconds / (60.0 * 60.0 * 24.0)) + 0.5);

    if (seconds <= 0)
    {
        strRet = @"no time";
    }
    else if (seconds < 60)
    {
        int sec = seconds + 0.5;
        strRet = [NSString stringWithFormat:@"%d second%@", sec, (sec == 1 ? @"" : @"s")];
    }
    else if (minutes < 60)
    {
        strRet = [NSString stringWithFormat:@"%d minute%@", minutes, (minutes == 1 ? @"" : @"s")];
    }
    else if (hours <= 24)
    {
        double hoursDouble = (double) minutes / 60.0;
        strRet = [NSString stringWithFormat:@"%.1lf hour%@", hoursDouble, (hoursDouble < 1.1 ? @"" : @"s")];
    }
    else
    {
        strRet = [NSString stringWithFormat:@"%d day%@", days, (days == 1 ? @"" : @"s")];
    }

    return strRet;
}

// returns a model name that attempts to identify the actual device type from the model info
+ (NSString *)modelNameFrom:(NSString *)strModelInfo
{
    NSString *strExtra = @"unknown";

    if ([strModelInfo isEqualToString:@"iPhone1,1"])
    {
        strExtra = @"iPhone 1";
    }
    else if ([strModelInfo isEqualToString:@"iPhone1,2"])
    {
        strExtra = @"iPhone 3G";
    }
    else if ([strModelInfo hasPrefix:@"iPhone2"])
    {
        strExtra = @"iPhone 3GS";
    }
    else if ([strModelInfo hasPrefix:@"iPhone3"])
    {
        strExtra = @"iPhone 4";
    }
    else if ([strModelInfo hasPrefix:@"iPhone4"])
    {
        strExtra = @"iPhone 4S";
    }
    else if ([strModelInfo hasPrefix:@"iPhone5,3"] || [strModelInfo hasPrefix:@"iPhone5,4"])
    {
        strExtra = @"iPhone 5C";
    }
    else if ([strModelInfo hasPrefix:@"iPhone5"])
    {
        strExtra = @"iPhone 5";
    }
    else if ([strModelInfo hasPrefix:@"iPhone6"])
    {
        strExtra = @"iPhone 5S";
    }
    else if ([strModelInfo hasPrefix:@"iPhone7,1"])
    {
        strExtra = @"iPhone 6";
    }
    else if ([strModelInfo hasPrefix:@"iPhone7,2"])
    {
        strExtra = @"iPhone 6 Plus";
    }
    else if ([strModelInfo hasPrefix:@"iPod1"])
    {
        strExtra = @"iPod";
    }
    else if ([strModelInfo hasPrefix:@"iPod2"])
    {
        strExtra = @"iPod 2nd Gen";
    }
    else if ([strModelInfo hasPrefix:@"iPod3"])
    {
        strExtra = @"iPod 3rd Gen";
    }
    else if ([strModelInfo hasPrefix:@"iPod4"])
    {
        strExtra = @"iPod 4th Gen";
    }
    else if ([strModelInfo hasPrefix:@"iPod5"])
    {
        strExtra = @"iPod 5th Gen";
    }
    else if ([strModelInfo hasPrefix:@"iPod6"])
    {
        strExtra = @"iPod 6th Gen";
    }
    else if ([strModelInfo hasPrefix:@"iPad1"])
    {
        strExtra = @"iPad1";
    }
    else if ([strModelInfo hasPrefix:@"iPad2,5"] || [strModelInfo hasPrefix:@"iPad2,6"] || [strModelInfo hasPrefix:@"iPad2,7"])
    {
        strExtra = @"iPad Mini";
    }
    else if ([strModelInfo hasPrefix:@"iPad2"])
    {
        strExtra = @"iPad2";
    }
    else if ([strModelInfo hasPrefix:@"iPad3,4"] || [strModelInfo hasPrefix:@"iPad3,5"] || [strModelInfo hasPrefix:@"iPad3,6"])
    {
        strExtra = @"iPad4";
    }
    else if ([strModelInfo hasPrefix:@"iPad3"])
    {
        strExtra = @"iPad3";
    }
    else if ([strModelInfo hasPrefix:@"iPad4,1"] || [strModelInfo hasPrefix:@"iPad4,2"])
    {
        strExtra = @"iPad Air";
    }
    else if ([strModelInfo hasPrefix:@"iPad4,4"] || [strModelInfo hasPrefix:@"iPad4,5"])
    {
        strExtra = @"iPad Mini Retina";
    }
    else if ([strModelInfo hasPrefix:@"AppleTV2"])
    {
        strExtra = @"AppleTV 2";
    }
    else if ([strModelInfo hasPrefix:@"AppleTV3"])
    {
        strExtra = @"AppleTV 3";
    }
    else if ([strModelInfo hasPrefix:@"iPhone"])
    {
        strExtra = @"unknown iPhone";
    }
    else if ([strModelInfo hasPrefix:@"iPod"])
    {
        strExtra = @"unknown iPod";
    }
    else if ([strModelInfo hasPrefix:@"iPad"])
    {
        strExtra = @"unknown iPad";
    }
    else if ([strModelInfo hasPrefix:@"AppleTV"])
    {
        strExtra = @"unknown AppleTV";
    }
    else if ([strModelInfo hasSuffix:@"86"] || [strModelInfo isEqual:@"x86_64"])
    {
        strExtra = @"simulator";
    }

    NSString *strModelName = [NSString stringWithFormat:@"%@ (%@)", strModelInfo, strExtra];

    return strModelName;
}

+ (NSString *)strForBool:(BOOL)boolean
{
    return (boolean ? @"YES" : @"NO");
}

@end
