//
//  GraphView.h
//  ShoutToMeDev
//
//  Created by Adam Harris on 11/13/14.
//  Copyright (c) 2014 Adam Harris. All rights reserved.
//

#import <UIKit/UIKit.h>

@protocol GraphViewDelegate;

@interface GraphView : UIView

@property (nonatomic, assign)   id<GraphViewDelegate>   delegate;
@property (nonatomic, assign)   CGFloat                 minValue;
@property (nonatomic, assign)   CGFloat                 maxValue;
@property (nonatomic, assign)   CGFloat                 lineSpacing;
@property (nonatomic, assign)   CGFloat                 lineWidth;
@property (nonatomic, strong)   UIColor                 *lineColor;

- (void)addValue:(CGFloat)value;
- (void)addNumber:(NSNumber *)number;
- (void)clear;

@end

@protocol GraphViewDelegate <NSObject>

@required

@optional


@end