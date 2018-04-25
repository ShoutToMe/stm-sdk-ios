//
//  STMMessage.h
//  Pods
//
//  Created by Tyler Clemens on 6/2/16.
//
//

#import <UIKit/UIKit.h>
#import "STMChannel.h"
#import "STMUser.h"

@interface STMMessage : NSObject

@property (nonatomic, copy)     NSString                    *strID;
@property (nonatomic, copy)     NSDate                      *sentDate;
@property (nonatomic, copy)     NSString                    *strChannelId;
@property (nonatomic, copy)     NSString                    *strSenderId;
@property (nonatomic, copy)     NSString                    *strRecipientId;
@property (nonatomic, copy)     NSString                    *strMessage;
@property (nonatomic, copy)     NSString                    *strIdType;
@property (nonatomic, copy)     STMChannel                  *channel;
@property (nonatomic, retain)   STMUser                        *sender;
@property (nonatomic, retain)   STMUser                        *recipient;

- (id)initWithDictionary:(NSDictionary *)dictMessage;

@end
