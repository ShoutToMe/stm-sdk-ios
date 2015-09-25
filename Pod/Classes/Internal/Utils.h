//
//  Utils.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 11/3/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <Foundation/Foundation.h>

#define SYSTEM_VERSION_EQUAL_TO(v)                  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedSame)
#define SYSTEM_VERSION_GREATER_THAN(v)              ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedDescending)
#define SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(v)  ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN(v)                 ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] == NSOrderedAscending)
#define SYSTEM_VERSION_LESS_THAN_OR_EQUAL_TO(v)     ([[[UIDevice currentDevice] systemVersion] compare:v options:NSNumericSearch] != NSOrderedDescending)

@interface Utils : NSObject

+ (NSString *)createGUID;
+ (BOOL)isValidEMail:(NSString *)strEMail;
+ (BOOL)isValidPhone:(NSString *)strPhone;
+ (BOOL)stringIsSet:(NSString *)strString;
+ (NSInteger)randomNumFrom:(NSInteger)start to:(NSInteger)end;
+ (float)randomFloatFrom:(float)start to:(float)end;
+ (NSString *)stringFromKey:(NSString *)strKey inDictionary:(NSDictionary *)dict;
+ (int)intFromKey:(NSString *)strKey inDictionary:(NSDictionary *)dict;
+ (double)doubleFromKey:(NSString *)strKey inDictionary:(NSDictionary *)dict;
+ (BOOL)boolFromKey:(NSString *)strKey inDictionary:(NSDictionary *)dict;
+ (NSDate *)dateFromString:(NSString *)strDate;
+ (NSString *)timeStringForSeconds:(double)seconds;
+ (NSString *)modelNameFrom:(NSString *)strModelInfo;
+ (NSString *)strForBool:(BOOL)boolean;

@end
