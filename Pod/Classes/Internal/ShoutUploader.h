//
//  FileUploader.h
//  Pods
//
//  Created by Tracy Rojas on 7/17/17.
//
//

#import <Foundation/Foundation.h>
#import <AWSS3/AWSS3.h>

@interface ShoutUploader : NSObject

- (void)upload:(NSURL *)localFileURL completion:(void(^)(NSString*, NSError*))callback;

@end
