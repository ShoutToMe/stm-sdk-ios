//
//  SendShoutDelegateHandler.h
//  Pods
//
//  Created by Tracy Rojas on 7/24/17.
//
//

#import <Foundation/Foundation.h>
#import "Shout.h"

@interface SendShoutDelegateHandler : NSObject<SendShoutDelegate>

@property (weak) id<CreateShoutDelegate> createShoutDelegate;

- (void)onSendShoutCompleteWithShout:(STMShout *) shout WithStatus:(tSendShoutStatus)status;

@end
