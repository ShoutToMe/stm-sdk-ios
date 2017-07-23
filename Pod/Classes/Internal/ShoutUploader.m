//
//  FileUploader.m
//  Pods
//
//  Created by Tracy Rojas on 7/17/17.
//
//

#import "ShoutUploader.h"
#import "Server.h"
#import <MobileCoreServices/MobileCoreServices.h>

@implementation ShoutUploader

- (void)upload:(NSURL *)localFileURL completion:(void(^)(NSString*, NSError*))callback
{
    NSString *uuid = [[NSUUID UUID] UUIDString];
    NSString *fileExtension = [localFileURL pathExtension];
    NSString *UTI = (__bridge_transfer NSString *)UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (__bridge CFStringRef)fileExtension, NULL);
    NSString *contentType = (__bridge_transfer NSString *)UTTypeCopyPreferredTagWithClass((__bridge CFStringRef)UTI, kUTTagClassMIMEType);
    if (!contentType) {
        NSLog(@"Content type not found for media file: %@", [localFileURL absoluteString]);
        contentType = @"application/octet-stream";
    }
    NSString *s3FileKey = [NSString stringWithFormat:@"%@.%@", uuid, fileExtension];
    
    AWSS3TransferUtilityUploadCompletionHandlerBlock completionHandler = ^(AWSS3TransferUtilityUploadTask *task, NSError *error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if (error) {
                if ([error.domain isEqualToString:AWSS3TransferManagerErrorDomain]) {
                    switch (error.code) {
                        case AWSS3TransferManagerErrorCancelled:
                        case AWSS3TransferManagerErrorPaused:
                            NSLog(@"AWS media file transfer paused or cancelled");
                            break;
                            
                        default:
                            NSLog(@"An error occurred during AWS media file upload");
                            break;
                    }
                    callback(nil, error);
                } else {
                    NSLog(@"Unknown error domain from AWS task");
                    callback(nil, error);
                }
            } else if (task) {
                callback([NSString stringWithFormat:@"%@%@", SERVER_AWS_S3_UPLOAD_URL_PREFIX, s3FileKey], nil);
            }
        });
    };
    
    AWSS3TransferUtility *transferUtility = [AWSS3TransferUtility S3TransferUtilityForKey:SERVER_AWS_S3_CONFIGURATION_KEY];
    [transferUtility uploadFile:localFileURL
                          bucket:SERVER_AWS_S3_UPLOAD_BUCKET_NAME
                             key:s3FileKey
                     contentType:contentType
                      expression:nil
               completionHandler:completionHandler];
}
@end
