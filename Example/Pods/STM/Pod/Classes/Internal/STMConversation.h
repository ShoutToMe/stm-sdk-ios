//
//  Conversation.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 1/5/15.
//  Copyright (c) 2015 Adam Harris. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef enum eSTM_Conversation_Severity
{
    STM_Conversation_Severity_Minor,
    STM_Conversation_Severity_Moderate,
    STM_Conversation_Severity_Major
} tSTM_Conversation_Severity;

@interface ConversationLocation : NSObject

@property (nonatomic, assign)   double                  lat;
@property (nonatomic, assign)   double                  lon;
@property (nonatomic, copy)     NSString                *str_description;

@end

@interface STMConversation : NSObject

@property (nonatomic, copy)     NSString                    *str_id;
@property (nonatomic, copy)     NSString                    *str_created_date;
@property (nonatomic, copy)     NSString                    *str_modified_date;
@property (nonatomic, copy)     NSString                    *str_expiration_date;
@property (nonatomic, copy)     NSString                    *str_start_date;
@property (nonatomic, assign)   NSUInteger                  shout_count;
@property (nonatomic, copy)     NSString                    *str_severity;
@property (nonatomic, copy)     NSString                    *str_type;
@property (nonatomic, assign)   BOOL                        bVerified;
@property (nonatomic, copy)     NSString                    *str_summary;
@property (nonatomic, copy)     NSString                    *str_time_prefix;
@property (nonatomic, copy)     NSString                    *str_spoken_meta_information;
@property (nonatomic, assign)   tSTM_Conversation_Severity  severity;
@property (nonatomic, strong)   NSDate                      *dateCreated;
@property (nonatomic, strong)   NSDate                      *dateExpiration;
@property (nonatomic, strong)   NSDate                      *dateModified;
@property (nonatomic, strong)   NSDate                      *dateStart;
@property (nonatomic, strong)   NSDate                      *dateDownloaded;
@property (nonatomic, strong)   ConversationLocation        *location;
@property (nonatomic, copy)     NSString                    *str_url;

- (id)initWithDictionary:(NSDictionary *)dictConversation;

- (NSUInteger)ageInMinutes;
- (NSUInteger)minutesAgoDownloaded;
- (NSString *)subTitle;
- (BOOL)isUpdatedVersionOf:(STMConversation *)otherConversation;


@end




