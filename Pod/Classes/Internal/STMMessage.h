//
//  STMMessage.h
//  Pods
//
//  Created by Tyler Clemens on 6/2/16.
//
//

#import <UIKit/UIKit.h>

@interface STMMessage : NSObject

@property (nonatomic, copy)     NSString                    *strID;
@property (nonatomic, copy)     NSDate                      *dateCreated;
@property (nonatomic, copy)     NSString                    *strChannelId;
@property (nonatomic, copy)     NSString                    *strSenderId;
@property (nonatomic, copy)     NSString                    *strRecipientId;
@property (nonatomic, copy)     NSString                    *strMessage;
@property (nonatomic, copy)     NSString                    *strShoutId;

- (id)initWithDictionary:(NSDictionary *)dictMessage;

@end