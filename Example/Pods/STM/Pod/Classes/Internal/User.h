//
//  User.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 3/02/14.
//  Copyright 2015 Ditty Labs. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface User : NSObject

@property (nonatomic, assign) BOOL              bVerified;
@property (nonatomic, copy)   NSString          *strAuthCode;
@property (nonatomic, copy)   NSString          *strPhoneNumber;
@property (nonatomic, copy)   NSString          *strUserID;
@property (nonatomic, copy)   NSString          *strHandle;
@property (nonatomic, copy)   NSDate            *dateLastViewedMessages;

- (id)initWithDictionary:(NSDictionary *)dictMessage;

@end

