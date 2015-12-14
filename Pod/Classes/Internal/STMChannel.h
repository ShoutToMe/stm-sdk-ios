//
//  Channel.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 2/18/15.
//  Copyright (c) 2015 Adam Harris. All rights reserved.
//

#import <UIKit/UIKit.h>


@interface STMChannel : NSObject

@property (nonatomic, copy)     NSString                    *strID;
@property (nonatomic, copy)     NSString                    *strType;
@property (nonatomic, copy)     NSString                    *strName;
@property (nonatomic, copy)     NSString                    *strDescription;
@property (nonatomic, assign)   BOOL                        bGeofenced;
@property (nonatomic, copy)     NSString                    *strMixPanelToken;
@property (nonatomic, copy)     NSString                    *strWitAccessToken;
@property (nonatomic, copy)     NSString                    *strChannelImage;
@property (nonatomic, copy)     NSString                    *strChannelImageList;

- (id)initWithDictionary:(NSDictionary *)dictChannel;

@end




