//
//  STMSubscription.h
//  Pods
//
//  Created by Tyler Clemens on 7/6/16.
//
//

#import <Foundation/Foundation.h>
#import "Utils.h"

@interface STMSubscription : NSObject
@property (nonatomic, copy)     NSString     *strUserId;
@property (nonatomic, copy)     NSString     *strChannelId;
@property (nonatomic, copy)     NSString     *strSubscriptionArn;
@property (nonatomic, copy)     NSDate       *dateCreated;

- (id)initWithDictionary:(NSDictionary *)dict;
@end
