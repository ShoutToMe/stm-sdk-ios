//
//  Shout.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 12/10/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "STMConversation.h"

@interface STMShoutTrafficInfo : NSObject

@property (nonatomic, copy)     NSString            *str_expiration_date;
@property (nonatomic, assign)   double              heading;
@property (nonatomic, assign)   double              speed_mph;
@property (nonatomic, copy)     NSString            *str_category;
@property (nonatomic, copy)     NSString            *str_severity;

@end

@interface STMShoutStats : NSObject

@property (nonatomic, assign)   double              view_count;
@property (nonatomic, assign)   double              broadcast_count;
@property (nonatomic, assign)   double              approvals;
@property (nonatomic, assign)   double              disapprovals;
@property (nonatomic, assign)   double              score;

@end

@interface STMShoutUser : NSObject

@property (nonatomic, copy)     NSString            *str_user_name;
@property (nonatomic, assign)   BOOL                b_is_admin;
@property (nonatomic, assign)   double              reputation_score;
@property (nonatomic, copy)     NSString            *str_affiliate_id;

@end

@interface STMShout : NSObject

@property (nonatomic, copy)     NSString            *str_affiliate_id;
@property (nonatomic, copy)     NSString            *str_id;
@property (nonatomic, copy)     NSString            *str_reply_to_id;
@property (nonatomic, copy)     NSString            *str_conversation_id;
@property (nonatomic, copy)     NSString            *str_created_date;
@property (nonatomic, copy)     NSString            *str_modified_date;
@property (nonatomic, copy)     NSString            *str_state;
@property (nonatomic, copy)     NSString            *str_media_file_url;
@property (nonatomic, copy)     NSString            *str_mime_type;
@property (nonatomic, copy)     NSString            *str_channel;
@property (nonatomic, copy)     NSString            *str_spoken_text;
@property (nonatomic, copy)     NSString            *str_icon_url;
@property (nonatomic, assign)   double              my_vote;
@property (nonatomic, strong)   STMShoutTrafficInfo    *trafficInfo;
@property (nonatomic, strong)   STMShoutStats          *stats;
@property (nonatomic, strong)   STMShoutUser           *user;
@property (nonatomic, strong)   NSDate              *dateCreated;
@property (nonatomic, strong)   NSDate              *dateModified;
@property (nonatomic, assign)   BOOL                bHasBeenPlayed;

- (id)initWithDictionary:(NSDictionary *)dictShout;

- (NSUInteger)ageInMinutes;

@end




