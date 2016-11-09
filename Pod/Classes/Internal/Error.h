//
//  Error.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 1/12/15.
//  Copyright 2015 Ditty Labs. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Settings.h"
#import "STMShout.h"


#define STM_ERROR(cat, sev, desc, det, req, req_data, res) \
                  [[STM error] logErrorWithCategory:cat \
                                       withSeverity:sev \
                                     andDescription:desc \
                                         andDetails:det \
                                         andRequest:req \
                                        andRequestData:req_data \
                                         andResults:res \
                                         inFunction:[NSString stringWithUTF8String:__func__] \
                                           inSource:[NSString stringWithUTF8String:__FILE__] \
                                             onLine:(int)__LINE__]
static NSString *ShoutToMeErrorDomain = @"com.ShoutToMe.ErrorDomain";

typedef enum eErrorCategory
{
    ErrorCategory_Unknown,
    ErrorCategory_Internal,
    ErrorCategory_Network,
    ErrorCategory_VoiceCmd,
    ErrorCategory_Analytics
} tErrorCategory;

typedef enum eErrorSeverity
{
    ErrorSeverity_Unknown,
    ErrorSeverity_Fatal,
    ErrorSeverity_Warning,
    ErrorSeverity_Info
} tErrorSeverity;

typedef enum eErrorType {
    MicPermissionNotGranted,
    APITokenNotSet,
    LocationServicesNotEnabledOrAuthorized
} eErrorType;
// this is singleton object class
// this means it has static methods that create on instance of itself for use by all


@interface Error : NSObject

+ (void)initAll;
+ (void)freeAll;

+ (Error *)controller;

- (void)logErrorWithCategory:(tErrorCategory)cat withSeverity:(tErrorSeverity)severity andDescription:(NSString *)strDescription andDetails:(NSString *)strDetails andRequest:(NSString *)strRequest andRequestData:(NSObject *)RequestData andResults:(NSString *)strResults inFunction:(NSString *)strFunction inSource:(NSString *)strSource onLine:(int)nLine;


@end

