//
//  STMSubscription.m
//  Pods
//
//  Created by Tyler Clemens on 7/6/16.
//
//

#import "STMSubscription.h"

@implementation STMSubscription


- (id)init
{
    self = [super init];
    if (self)
    {
        self.strUserId = @"";
        self.strChannelId = @"";
        self.strSubscriptionArn = @"";
    }
    return self;
}

- (id)initWithDictionary:(NSDictionary *)dictMessage
{
    self = [super init];
    if (self)
    {
        [self setDataFromDictionary:dictMessage];
    }
    return self;
}

- (NSString *)description
{
    NSString *strDesc = [NSString stringWithFormat:@"Subscription - user_id: %@, channel_id: %@, subscription_arn: %@, date_created: %@",
                         self.strUserId,
                         self.strChannelId,
                         self.strSubscriptionArn,
                         self.dateCreated
                         ];
    
    return strDesc;
}

#pragma mark - Misc Methods

- (void)setDataFromDictionary:(NSDictionary *)dict
{
    if (dict)
    {
        self.strUserId = [Utils stringFromKey:@"user_id" inDictionary:dict];
        self.strChannelId = [Utils stringFromKey:@"channel_id" inDictionary:dict];
        self.strSubscriptionArn = [Utils stringFromKey:@"subscription_arn" inDictionary:dict];
//        self.dateCreated = [Utils dateFromString:[Utils stringFromKey:@"created_date" inDictionary:dict]];
        
    }
}

@end
