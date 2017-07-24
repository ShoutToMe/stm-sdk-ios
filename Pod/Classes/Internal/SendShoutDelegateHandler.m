//
//  SendShoutDelegateHandler.m
//  Pods
//
//  Created by Tracy Rojas on 7/24/17.
//
//

#import "SendShoutDelegateHandler.h"
#import "Error.h"

@implementation SendShoutDelegateHandler

- (void)onSendShoutCompleteWithShout:(STMShout *) shout WithStatus:(tSendShoutStatus)status
{
    if ([self.createShoutDelegate respondsToSelector:@selector(shoutCreated:error:)]) {
        if (status == SendShoutStatus_Success) {
            [self.createShoutDelegate shoutCreated:shout error:nil];
        } else if (status == SendShoutStatus_Failure) {
            NSError *error = [NSError errorWithDomain:ShoutToMeErrorDomain code:STMErrorUnknown userInfo:nil];
            [self.createShoutDelegate shoutCreated:nil error:error];
        }
    }
}

@end
