//
//  STMError.m
//
//  Description:
//      This module provides the functionality for handling errors (e.g., send to server log)
//
//  Created by Tracy Rojas on 7/28/17.
//  Copyright 2017 Shout to Me. All rights reserved.
//

#import "STMError.h"
#import <sys/utsname.h>
#import "Utils.h"
#import "Settings.h"
#import "DL_URLServer.h"
#import "Server.h"
#import "UserData.h"

static BOOL bInitialized = NO;

__strong static STMError *singleton = nil; // this will be the one and only object this static singleton class has

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface ErrorData : NSObject
{
}

@property (nonatomic, assign)   tErrorCategory  category;
@property (nonatomic, assign)   tErrorSeverity  severity;
@property (nonatomic, copy)     NSString        *strFunction;
@property (nonatomic, copy)     NSString        *strSource;
@property (nonatomic, assign)   int             nLine;
@property (nonatomic, copy)     NSString        *strDescription;
@property (nonatomic, copy)     NSString        *strDetails;
@property (nonatomic, copy)     NSString        *strRequest;
@property (nonatomic, strong)   NSObject        *requestData;
@property (nonatomic, copy)     NSString        *strResults;

@end

@implementation ErrorData

- (id)init
{
    self = [super init];
    if (self)
    {
        self.category = ErrorCategory_Unknown;
        self.severity = ErrorSeverity_Unknown;
        self.strFunction = @"";
        self.strSource = @"";
        self.nLine = -1;
        self.strRequest = @"";
        self.requestData = @"";
        self.strDescription = @"";
        self.strResults = @"";
        self.strDetails = @"";
    }
    return self;
}

- (NSString *)description
{
    return([NSString stringWithFormat:@"\n************************************************************************************************************************************\n* STM Error:\n* Category - %d (%@)\n* Severity - %d (%@)\n* Description - %@\n* Details - %@\n* Request - %@\n* Request Data - %@\n* Results - %@\n* Function - %@\n* Source - %@\n* Line - %d\n************************************************************************************************************************************",
            self.category,
            [self nameForCategory:self.category],
            self.severity,
            [self nameForSeverity:self.severity],
            self.strDescription,
            self.strDetails,
            self.strRequest,
            self.requestData,
            self.strResults,
            self.strFunction,
            self.strSource,
            self.nLine]);
}

- (NSString *)nameForSeverity:(tErrorSeverity)severity
{
    NSString *strRet = @"Unknown";
    
    switch (severity)
    {
        case ErrorSeverity_Fatal:
            strRet = @"Fatal";
            break;
            
        case ErrorSeverity_Warning:
            strRet = @"Warning";
            break;
            
        case ErrorSeverity_Info:
            strRet = @"Info";
            break;
            
        default:
            break;
    }
    
    return strRet;
}

- (NSString *)nameForCategory:(tErrorCategory)category
{
    NSString *strRet = @"Unknown";
    
    switch (category)
    {
        case ErrorCategory_Internal:
            strRet = @"Internal";
            break;
            
        case ErrorCategory_Network:
            strRet = @"Network";
            break;
            
        case ErrorCategory_VoiceCmd:
            strRet = @"Voice Command";
            break;
        case ErrorCategory_Analytics:
            strRet = @"Analytics";
            break;
            
        default:
            break;
    }
    
    return strRet;
}

@end

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////

@interface STMError () <DL_URLRequestDelegate>
{
}

@end

@implementation STMError

#pragma mark - Static methods

+ (void)initAll
{
    if (NO == bInitialized)
    {
        [Settings initAll];
        [DL_URLServer initAll];
        
        singleton = [[STMError alloc] init];
        
        bInitialized = YES;
    }
}

+ (void)freeAll
{
    if (YES == bInitialized)
    {
        // release our singleton
        singleton = nil;
        
        bInitialized = NO;
    }
}

// returns the singleton
// (this call is both a container and an object class and the container holds one of itself)
+ (STMError *)controller
{
    return (singleton);
}

#pragma mark - Object Methods

- (id)init
{
    self = [super init];
    if (self)
    {
        
    }
    return self;
}

- (void)dealloc
{
    [[DL_URLServer controller] cancelAllRequestsForDelegate:self];
}

#pragma mark - Misc Methods

- (void)sendError:(ErrorData *)data
{
    if (data)
    {
        // get the model name
        struct utsname systemInfo;
        uname(&systemInfo);
        NSString *strModelInfo = [NSString stringWithCString:systemInfo.machine encoding:NSUTF8StringEncoding];
        NSString *strModelName = [Utils modelNameFrom:strModelInfo];
        UIDevice *curDevice = [UIDevice currentDevice];
        NSString *strOS = [NSString stringWithFormat:@"iOS v%@", [curDevice systemVersion]];
        
        // set the json data
        NSMutableDictionary *dictData = [[NSMutableDictionary alloc] init];
        [dictData setObject:[data nameForCategory:data.category] forKey:@"Category"];
        [dictData setObject:[data nameForSeverity:data.severity] forKey:@"Severity"];
        [dictData setObject:data.strFunction forKey:@"Function"];
        [dictData setObject:data.strSource forKey:@"Source"];
        [dictData setObject:[NSNumber numberWithInt:data.nLine] forKey:@"Line"];
        [dictData setObject:data.strRequest forKey:@"Request"];
        [dictData setObject:data.strResults forKey:@"Results"];
        [dictData setObject:data.requestData forKey:@"RequestData"];
        [dictData setObject:data.strDescription forKey:@"Description"];
        [dictData setObject:data.strDetails forKey:@"Details"];
        [dictData setObject:[Settings controller].strAffiliateID forKey:@"AffiliateID"];
        [dictData setObject:[Settings controller].strServerURL forKey:@"ServerURL"];
        [dictData setObject:[Settings controller].channel.strID forKey:@"ChannelID"];
        [dictData setObject:[Settings controller].channel.strName forKey:@"ChannelName"];
        [dictData setObject:[Settings controller].strDeviceID forKey:@"DeviceID"];
        [dictData setObject:[UserData controller].user.strHandle forKey:@"Handle"];
        [dictData setObject:[UserData controller].user.strUserID forKey:@"UserID"];
        [dictData setObject:strModelName forKey:@"Model"];
        [dictData setObject:strOS forKey:@"OS"];
        [dictData setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] forKey:@"Version"];
        [dictData setObject:[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleVersion"] forKey:@"Build"];
        [dictData setObject:[NSString stringWithFormat:@"%@", [NSDate date]] forKey:@"Timestamp"];
        
        NSError *error = nil;
        NSData *dataJSON = [NSJSONSerialization dataWithJSONObject:dictData options:NSJSONWritingPrettyPrinted error:&error];
        NSString *strJSON = [[NSString alloc] initWithData:dataJSON encoding:NSUTF8StringEncoding];
        //NSLog(@"Error Send: data = %@", strJSON);
        
        NSString *strURL = [NSString stringWithFormat:@"%@/%@",
                            [Settings controller].strServerURL,
                            SERVER_CMD_POST_ERROR];
        
        //NSLog(@"Error Send: URL = %@", strURL);
        
        //[[Analytics controller] event:@"error" info:dictData];
        
        [[DL_URLServer controller] issueRequestURL:strURL
                                        methodType:DL_URLRequestMethod_Post
                                        withParams:strJSON
                                        withObject:nil
                                      withDelegate:self
                                acceptableCacheAge:DL_URLSERVER_CACHE_AGE_NEVER
                                       cacheResult:NO
                                       contentType:CONTENT_TYPE
                                    headerRequests:[[UserData controller] dictBasicRequestHeaders]];
    }
}

#pragma mark - Public Methods

- (void)logErrorWithCategory:(tErrorCategory)cat withSeverity:(tErrorSeverity)severity andDescription:(NSString *)strDescription andDetails:(NSString *)strDetails andRequest:(NSString *)strRequest andRequestData:(NSObject *)RequestData andResults:(NSString *)strResults inFunction:(NSString *)strFunction inSource:(NSString *)strSource onLine:(int)nLine
{
    ErrorData *data = [[ErrorData alloc] init];
    
    data.category = cat;
    data.severity = severity;
    data.strFunction = strFunction;
    data.strSource = [strSource lastPathComponent];
    data.nLine = nLine;
    data.strRequest = strRequest ? strRequest : @"";
    data.requestData = RequestData ? RequestData : @"";
    data.strDescription = strDescription;
    data.strResults = strResults ? strResults : @"";
    data.strDetails = strDetails;
    
    NSLog(@"%@", data);
    
    [self sendError:data];
}

#pragma mark - DL_URLServer Callbacks

// this is the results callback from DLURLServer
- (void)onDL_URLRequestCompleteWithStatus:(tDL_URLRequestStatus)status resultData:(NSData *)data resultObj:(id)object
{
    BOOL bSuccess = NO;
    
    NSString *jsonString = [[NSString alloc] initWithBytes:[data bytes] length:[data length] encoding:NSUTF8StringEncoding];
    
    NSLog(@"Error: Results download returned: %@", jsonString );
    
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF32BigEndianStringEncoding];
    NSDictionary *dictResults = [NSJSONSerialization JSONObjectWithData:jsonData options:NSJSONReadingMutableContainers error:nil];
    NSString *strStatus = [dictResults objectForKey:SERVER_RESULTS_STATUS_KEY];
    
    NSLog(@"decode: %@", dictResults);
    
    if (status == DL_URLRequestStatus_Success)
    {
        if ([strStatus isEqualToString:SERVER_RESULTS_STATUS_SUCCESS])
        {
            bSuccess = YES;
        }
    }
    
    if (bSuccess)
    {
        NSLog(@"STM Error: Error successfully sent to server");
    }
    else
    {
        NSLog(@"STM Error: Failed to send error to server");
    }
}

@end
